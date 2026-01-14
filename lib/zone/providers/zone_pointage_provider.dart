import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/site.dart';
import 'package:spas_web/services/zoneMember.dart';

/// Modèle pour les stats de pointage d'un membre de zone
class ZoneMemberPointageStats {
  final ZoneMember zoneMember;
  final int totalSites;
  final int visitedSites;
  
  ZoneMemberPointageStats({
    required this.zoneMember,
    required this.totalSites,
    required this.visitedSites,
  });
  
  double get progressPercent => totalSites > 0 ? (visitedSites / totalSites) * 100 : 0;
}

/// Provider optimisé pour la liste des pointages par zone
class ZonePointageListProvider extends ChangeNotifier {
  final ZoneMemberService _zoneMemberService = ZoneMemberService();
  final SiteService _siteService = SiteService();
  
  bool _isLoading = false;
  String? _error;
  List<ZoneMemberPointageStats> _stats = [];
  DateTime _selectedMonth = DateTime.now();
  String _searchKeyword = '';
  
  // Cache pour éviter les requêtes répétées
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(minutes: 3);
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;
  String get searchKeyword => _searchKeyword;
  
  List<ZoneMemberPointageStats> get filteredStats {
    if (_searchKeyword.isEmpty) return _stats;
    
    final keyword = _searchKeyword.toLowerCase();
    return _stats.where((stat) {
      final fullName = '${stat.zoneMember.firstName} ${stat.zoneMember.lastName}'.toLowerCase();
      final zoneName = stat.zoneMember.zone?.name.toLowerCase() ?? '';
      final zoneCode = stat.zoneMember.zone?.codeZone.toLowerCase() ?? '';
      return fullName.contains(keyword) || zoneName.contains(keyword) || zoneCode.contains(keyword);
    }).toList();
  }
  
  bool get needsRefresh {
    if (_lastFetch == null) return true;
    return DateTime.now().difference(_lastFetch!) > _cacheTimeout;
  }

  /// Change le mois sélectionné et recharge les données
  Future<void> setMonth(DateTime month) async {
    final newMonth = DateTime(month.year, month.month);
    if (_selectedMonth.year == newMonth.year && _selectedMonth.month == newMonth.month) {
      return;
    }
    _selectedMonth = newMonth;
    _lastFetch = null; // Force refresh
    await loadData();
  }

  /// Met à jour le mot-clé de recherche
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  /// Charge les données des membres de zone avec leurs stats
  Future<void> loadData() async {
    if (_isLoading) return;
    
    _setLoading(true);
    _error = null;
    
    try {
      // 1. Charger tous les membres de zone actifs
      final zoneMembers = await _zoneMemberService.allActifAsModel();
      
      // 2. Calculer la plage de dates du mois
      final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endOfMonth = _selectedMonth.month == 12
          ? DateTime(_selectedMonth.year + 1, 1, 1)
          : DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      
      // 3. Charger les stats pour chaque membre en parallèle (par batch pour éviter surcharge)
      final List<ZoneMemberPointageStats> newStats = [];
      
      // Traiter par batch de 5 pour éviter trop de requêtes simultanées
      for (int i = 0; i < zoneMembers.length; i += 5) {
        final batch = zoneMembers.skip(i).take(5).toList();
        final batchResults = await Future.wait(
          batch.map((zm) => _loadStatsForMember(zm, startOfMonth, endOfMonth)),
        );
        newStats.addAll(batchResults.whereType<ZoneMemberPointageStats>());
      }
      
      _stats = newStats;
      _lastFetch = DateTime.now();
      
    } catch (e) {
      _error = 'Erreur lors du chargement: $e';
      debugPrint(_error);
    } finally {
      _setLoading(false);
    }
  }

  /// Charge les stats pour un membre de zone spécifique
  Future<ZoneMemberPointageStats?> _loadStatsForMember(
    ZoneMember zoneMember,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      if (zoneMember.zone == null) {
        return ZoneMemberPointageStats(
          zoneMember: zoneMember,
          totalSites: 0,
          visitedSites: 0,
        );
      }
      
      // Requêtes en parallèle
      final results = await Future.wait([
        _siteService.allSitesCountByZone(zoneMember.zone!),
        _getVisitedSitesCount(zoneMember, startDate, endDate),
      ]);
      
      final totalSites = results[0] as int? ?? 0;
      final visitedSites = results[1] as int;
      
      return ZoneMemberPointageStats(
        zoneMember: zoneMember,
        totalSites: totalSites,
        visitedSites: visitedSites,
      );
    } catch (e) {
      debugPrint('Erreur pour ${zoneMember.firstName}: $e');
      return ZoneMemberPointageStats(
        zoneMember: zoneMember,
        totalSites: 0,
        visitedSites: 0,
      );
    }
  }

  /// Compte les sites visités par un membre de zone (requête optimisée)
  Future<int> _getVisitedSitesCount(
    ZoneMember zoneMember,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final collection = FirebaseFirestore.instance.collection('zonePointings');
    
    final snapshot = await collection
        .where('zoneMember.UID', isEqualTo: zoneMember.UID)
        .where('datetimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('datetimestamp', isLessThan: Timestamp.fromDate(endDate))
        .get();
    
    // Compter les sites uniques
    final uniqueSiteIds = snapshot.docs
        .map((doc) => doc.data()['site']?['UID'] as String?)
        .where((id) => id != null)
        .toSet();
    
    return uniqueSiteIds.length;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Force le rafraîchissement des données
  Future<void> refresh() async {
    _lastFetch = null;
    await loadData();
  }

  void clear() {
    _stats = [];
    _error = null;
    _lastFetch = null;
    notifyListeners();
  }
}
