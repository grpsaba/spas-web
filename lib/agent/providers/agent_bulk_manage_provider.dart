import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agent.dart';
import 'package:spas_web/services/department.dart';

enum AgentBulkManageMode {
  update,
  delete,
}

class AgentBulkManageProvider extends ChangeNotifier {
  AgentBulkManageProvider({
    AgentService? agentService,
    DepartmentService? departmentService,
  })  : _agentService = agentService ?? AgentService(),
        _departmentService = departmentService ?? DepartmentService();

  static const List<String> typeOptions = <String>[
    'Tous',
    'FIXE',
    'POINT ZERO',
    'RONDIER',
  ];

  final AgentService _agentService;
  final DepartmentService _departmentService;

  final TextEditingController searchController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController lastNamePrefixController =
      TextEditingController();

  List<Department> _departments = <Department>[];
  List<Agent> _loadedAgents = <Agent>[];
  List<Agent> _visibleAgents = <Agent>[];
  Set<String> _selectedCodes = <String>{};

  bool _isLoadingDepartments = false;
  bool _isLoadingAgents = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _submitMessage = 'Traitement en cours...';

  AgentBulkManageMode _mode = AgentBulkManageMode.update;

  bool? _selectedActif = true;
  String _selectedType = 'Tous';
  String _selectedDepartment = 'Tous';
  String _searchQuery = '';

  Department? _bulkDepartment;
  AgentType? _bulkAgentType;
  bool? _bulkActif;
  bool _replacePhone = false;
  bool _replaceEmail = false;
  bool _replaceDepartment = false;
  bool _replaceAgentType = false;
  bool _replaceStatus = false;
  bool _replaceLastNamePrefix = false;
  bool _preserveExistingNumbering = true;

  Timer? _searchDebounce;

  List<Department> get departments =>
      List<Department>.unmodifiable(_departments);
  List<Agent> get loadedAgents => List<Agent>.unmodifiable(_loadedAgents);
  List<Agent> get visibleAgents => List<Agent>.unmodifiable(_visibleAgents);
  Set<String> get selectedCodes => Set<String>.unmodifiable(_selectedCodes);

  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isLoadingAgents => _isLoadingAgents;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get submitMessage => _submitMessage;

  AgentBulkManageMode get mode => _mode;

  bool? get selectedActif => _selectedActif;
  String get selectedType => _selectedType;
  String get selectedDepartment => _selectedDepartment;
  String get searchQuery => _searchQuery;

  Department? get bulkDepartment => _bulkDepartment;
  AgentType? get bulkAgentType => _bulkAgentType;
  bool? get bulkActif => _bulkActif;
  bool get replacePhone => _replacePhone;
  bool get replaceEmail => _replaceEmail;
  bool get replaceDepartment => _replaceDepartment;
  bool get replaceAgentType => _replaceAgentType;
  bool get replaceStatus => _replaceStatus;
  bool get replaceLastNamePrefix => _replaceLastNamePrefix;
  bool get preserveExistingNumbering => _preserveExistingNumbering;

  bool get hasSelection => _selectedCodes.isNotEmpty;
  int get selectedCount => _selectedCodes.length;
  int get loadedCount => _loadedAgents.length;
  int get visibleCount => _visibleAgents.length;

  List<String> get departmentOptions => <String>[
        'Tous',
        ..._departments.map((department) => department.label),
      ];

  String get selectedStatusLabel {
    if (_selectedActif == null) {
      return 'Tous';
    }
    return _selectedActif == true ? 'Actifs' : 'Inactifs';
  }

  List<Agent> get selectedAgents {
    if (_selectedCodes.isEmpty) {
      return const <Agent>[];
    }

    return _loadedAgents
        .where((agent) => _selectedCodes.contains(agent.code))
        .toList();
  }

  Future<void> initialize() async {
    await Future.wait([
      loadDepartments(),
      loadAgentsFromFirebase(),
    ]);
  }

  Future<void> refresh() async {
    await loadAgentsFromFirebase();
  }

  Future<void> loadDepartments() async {
    _isLoadingDepartments = true;
    notifyListeners();

    try {
      final departments = await _departmentService.allFuture();
      departments.sort(
        (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
      );
      _departments = departments;
    } catch (error) {
      _errorMessage = 'Erreur chargement départements: $error';
      _departments = <Department>[];
    } finally {
      _isLoadingDepartments = false;
      notifyListeners();
    }
  }

  Future<void> loadAgentsFromFirebase() async {
    _isLoadingAgents = true;
    _errorMessage = null;
    _loadedAgents = <Agent>[];
    _visibleAgents = <Agent>[];
    _selectedCodes.clear();
    notifyListeners();

    try {
      final allAgents = await _agentService.allFuture();

      final filtered = allAgents.where((agent) {
        final matchesStatus =
            _selectedActif == null || agent.actif == _selectedActif;

        final agentType = (agent.typeAgent?.label ?? '').trim().toUpperCase();
        final matchesType =
            _selectedType == 'Tous' || agentType == _selectedType.trim();

        final departmentLabel =
            (agent.department?.label ?? '').trim().toLowerCase();
        final selectedDepartment = _selectedDepartment.trim().toLowerCase();
        final matchesDepartment = _selectedDepartment == 'Tous' ||
            departmentLabel == selectedDepartment;

        return matchesStatus && matchesType && matchesDepartment;
      }).toList();

      filtered.sort(
        (a, b) => a.code.toLowerCase().compareTo(b.code.toLowerCase()),
      );

      _loadedAgents = filtered;
      _applySearch(notify: false);
    } catch (error) {
      _errorMessage = 'Erreur chargement agents: $error';
    } finally {
      _isLoadingAgents = false;
      notifyListeners();
    }
  }

  void setMode(AgentBulkManageMode value) {
    if (_mode == value) return;
    _mode = value;
    notifyListeners();
  }

  void setSearchQuery(String value) {
    if (searchController.text != value) {
      searchController.text = value;
      searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: searchController.text.length),
      );
    }

    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _searchQuery = value;
      _applySearch();
    });
  }

  Future<void> setType(String? value) async {
    if (value == null || value == _selectedType) return;
    _selectedType = value;
    await loadAgentsFromFirebase();
  }

  Future<void> setDepartment(String? value) async {
    if (value == null || value == _selectedDepartment) return;
    _selectedDepartment = value;
    await loadAgentsFromFirebase();
  }

  Future<void> setStatus(bool? value) async {
    if (value == _selectedActif) return;
    _selectedActif = value;
    await loadAgentsFromFirebase();
  }

  void setBulkDepartment(Department? value) {
    _bulkDepartment = value;
    notifyListeners();
  }

  void setBulkAgentType(AgentType? value) {
    _bulkAgentType = value;
    notifyListeners();
  }

  void setBulkStatus(bool? value) {
    _bulkActif = value;
    notifyListeners();
  }

  void setReplacePhone(bool value) {
    _replacePhone = value;
    if (!value) {
      phoneController.clear();
    }
    notifyListeners();
  }

  void setReplaceEmail(bool value) {
    _replaceEmail = value;
    if (!value) {
      emailController.clear();
    }
    notifyListeners();
  }

  void setReplaceDepartment(bool value) {
    _replaceDepartment = value;
    if (!value) {
      _bulkDepartment = null;
    }
    notifyListeners();
  }

  void setReplaceAgentType(bool value) {
    _replaceAgentType = value;
    if (!value) {
      _bulkAgentType = null;
    }
    notifyListeners();
  }

  void setReplaceStatus(bool value) {
    _replaceStatus = value;
    if (!value) {
      _bulkActif = null;
    }
    notifyListeners();
  }

  void setReplaceLastNamePrefix(bool value) {
    _replaceLastNamePrefix = value;
    if (!value) {
      lastNamePrefixController.clear();
      _preserveExistingNumbering = true;
    }
    notifyListeners();
  }

  void setPreserveExistingNumbering(bool value) {
    _preserveExistingNumbering = value;
    notifyListeners();
  }

  void toggleSelection(Agent agent) {
    if (_selectedCodes.contains(agent.code)) {
      _selectedCodes.remove(agent.code);
    } else {
      _selectedCodes.add(agent.code);
    }
    notifyListeners();
  }

  void selectAllVisible() {
    _selectedCodes.addAll(_visibleAgents.map((agent) => agent.code));
    notifyListeners();
  }

  void clearSelection() {
    _selectedCodes.clear();
    notifyListeners();
  }

  void selectOnlyVisible() {
    _selectedCodes = _visibleAgents.map((agent) => agent.code).toSet();
    notifyListeners();
  }

  Future<void> applyBulkUpdate() async {
    if (_selectedCodes.isEmpty || _isSubmitting) return;

    _errorMessage = null;

    final shouldUpdateAnything = _replacePhone ||
        _replaceEmail ||
        _replaceDepartment ||
        _replaceAgentType ||
        _replaceStatus ||
        _replaceLastNamePrefix;

    if (!shouldUpdateAnything) {
      _errorMessage =
          'Choisis au moins un champ à mettre à jour avant de lancer le traitement.';
      notifyListeners();
      return;
    }

    if (_replacePhone && phoneController.text.trim().isEmpty) {
      _errorMessage = 'Le téléphone de remplacement est obligatoire.';
      notifyListeners();
      return;
    }

    if (_replaceDepartment && _bulkDepartment == null) {
      _errorMessage = 'Le département de remplacement est obligatoire.';
      notifyListeners();
      return;
    }

    if (_replaceAgentType && _bulkAgentType == null) {
      _errorMessage = 'Le type d’agent de remplacement est obligatoire.';
      notifyListeners();
      return;
    }

    if (_replaceStatus && _bulkActif == null) {
      _errorMessage = 'Le statut de remplacement est obligatoire.';
      notifyListeners();
      return;
    }

    if (_replaceLastNamePrefix &&
        lastNamePrefixController.text.trim().isEmpty &&
        !_preserveExistingNumbering) {
      _errorMessage =
          'Le texte de remplacement du nom est obligatoire si la numérotation n’est pas conservée.';
      notifyListeners();
      return;
    }

    _isSubmitting = true;
    _submitMessage =
        'Mise à jour de $selectedCount agent${selectedCount > 1 ? 's' : ''} en cours...';
    notifyListeners();

    try {
      final selected = selectedAgents;
      final updatedAgents = <Agent>[];

      for (final agent in selected) {
        final updated = Agent(
          code: agent.code,
          firstName: agent.firstName,
          lastName: agent.lastName,
          phone: agent.phone,
          email: agent.email,
          tracking: agent.tracking,
          site: agent.site,
          department: agent.department,
          typeAgent: agent.typeAgent,
          actif: agent.actif,
          docs: List<DocumentFile>.from(agent.docs ?? const <DocumentFile>[]),
          contacts: List<ConactReference>.from(
              agent.contacts ?? const <ConactReference>[]),
          dateEmbauche: agent.dateEmbauche,
          dateArret: agent.dateArret,
        );

        if (_replacePhone) {
          updated.phone = phoneController.text.trim();
        }

        if (_replaceEmail) {
          updated.email = emailController.text.trim();
        }

        if (_replaceDepartment) {
          updated.department = _bulkDepartment;
        }

        if (_replaceAgentType) {
          updated.typeAgent = _bulkAgentType;
        }

        if (_replaceStatus) {
          updated.actif = _bulkActif;
        }

        if (_replaceLastNamePrefix) {
          updated.lastName = _buildUpdatedLastName(updated.lastName);
        }

        updatedAgents.add(updated);
      }

      await _agentService.bulkUpdate(updatedAgents);

      final updatedByCode = <String, Agent>{
        for (final agent in updatedAgents) agent.code: agent,
      };

      _loadedAgents = _loadedAgents
          .map((agent) => updatedByCode[agent.code] ?? agent)
          .toList();
      _applySearch(notify: false);

      _submitMessage = 'Mise à jour terminée.';
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 400));
    } catch (error) {
      _errorMessage = 'Erreur mise à jour groupée: $error';
      rethrow;
    } finally {
      _isSubmitting = false;
      _submitMessage = 'Traitement en cours...';
      notifyListeners();
    }
  }

  Future<void> applyBulkDelete() async {
    if (_selectedCodes.isEmpty || _isSubmitting) return;

    _isSubmitting = true;
    _errorMessage = null;
    _submitMessage =
        'Suppression de $selectedCount agent${selectedCount > 1 ? 's' : ''} en cours...';
    notifyListeners();

    try {
      final selected = selectedAgents;
      await _agentService.bulkDelete(selected);

      _loadedAgents = _loadedAgents
          .where((agent) => !_selectedCodes.contains(agent.code))
          .toList();
      _selectedCodes.clear();
      _applySearch(notify: false);

      _submitMessage = 'Suppression terminée.';
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 400));
    } catch (error) {
      _errorMessage = 'Erreur suppression groupée: $error';
      rethrow;
    } finally {
      _isSubmitting = false;
      _submitMessage = 'Traitement en cours...';
      notifyListeners();
    }
  }

  void resetFilters() {
    _searchDebounce?.cancel();
    searchController.clear();
    _selectedActif = true;
    _selectedType = 'Tous';
    _selectedDepartment = 'Tous';
    _searchQuery = '';
    _errorMessage = null;

    unawaited(loadAgentsFromFirebase());
  }

  void resetBulkForm() {
    _bulkDepartment = null;
    _bulkAgentType = null;
    _bulkActif = null;

    _replacePhone = false;
    _replaceEmail = false;
    _replaceDepartment = false;
    _replaceAgentType = false;
    _replaceStatus = false;
    _replaceLastNamePrefix = false;
    _preserveExistingNumbering = true;

    phoneController.clear();
    emailController.clear();
    lastNamePrefixController.clear();

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _applySearch({bool notify = true}) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      _visibleAgents = List<Agent>.from(_loadedAgents);
      if (notify) {
        notifyListeners();
      }
      return;
    }

    _visibleAgents = _loadedAgents.where((agent) {
      final values = <String>[
        agent.code,
        agent.firstName,
        agent.lastName,
        agent.phone,
        agent.email,
        agent.site?.name ?? '',
        agent.department?.label ?? '',
        agent.typeAgent?.label ?? '',
      ];

      return values.any(
        (value) => value.toLowerCase().contains(query),
      );
    }).toList();

    if (notify) {
      notifyListeners();
    }
  }

  String _buildUpdatedLastName(String currentLastName) {
    final prefix = lastNamePrefixController.text.trim();
    if (prefix.isEmpty) {
      return currentLastName;
    }

    if (_preserveExistingNumbering) {
      final numberMatch = RegExp(r'\d+').firstMatch(currentLastName);
      final numberPart = numberMatch?.group(0);
      if (numberPart != null && numberPart.isNotEmpty) {
        return '$prefix $numberPart';
      }
    }

    return prefix;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    phoneController.dispose();
    emailController.dispose();
    lastNamePrefixController.dispose();
    super.dispose();
  }
}
