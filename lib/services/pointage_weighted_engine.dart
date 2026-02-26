import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

/// Types de pointage supportés côté métier.
class SitePointingType {
  static const String jour = 'jour';
  static const String nuit = 'nuit';
  static const String jourNuit = 'jour_nuit';

  static const Set<String> allowed = {jour, nuit, jourNuit};
}

/// Période opérationnelle d'un pointage.
enum PointagePeriod { jour, nuit }

/// Résultat agrégé pondéré.
class WeightedPointageResult {
  final double realizedWeight;
  final double expectedWeight;
  final int visitedSites;
  final int totalSites;

  const WeightedPointageResult({
    required this.realizedWeight,
    required this.expectedWeight,
    required this.visitedSites,
    required this.totalSites,
  });

  double get performancePercent =>
      expectedWeight <= 0 ? 0 : (realizedWeight * 100.0 / expectedWeight);

  int get unvisitedSites =>
      (totalSites - visitedSites) < 0 ? 0 : (totalSites - visitedSites);
}

class _SiteDayAccumulator {
  final String siteType;
  bool hasJour = false;
  bool hasNuit = false;

  _SiteDayAccumulator({required this.siteType});

  void add(PointagePeriod period) {
    if (period == PointagePeriod.jour) {
      hasJour = true;
    } else {
      hasNuit = true;
    }
  }

  double realizedWeight() {
    switch (siteType) {
      case SitePointingType.nuit:
        return hasNuit ? 1.0 : 0.0;
      case SitePointingType.jourNuit:
        return (hasJour ? 0.5 : 0.0) + (hasNuit ? 0.5 : 0.0);
      case SitePointingType.jour:
      default:
        return hasJour ? 1.0 : 0.0;
    }
  }
}

class PointageWeightedEngine {
  static const int _jourStartHour = 2;
  static const int _nightStartHour = 18;

  /// Fallback de compatibilité: null/missing/invalid -> jour
  static String normalizePointingType(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (SitePointingType.allowed.contains(normalized)) {
      return normalized;
    }
    return SitePointingType.jour;
  }

  /// JOUR: [02:00, 18:00), NUIT: [18:00, 02:00)
  /// Cas métier explicitement validé: 02:00 => JOUR
  static PointagePeriod classifyPeriod(DateTime timestamp) {
    final hour = timestamp.hour;
    if (hour >= _jourStartHour && hour < _nightStartHour) {
      return PointagePeriod.jour;
    }
    return PointagePeriod.nuit;
  }

  /// Journée opérationnelle avec borne à 02:00.
  /// 00:00..01:59 appartient à la journée opérationnelle précédente.
  static DateTime operationalDay(DateTime timestamp) {
    final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
    if (timestamp.hour < _jourStartHour) {
      return day.subtract(const Duration(days: 1));
    }
    return day;
  }

  static String? _extractSiteIdFromMap(Map<String, dynamic> data) {
    final siteData = data['site'];
    if (siteData is Map<String, dynamic>) {
      final uid = siteData['UID'];
      if (uid is String && uid.isNotEmpty) return uid;
    }
    return null;
  }

  static DateTime? _extractDateFromMap(Map<String, dynamic> data) {
    final ts = data['datetimestamp'];
    if (ts is DateTime) return ts;
    if (ts is Timestamp) return ts.toDate();
    if (ts is String && ts.isNotEmpty) {
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) return parsed;
    }

    final date = data['date'];
    if (date is DateTime) return date;
    if (date is Timestamp) return date.toDate();
    if (date is String && date.isNotEmpty) {
      return DateTime.tryParse(date);
    }

    return null;
  }

  static PointagePeriod? _extractPeriodFromMap(Map<String, dynamic> data) {
    final raw = (data['period'] ?? '').toString().trim().toLowerCase();
    if (raw == SitePointingType.jour) return PointagePeriod.jour;
    if (raw == SitePointingType.nuit) return PointagePeriod.nuit;
    return null;
  }

  static DateTime? _extractOperationalDayFromMap(Map<String, dynamic> data) {
    final raw = data['operationalDay'];
    if (raw is DateTime) {
      return DateTime(raw.year, raw.month, raw.day);
    }
    if (raw is Timestamp) {
      final d = raw.toDate();
      return DateTime(d.year, d.month, d.day);
    }
    if (raw is String && raw.isNotEmpty) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    return null;
  }

  static String _resolveTypeForSite(Map<String, Site> siteById, String siteId) {
    final site = siteById[siteId];
    return normalizePointingType(site?.pointingType);
  }

  static WeightedPointageResult computeForSitePointings({
    required List<Site> allSites,
    required List<Map<String, dynamic>> pointingDocs,
    String? supervisorUid,
    int periodDays = 1,
  }) {
    final Map<String, Site> sitesById = {
      for (final site in allSites) site.UID: site,
    };

    final Map<String, _SiteDayAccumulator> bySiteDay = {};
    final Set<String> visited = {};

    for (final doc in pointingDocs) {
      final siteId = _extractSiteIdFromMap(doc);
      if (siteId == null || !sitesById.containsKey(siteId)) continue;

      if (supervisorUid != null) {
        final supervisor = doc['supervisor'];
        final uid = (supervisor is Map<String, dynamic>) ? supervisor['UID'] : null;
        if (uid != supervisorUid) continue;
      }

      final date = _extractDateFromMap(doc);
      if (date == null) continue;

      final type = _resolveTypeForSite(sitesById, siteId);
      final period = _extractPeriodFromMap(doc) ?? classifyPeriod(date);
      final opDay = _extractOperationalDayFromMap(doc) ?? operationalDay(date);
      final key = '$siteId|${opDay.toIso8601String()}';

      final accumulator = bySiteDay.putIfAbsent(
        key,
        () => _SiteDayAccumulator(siteType: type),
      );
      accumulator.add(period);
      visited.add(siteId);
    }

    double realizedWeight = 0;
    for (final acc in bySiteDay.values) {
      realizedWeight += acc.realizedWeight();
    }

    final expectedWeight = (allSites.length * periodDays).toDouble();

    return WeightedPointageResult(
      realizedWeight: realizedWeight,
      expectedWeight: expectedWeight,
      visitedSites: visited.length,
      totalSites: allSites.length,
    );
  }

  static Future<WeightedPointageResult> computeForZonePointings({
    required List<Site> allSites,
    required List<Map<String, dynamic>> pointingDocs,
    required String zoneMemberUid,
    int periodDays = 1,
  }) async {
    final Map<String, Site> sitesById = {
      for (final site in allSites) site.UID: site,
    };

    final Map<String, _SiteDayAccumulator> bySiteDay = {};
    final Set<String> visited = {};

    for (final doc in pointingDocs) {
      final zoneMember = doc['zoneMember'];
      final uid = (zoneMember is Map<String, dynamic>) ? zoneMember['UID'] : null;
      if (uid != zoneMemberUid) continue;

      final siteId = _extractSiteIdFromMap(doc);
      if (siteId == null || !sitesById.containsKey(siteId)) continue;

      final date = _extractDateFromMap(doc);
      if (date == null) continue;

      final type = _resolveTypeForSite(sitesById, siteId);
      final period = _extractPeriodFromMap(doc) ?? classifyPeriod(date);
      final opDay = _extractOperationalDayFromMap(doc) ?? operationalDay(date);
      final key = '$siteId|${opDay.toIso8601String()}';

      final accumulator = bySiteDay.putIfAbsent(
        key,
        () => _SiteDayAccumulator(siteType: type),
      );
      accumulator.add(period);
      visited.add(siteId);
    }

    double realizedWeight = 0;
    for (final acc in bySiteDay.values) {
      realizedWeight += acc.realizedWeight();
    }

    final expectedWeight = (allSites.length * periodDays).toDouble();

    return WeightedPointageResult(
      realizedWeight: realizedWeight,
      expectedWeight: expectedWeight,
      visitedSites: visited.length,
      totalSites: allSites.length,
    );
  }

  /// Calcul pondéré pour rapports superviseur (mensuel/période).
  static Map<String, dynamic> computeSupervisorPeriodMetrics({
    required Supervisor supervisor,
    required List<Site> assignedSites,
    required List<Map<String, dynamic>> dailyPointages,
    required int periodDays,
  }) {
    final Map<String, Site> sitesById = {
      for (final site in assignedSites) site.UID: site,
    };

    final Map<String, _SiteDayAccumulator> bySiteDay = {};

    for (final p in dailyPointages) {
      final dynamic dateRaw = p['date'];
      final dynamic pointsRaw = p['pointages'];
      if (dateRaw is! DateTime || pointsRaw is! List) continue;

      for (final raw in pointsRaw) {
        if (raw is! PointingSite) continue;

        final siteId = raw.site.UID;
        if (!sitesById.containsKey(siteId)) continue;

        final hasSupervisor = raw.supervisor?.UID == supervisor.UID;
        final hasSecondary = raw.site.supervisor_2?.UID == supervisor.UID;
        if (!hasSupervisor && !hasSecondary) continue;

        final type = normalizePointingType(sitesById[siteId]?.pointingType);
        final period = classifyPeriod(raw.date);
        final opDay = operationalDay(raw.date);
        final key = '$siteId|${opDay.toIso8601String()}';

        final accumulator = bySiteDay.putIfAbsent(
          key,
          () => _SiteDayAccumulator(siteType: type),
        );
        accumulator.add(period);
      }
    }

    double realizedWeight = 0;
    for (final acc in bySiteDay.values) {
      realizedWeight += acc.realizedWeight();
    }

    final expectedWeight = assignedSites.length * periodDays.toDouble();
    final performance = expectedWeight <= 0
        ? 0.0
        : (realizedWeight * 100.0 / expectedWeight);

    return {
      'realizedWeight': realizedWeight,
      'expectedWeight': expectedWeight,
      'performance': performance,
    };
  }

  /// Calcul pondéré pour rapports chef de zone (mensuel/période).
  static Map<String, dynamic> computeZoneMemberPeriodMetrics({
    required ZoneMember zoneMember,
    required List<Site> zoneSites,
    required List<Map<String, dynamic>> dailyPointages,
    required int periodDays,
  }) {
    final Map<String, Site> sitesById = {
      for (final site in zoneSites) site.UID: site,
    };

    final Map<String, _SiteDayAccumulator> bySiteDay = {};

    for (final p in dailyPointages) {
      final dynamic pointsRaw = p['pointages'];
      if (pointsRaw is! List) continue;

      for (final raw in pointsRaw) {
        if (raw is! PointingZone) continue;
        if (raw.zoneMember?.UID != zoneMember.UID) continue;

        final siteId = raw.site.UID;
        if (!sitesById.containsKey(siteId)) continue;

        final type = normalizePointingType(sitesById[siteId]?.pointingType);
        final period = classifyPeriod(raw.date);
        final opDay = operationalDay(raw.date);
        final key = '$siteId|${opDay.toIso8601String()}';

        final accumulator = bySiteDay.putIfAbsent(
          key,
          () => _SiteDayAccumulator(siteType: type),
        );
        accumulator.add(period);
      }
    }

    double realizedWeight = 0;
    for (final acc in bySiteDay.values) {
      realizedWeight += acc.realizedWeight();
    }

    final expectedWeight = zoneSites.length * periodDays.toDouble();
    final performance = expectedWeight <= 0
        ? 0.0
        : (realizedWeight * 100.0 / expectedWeight);

    return {
      'realizedWeight': realizedWeight,
      'expectedWeight': expectedWeight,
      'performance': performance,
    };
  }
}
