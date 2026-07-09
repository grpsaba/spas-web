import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agent.dart';
import 'package:spas_web/services/department.dart';

class AgentListProvider extends ChangeNotifier {
  AgentListProvider({
    AgentService? agentService,
    DepartmentService? departmentService,
  })  : _agentService = agentService ?? AgentService(),
        _departmentService = departmentService ?? DepartmentService();

  static const int defaultRowsPerPage = 20;
  static const List<String> typeOptions = <String>[
    'Tous',
    'FIXE',
    'POINT ZERO',
    'RONDIER',
  ];

  final AgentService _agentService;
  final DepartmentService _departmentService;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<Agent> _agents = <Agent>[];
  List<Agent> _filteredAgents = <Agent>[];
  List<Department> _departments = <Department>[];

  bool? _selectedActif = true;
  String _selectedType = 'Tous';
  String _selectedDepartment = 'Tous';
  String _searchQuery = '';

  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingDepartments = false;
  bool _isRefreshing = false;
  bool _hasMore = true;
  String? _errorMessage;

  int _rowsPerPage = defaultRowsPerPage;

  DocumentSnapshot? _lastDocument;
  Timer? _searchDebounce;
  int _searchRequestId = 0;

  List<Agent> get agents => List<Agent>.unmodifiable(_agents);
  List<Agent> get filteredAgents => List<Agent>.unmodifiable(_filteredAgents);
  List<Department> get departments =>
      List<Department>.unmodifiable(_departments);

  bool? get selectedActif => _selectedActif;
  String get selectedType => _selectedType;
  String get selectedDepartment => _selectedDepartment;
  String get searchQuery => _searchQuery;

  bool get isInitialLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isLoadingDepartments => _isLoadingDepartments;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  int get rowsPerPage => _rowsPerPage;

  int get loadedCount => _agents.length;
  int get filteredCount => _filteredAgents.length;

  bool get shouldUseExternalScroll => filteredCount > rowsPerPage;
  int get effectiveRowsPerPage {
    if (filteredCount == 0) {
      return 1;
    }
    return filteredCount < rowsPerPage ? filteredCount : rowsPerPage;
  }

  String get loadedCountText {
    if (loadedCount == 0) {
      return 'Aucun agent chargé';
    }

    final base =
        '$loadedCount agent${loadedCount > 1 ? 's' : ''} chargé${loadedCount > 1 ? 's' : ''}';

    if (_hasMore) {
      return '$base (chargement partiel)';
    }

    return '$base (liste complète chargée)';
  }

  List<Agent> get exportableAgents => List<Agent>.unmodifiable(_filteredAgents);

  Future<void> initialize() async {
    await Future.wait([
      loadDepartments(),
      loadInitialData(),
    ]);
  }

  Future<void> refresh() async {
    if (_searchQuery.trim().isNotEmpty) {
      await _loadSearchResults();
      return;
    }

    await loadInitialData();
  }

  Future<void> loadInitialData() async {
    final requestId = ++_searchRequestId;
    final hasExistingData = _agents.isNotEmpty;
    _isInitialLoading = !hasExistingData;
    _isRefreshing = hasExistingData;
    _errorMessage = null;
    _lastDocument = null;
    _hasMore = true;
    if (!hasExistingData) {
      _agents.clear();
      _filteredAgents = <Agent>[];
    }
    notifyListeners();

    try {
      final result = await _agentService.fetchPage(
        limit: _rowsPerPage,
        actif: _selectedActif,
        agentTypeLabel: _selectedType == 'Tous' ? null : _selectedType.trim(),
        departmentLabel:
            _selectedDepartment == 'Tous' ? null : _selectedDepartment.trim(),
      );

      if (requestId != _searchRequestId) return;

      _agents
        ..clear()
        ..addAll(result.agents);
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;

      _applyFilters(notify: false);
    } catch (error) {
      if (requestId != _searchRequestId) return;
      _hasMore = false;
      _errorMessage = error.toString();
    } finally {
      if (requestId == _searchRequestId) {
        _isInitialLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMoreAgents() async {
    if (_searchQuery.trim().isNotEmpty || _isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _agentService.fetchPage(
        limit: _rowsPerPage,
        startAfterDocument: _lastDocument,
        actif: _selectedActif,
        agentTypeLabel: _selectedType == 'Tous' ? null : _selectedType.trim(),
        departmentLabel:
            _selectedDepartment == 'Tous' ? null : _selectedDepartment.trim(),
      );

      _agents.addAll(result.agents);
      _lastDocument = result.lastDocument;
      _hasMore = result.hasMore;

      _applyFilters(notify: false);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
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
    } catch (_) {
      _departments = <Department>[];
    } finally {
      _isLoadingDepartments = false;
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
    _searchDebounce = Timer(const Duration(milliseconds: 300), () async {
      _searchQuery = value;

      if (_searchQuery.trim().isEmpty) {
        await loadInitialData();
      } else {
        await _loadSearchResults();
      }
    });
  }

  Future<void> setType(String? value) async {
    if (value == null || value == _selectedType) return;
    _selectedType = value;
    await _reloadCurrentMode();
  }

  Future<void> setDepartment(String? value) async {
    if (value == null || value == _selectedDepartment) return;
    _selectedDepartment = value;
    await _reloadCurrentMode();
  }

  Future<void> setStatus(bool? value) async {
    if (value == _selectedActif) return;
    _selectedActif = value;
    await _reloadCurrentMode();
  }

  Future<void> resetFilters() async {
    _searchDebounce?.cancel();
    searchController.clear();
    _selectedActif = true;
    _selectedType = 'Tous';
    _selectedDepartment = 'Tous';
    _searchQuery = '';
    await loadInitialData();
  }

  Future<void> increaseRowsPerPage() async {
    _rowsPerPage += 10;
    await loadInitialData();
  }

  Future<void> decreaseRowsPerPage() async {
    _rowsPerPage = _rowsPerPage <= defaultRowsPerPage
        ? defaultRowsPerPage
        : _rowsPerPage - 10;
    await loadInitialData();
  }

  Future<void> setRowsPerPage(int value) async {
    if (value <= 0 || value == _rowsPerPage) return;
    _rowsPerPage = value;
    await _reloadCurrentMode();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String get resultText {
    if (_isInitialLoading) {
      return 'Chargement...';
    }

    final resultLabel =
        '$filteredCount résultat${filteredCount > 1 ? 's' : ''}';

    if (loadedCount == 0) {
      return resultLabel;
    }

    if (_hasMore) {
      return '$resultLabel • $loadedCount agent${loadedCount > 1 ? 's' : ''} actuellement chargé${loadedCount > 1 ? 's' : ''}';
    }

    return '$resultLabel • $loadedCount agent${loadedCount > 1 ? 's' : ''} chargé${loadedCount > 1 ? 's' : ''} au total';
  }

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

  void _applyFilters({bool notify = true}) {
    final query = _searchQuery.trim().toLowerCase();

    _filteredAgents = _agents.where((agent) {
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

      if (query.isEmpty) {
        return matchesStatus && matchesType && matchesDepartment;
      }

      final searchValues = <String>[
        agent.code,
        agent.firstName,
        agent.lastName,
        agent.phone,
        agent.email,
        agent.site?.name ?? '',
        agent.department?.label ?? '',
        agent.typeAgent?.label ?? '',
      ].map((value) => value.toLowerCase());

      final matchesSearch = searchValues.any((value) => value.contains(query));

      return matchesStatus && matchesType && matchesDepartment && matchesSearch;
    }).toList();

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> _reloadCurrentMode() async {
    if (_searchQuery.trim().isNotEmpty) {
      await _loadSearchResults();
      return;
    }

    await loadInitialData();
  }

  Future<void> _loadSearchResults() async {
    final query = _searchQuery.trim();
    if (query.isEmpty) {
      await loadInitialData();
      return;
    }

    final requestId = ++_searchRequestId;
    final hasExistingData = _agents.isNotEmpty;
    _isInitialLoading = !hasExistingData;
    _isRefreshing = hasExistingData;
    _errorMessage = null;
    _lastDocument = null;
    _hasMore = false;
    if (!hasExistingData) {
      _agents.clear();
      _filteredAgents = <Agent>[];
    }
    notifyListeners();

    try {
      final agents = await _agentService.searchByPrefix(
        query: query,
        limit: 100,
        actif: _selectedActif,
        agentTypeLabel: _selectedType == 'Tous' ? null : _selectedType.trim(),
        departmentLabel:
            _selectedDepartment == 'Tous' ? null : _selectedDepartment.trim(),
      );

      if (requestId != _searchRequestId) return;

      _agents
        ..clear()
        ..addAll(agents);
      _filteredAgents = List<Agent>.from(agents);
      _hasMore = false;
    } catch (error) {
      if (requestId != _searchRequestId) return;
      _hasMore = false;
      _errorMessage = error.toString();
    } finally {
      if (requestId == _searchRequestId) {
        _isInitialLoading = false;
        _isRefreshing = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}
