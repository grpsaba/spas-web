import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/site.dart';
import 'package:spas_web/services/tenant_scope.dart';

/// Provider pour gérer les données de statut des sites (pointés/non pointés)
/// Optimisé pour éviter les requêtes répétées et le filtrage côté client
class SiteStatusProvider extends ChangeNotifier {
  final SiteService _siteService = SiteService();
  
  bool _isLoading = false;
  String? _error;
  List<Site> _allSites = [];
  List<Site> _visitedSites = [];
  List<Site> _unvisitedSites = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Site> get allSites => _allSites;
  List<Site> get visitedSites => _visitedSites;
  List<Site> get unvisitedSites => _unvisitedSites;
  int get totalSites => _allSites.length;
  int get visitedCount => _visitedSites.length;
  int get unvisitedCount => _unvisitedSites.length;
  double get progressPercent => totalSites > 0 ? (visitedCount / totalSites) * 100 : 0;

  /// Charge les données pour un superviseur avec filtre de date
  Future<void> loadForSupervisor({
    required Supervisor supervisor,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _error = null;
    
    try {
      // Charger les sites du superviseur en parallèle avec les pointages
      final results = await Future.wait([
        _siteService.allBySupervisor(supervisor),
        _getPointedSiteIdsBySupervisor(supervisor, startDate, endDate),
      ]);
      
      _allSites = results[0] as List<Site>;
      final pointedSiteIds = results[1] as Set<String>;
      
      // Séparer les sites visités et non visités
      _visitedSites = [];
      _unvisitedSites = [];
      
      for (final site in _allSites) {
        if (pointedSiteIds.contains(site.UID)) {
          _visitedSites.add(site);
        } else {
          _unvisitedSites.add(site);
        }
      }
      
    } catch (e) {
      _error = 'Erreur lors du chargement: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Charge les données pour un membre de zone avec filtre de mois
  Future<void> loadForZoneMember({
    required ZoneMember zoneMember,
    required DateTime month,
  }) async {
    if (zoneMember.zone == null) {
      _error = 'Zone non définie pour ce membre';
      notifyListeners();
      return;
    }
    
    _setLoading(true);
    _error = null;
    
    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = month.month == 12
          ? DateTime(month.year + 1, 1, 1)
          : DateTime(month.year, month.month + 1, 1);
      
      // Charger en parallèle
      final results = await Future.wait([
        _siteService.allByZone(zoneMember.zone!),
        _getPointedSiteIdsByZoneMember(zoneMember, startOfMonth, endOfMonth),
      ]);
      
      _allSites = results[0] as List<Site>;
      final pointedSiteIds = results[1] as Set<String>;
      
      // Séparer les sites
      _visitedSites = [];
      _unvisitedSites = [];
      
      for (final site in _allSites) {
        if (pointedSiteIds.contains(site.UID)) {
          _visitedSites.add(site);
        } else {
          _unvisitedSites.add(site);
        }
      }
      
    } catch (e) {
      _error = 'Erreur lors du chargement: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Récupère les IDs des sites pointés par un superviseur (requête optimisée)
  Future<Set<String>> _getPointedSiteIdsBySupervisor(
    Supervisor supervisor,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final collection = FirebaseFirestore.instance.collection('sitePointings');

    final snapshot = await TenantScope.getQuery(
      'SiteStatusProvider.pointedSitesBySupervisor',
      TenantScope.applyToQuery(collection)
          .where('supervisor.UID', isEqualTo: supervisor.UID)
          .where(
            'datetimestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('datetimestamp', isLessThan: Timestamp.fromDate(endDate)),
    );
    
    return snapshot.docs
        .map((doc) => doc.data()['site']?['UID'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet();
  }

  /// Récupère les IDs des sites pointés par un membre de zone (requête optimisée)
  Future<Set<String>> _getPointedSiteIdsByZoneMember(
    ZoneMember zoneMember,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final collection = FirebaseFirestore.instance.collection('zonePointings');

    final snapshot = await TenantScope.getQuery(
      'SiteStatusProvider.pointedSitesByZoneMember',
      TenantScope.applyToQuery(collection)
          .where('zoneMember.UID', isEqualTo: zoneMember.UID)
          .where(
            'datetimestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
          )
          .where('datetimestamp', isLessThan: Timestamp.fromDate(endDate)),
    );
    
    return snapshot.docs
        .map((doc) => doc.data()['site']?['UID'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clear() {
    _allSites = [];
    _visitedSites = [];
    _unvisitedSites = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
