import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/pointage_weighted_engine.dart';
import 'package:spas_web/services/site.dart';

/// Provider pour gérer les données de statut des sites (pointés/non pointés)
/// Optimisé pour éviter les requêtes répétées et le filtrage côté client
class SiteStatusProvider extends ChangeNotifier {
  final SiteService _siteService = SiteService();
  
  bool _isLoading = false;
  String? _error;
  List<Site> _allSites = [];
  List<Site> _visitedSites = [];
  List<Site> _unvisitedSites = [];
  double _realizedWeight = 0;
  double _expectedWeight = 0;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Site> get allSites => _allSites;
  List<Site> get visitedSites => _visitedSites;
  List<Site> get unvisitedSites => _unvisitedSites;
  int get totalSites => _allSites.length;
  int get visitedCount => _visitedSites.length;
  int get unvisitedCount => _unvisitedSites.length;
  double get realizedWeight => _realizedWeight;
  double get expectedWeight => _expectedWeight;
  double get progressPercent =>
      _expectedWeight <= 0 ? 0 : (_realizedWeight * 100 / _expectedWeight);

  /// Charge les données pour un superviseur avec filtre de date
  Future<void> loadForSupervisor({
    required Supervisor supervisor,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _setLoading(true);
    _error = null;
    _realizedWeight = 0;
    _expectedWeight = 0;

    try {
      // Charger les sites du superviseur en parallèle avec les pointages
      final results = await Future.wait([
        _siteService.allBySupervisor(supervisor),
        _getPointingDocsBySupervisor(supervisor, startDate, endDate),
      ]);

      _allSites = results[0] as List<Site>;
      final pointingDocs = results[1] as List<Map<String, dynamic>>;

      final uniqueDays = _countRequestedDays(startDate, endDate);
      final weighted = PointageWeightedEngine.computeForSitePointings(
        allSites: _allSites,
        pointingDocs: pointingDocs,
        supervisorUid: supervisor.UID,
        periodDays: uniqueDays,
      );

      _realizedWeight = weighted.realizedWeight;
      _expectedWeight = weighted.expectedWeight;

      // Séparer les sites visités et non visités
      final pointedSiteIds = _extractVisitedSiteIds(pointingDocs);
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
      _realizedWeight = 0;
      _expectedWeight = 0;
      _allSites = [];
      _visitedSites = [];
      _unvisitedSites = [];
      notifyListeners();
      return;
    }

    _setLoading(true);
    _error = null;
    _realizedWeight = 0;
    _expectedWeight = 0;

    try {
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = month.month == 12
          ? DateTime(month.year + 1, 1, 1)
          : DateTime(month.year, month.month + 1, 1);

      // Charger en parallèle
      final results = await Future.wait([
        _siteService.allByZone(zoneMember.zone!),
        _getPointingDocsByZoneMember(zoneMember, startOfMonth, endOfMonth),
      ]);

      _allSites = results[0] as List<Site>;
      final pointingDocs = results[1] as List<Map<String, dynamic>>;

      final periodDays = endOfMonth.difference(startOfMonth).inDays;
      final weighted = await PointageWeightedEngine.computeForZonePointings(
        allSites: _allSites,
        pointingDocs: pointingDocs,
        zoneMemberUid: zoneMember.UID,
        periodDays: periodDays <= 0 ? 1 : periodDays,
      );

      _realizedWeight = weighted.realizedWeight;
      _expectedWeight = weighted.expectedWeight;

      // Séparer les sites
      final pointedSiteIds = _extractVisitedSiteIds(pointingDocs);
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

  /// Récupère les documents de pointage site pour un superviseur (requête optimisée)
  Future<List<Map<String, dynamic>>> _getPointingDocsBySupervisor(
    Supervisor supervisor,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final CollectionReference<Map<String, dynamic>> collection =
        FirebaseFirestore.instance.collection('sitePointings');

    final snapshot = await collection
        .where('supervisor.UID', isEqualTo: supervisor.UID)
        .where('datetimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('datetimestamp', isLessThan: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => Map<String, dynamic>.from(doc.data()))
        .toList();
  }

  /// Récupère les documents de pointage zone pour un membre de zone (requête optimisée)
  Future<List<Map<String, dynamic>>> _getPointingDocsByZoneMember(
    ZoneMember zoneMember,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final CollectionReference<Map<String, dynamic>> collection =
        FirebaseFirestore.instance.collection('zonePointings');

    final snapshot = await collection
        .where('zoneMember.UID', isEqualTo: zoneMember.UID)
        .where('datetimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('datetimestamp', isLessThan: Timestamp.fromDate(endDate))
        .get();

    return snapshot.docs
        .map((doc) => Map<String, dynamic>.from(doc.data()))
        .toList();
  }

  Set<String> _extractVisitedSiteIds(List<Map<String, dynamic>> pointingDocs) {
    return pointingDocs
        .map((doc) {
          final site = doc['site'];
          if (site is Map<String, dynamic>) {
            final uid = site['UID'];
            if (uid is String && uid.isNotEmpty) return uid;
          }
          return null;
        })
        .whereType<String>()
        .toSet();
  }

  int _countRequestedDays(DateTime startDate, DateTime endDate) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);

    final isExclusiveEnd = endDate.hour == 0 &&
        endDate.minute == 0 &&
        endDate.second == 0 &&
        endDate.millisecond == 0 &&
        endDate.microsecond == 0;

    final days = isExclusiveEnd
        ? end.difference(start).inDays
        : end.difference(start).inDays + 1;

    return days <= 0 ? 1 : days;
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
