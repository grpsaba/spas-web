import 'package:flutter/material.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/site.dart';
import 'package:spas_web/services/supervisor.dart';

class HomeProvider extends ChangeNotifier {
  int _nbSite = 0;
  bool _greeting = false;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  List<Site> _sites = [];
  List<Supervisor> _supervisors = [];
  
  // Cache pour éviter les appels répétés
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 5);

  // Getters
  int get nbSite => _nbSite;
  bool get greeting => _greeting;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  List<Site> get sites => List.unmodifiable(_sites);
  List<Supervisor> get supervisors => List.unmodifiable(_supervisors);

  bool get needsRefresh {
    if (_lastFetch == null) return true;
    return DateTime.now().difference(_lastFetch!) > _cacheTimeout;
  }

  Future<void> loadData() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _setError(false, '');

    try {
      // Chargement parallèle pour optimiser les performances
      final results = await Future.wait([
        _loadSites(),
        _loadSupervisors(),
      ]);
      
      _lastFetch = DateTime.now();
      _greeting = true;
    } catch (e) {
      _setError(true, 'Erreur lors du chargement des données: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadSites() async {
    try {
      final allSites = await SiteService().allAsModel();
      _sites = allSites.where((site) => site.actif == true).toList();
      _nbSite = _sites.length;
      notifyListeners();
    } catch (e) {
      throw Exception('Impossible de charger les sites: $e');
    }
  }

  Future<void> _loadSupervisors() async {
    try {
      _supervisors = await SupervisorService().allFuture();
      notifyListeners();
    } catch (e) {
      throw Exception('Impossible de charger les superviseurs: $e');
    }
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(bool hasError, String message) {
    if (_hasError != hasError || _errorMessage != message) {
      _hasError = hasError;
      _errorMessage = message;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _clearData();
    await loadData();
  }

  void _clearData() {
    _sites.clear();
    _supervisors.clear();
    _nbSite = 0;
    _greeting = false;
    _lastFetch = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _clearData();
    super.dispose();
  }
}
