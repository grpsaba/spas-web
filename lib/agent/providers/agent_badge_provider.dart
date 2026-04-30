import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agent.dart';
import 'package:spas_web/services/department.dart';

class AgentBadgeProvider extends ChangeNotifier {
  AgentBadgeProvider({
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

  List<Department> _departments = <Department>[];
  List<Agent> _loadedAgents = <Agent>[];
  List<Agent> _visibleAgents = <Agent>[];
  Set<String> _selectedCodes = <String>{};

  bool _isLoadingDepartments = false;
  bool _isLoadingAgents = false;
  bool _isGeneratingBadges = false;
  String _generationMessage = 'Préparation des badges...';
  String? _errorMessage;

  bool? _selectedActif = true;
  String _selectedType = 'Tous';
  String _selectedDepartment = 'Tous';
  String _searchQuery = '';

  bool _useCurrentList = true;

  Timer? _searchDebounce;

  List<Department> get departments =>
      List<Department>.unmodifiable(_departments);
  List<Agent> get loadedAgents => List<Agent>.unmodifiable(_loadedAgents);
  List<Agent> get visibleAgents => List<Agent>.unmodifiable(_visibleAgents);
  Set<String> get selectedCodes => Set<String>.unmodifiable(_selectedCodes);

  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isLoadingAgents => _isLoadingAgents;
  bool get isGeneratingBadges => _isGeneratingBadges;
  String get generationMessage => _generationMessage;
  String? get errorMessage => _errorMessage;

  bool? get selectedActif => _selectedActif;
  String get selectedType => _selectedType;
  String get selectedDepartment => _selectedDepartment;
  String get searchQuery => _searchQuery;

  bool get useCurrentList => _useCurrentList;

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

  Future<void> initialize({
    List<Agent>? currentAgents,
    bool useCurrentList = true,
  }) async {
    _useCurrentList = useCurrentList;
    _errorMessage = null;
    await loadDepartments();

    if (useCurrentList && currentAgents != null && currentAgents.isNotEmpty) {
      setCurrentAgents(currentAgents);
    } else {
      _loadedAgents = <Agent>[];
      _visibleAgents = <Agent>[];
      _selectedCodes.clear();
      notifyListeners();
    }
  }

  void setMode({
    required bool useCurrentList,
    List<Agent>? currentAgents,
  }) {
    _useCurrentList = useCurrentList;
    _errorMessage = null;

    if (_useCurrentList) {
      if (currentAgents != null) {
        setCurrentAgents(currentAgents);
      } else {
        _loadedAgents = <Agent>[];
        _visibleAgents = <Agent>[];
        _selectedCodes.clear();
        notifyListeners();
      }
      return;
    }

    _loadedAgents = <Agent>[];
    _visibleAgents = <Agent>[];
    _selectedCodes.clear();
    notifyListeners();
  }

  void setCurrentAgents(List<Agent> agents) {
    _loadedAgents = List<Agent>.from(agents);
    _selectedCodes = _loadedAgents.map((agent) => agent.code).toSet();
    _applySearch(notify: false);
    notifyListeners();
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
      _selectedCodes = _loadedAgents.map((agent) => agent.code).toSet();
      _applySearch(notify: false);
    } catch (error) {
      _errorMessage = 'Erreur chargement agents: $error';
    } finally {
      _isLoadingAgents = false;
      notifyListeners();
    }
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
    if (!_useCurrentList) {
      await loadAgentsFromFirebase();
    } else {
      notifyListeners();
    }
  }

  Future<void> setDepartment(String? value) async {
    if (value == null || value == _selectedDepartment) return;
    _selectedDepartment = value;
    if (!_useCurrentList) {
      await loadAgentsFromFirebase();
    } else {
      notifyListeners();
    }
  }

  Future<void> setStatus(bool? value) async {
    if (value == _selectedActif) return;
    _selectedActif = value;
    if (!_useCurrentList) {
      await loadAgentsFromFirebase();
    } else {
      notifyListeners();
    }
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

  void resetFilters({List<Agent>? currentAgents}) {
    _searchDebounce?.cancel();
    searchController.clear();
    _selectedActif = true;
    _selectedType = 'Tous';
    _selectedDepartment = 'Tous';
    _searchQuery = '';
    _errorMessage = null;

    if (_useCurrentList) {
      if (currentAgents != null) {
        setCurrentAgents(currentAgents);
      } else {
        _applySearch();
      }
      return;
    }

    unawaited(loadAgentsFromFirebase());
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> generateSelectedBadges({
    required Future<void> Function(List<Agent> agents) onGenerate,
  }) async {
    if (_selectedCodes.isEmpty || _isGeneratingBadges) {
      return;
    }

    _isGeneratingBadges = true;
    _generationMessage = 'Préparation des badges...';
    notifyListeners();

    try {
      await Future<void>.delayed(Duration.zero);
      _generationMessage =
          'Génération de $selectedCount badge${selectedCount > 1 ? 's' : ''} en cours...';
      notifyListeners();

      await onGenerate(selectedAgents);

      _generationMessage = 'Ouverture du document...';
      notifyListeners();

      await Future<void>.delayed(const Duration(milliseconds: 900));
    } catch (error) {
      _errorMessage = 'Erreur génération badges: $error';
      rethrow;
    } finally {
      _isGeneratingBadges = false;
      _generationMessage = 'Préparation des badges...';
      notifyListeners();
    }
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

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
