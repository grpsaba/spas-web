import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/error_logs/models/geo_diagnostic.dart';
import 'package:spas_web/models/pointing_method.dart';

class GeoRole {
  static const String supervisor = 'supervisor';
  static const String zoneChief = 'zone_chief';

  static String label(String? role) =>
      role == zoneChief ? 'Chef de zone' : 'Superviseur';
}

const String unknownDeviceLabel = 'Modèle inconnu';
const String unknownVersionLabel = 'Version inconnue';

String _personName(Map? actor) {
  if (actor == null) return 'Inconnu';
  final name = '${actor['firstName'] ?? ''} ${actor['lastName'] ?? ''}'.trim();
  if (name.isNotEmpty) return name;
  final code = actor['code']?.toString().trim();
  return code == null || code.isEmpty ? 'Inconnu' : code;
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

/// One site visit (sitePointings / zonePointings document).
class GeoPointingRecord {
  const GeoPointingRecord({
    required this.personKey,
    required this.personName,
    required this.role,
    this.method,
    this.deviceModel,
    this.appVersion,
  });

  final String personKey;
  final String personName;
  final String role;

  /// Null when an old document does not allow to tell.
  final PointingMethod? method;
  final String? deviceModel;
  final String? appVersion;

  factory GeoPointingRecord.fromDocument(
    Map<String, dynamic> data, {
    required String role,
  }) {
    final actor =
        role == GeoRole.zoneChief ? data['zoneMember'] : data['supervisor'];
    final actorMap = actor is Map ? actor : null;
    return GeoPointingRecord(
      personKey: _text(actorMap?['UID']) ?? 'inconnu',
      personName: _personName(actorMap),
      role: role,
      method: PointingMethodInfo.fromDocument(data)?.method,
      deviceModel: DeviceInfoView.fromMap(data['deviceInfo'])?.modelLabel,
      appVersion: _text(data['appVersion']),
    );
  }
}

/// One non-successful geolocation attempt (error_logs with attemptOutcome).
class GeoAttemptRecord {
  const GeoAttemptRecord({
    required this.personKey,
    required this.personName,
    required this.role,
    required this.outcome,
    this.deviceModel,
    this.appVersion,
  });

  final String personKey;
  final String personName;
  final String role;
  final String outcome;
  final String? deviceModel;
  final String? appVersion;

  /// Null for logs that are not geolocation attempts (older app versions).
  static GeoAttemptRecord? fromErrorLog(ErrorLog log) {
    final outcome = log.attemptOutcome;
    if (outcome == null) return null;
    return GeoAttemptRecord(
      personKey: log.actorUID ?? 'inconnu',
      personName: log.actorName == 'N/A' ? 'Inconnu' : log.actorName,
      role: log.isZonePointing ? GeoRole.zoneChief : GeoRole.supervisor,
      outcome: outcome,
      deviceModel: log.device?.modelLabel,
      appVersion: log.appVersion,
    );
  }
}

/// Counters of one group (a person, a phone model or an app version).
class GeoStatsRow {
  GeoStatsRow({required this.key, required this.label, this.role});

  final String key;
  final String label;
  final String? role;

  int geo = 0;
  int photo = 0;
  int photoFallback = 0;
  int unknown = 0;
  final Map<String, int> failedByOutcome = {};

  int get totalPointings => geo + photo + photoFallback + unknown;
  int get failedAttempts =>
      failedByOutcome.values.fold(0, (sum, value) => sum + value);

  /// Share of geolocation-mode visits that ended with the photo fallback:
  /// photo_fallback ÷ (geo + photo_fallback). Photo-mode visits do not
  /// count. Null when there is no geolocation-mode visit.
  double? get fallbackRate {
    final geoMode = geo + photoFallback;
    return geoMode == 0 ? null : photoFallback / geoMode;
  }

  void addPointing(PointingMethod? method) {
    switch (method) {
      case PointingMethod.geo:
        geo++;
        break;
      case PointingMethod.photo:
        photo++;
        break;
      case PointingMethod.photoFallback:
        photoFallback++;
        break;
      case null:
        unknown++;
        break;
    }
  }

  void addAttempt(String outcome) =>
      failedByOutcome[outcome] = (failedByOutcome[outcome] ?? 0) + 1;

  /// "GPS trop lent 3 · Aucun signal GPS 1", most frequent first.
  String get failedSummary {
    final entries = failedByOutcome.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map((e) => '${AttemptOutcome.label(e.key)} ${e.value}')
        .join(' · ');
  }
}

class GeoStatsReport {
  GeoStatsReport({
    required this.byPerson,
    required this.byDeviceModel,
    required this.byAppVersion,
    required this.totals,
  });

  final List<GeoStatsRow> byPerson;
  final List<GeoStatsRow> byDeviceModel;
  final List<GeoStatsRow> byAppVersion;
  final GeoStatsRow totals;

  static GeoStatsReport aggregate({
    required Iterable<GeoPointingRecord> pointings,
    required Iterable<GeoAttemptRecord> attempts,
  }) {
    final persons = <String, GeoStatsRow>{};
    final devices = <String, GeoStatsRow>{};
    final versions = <String, GeoStatsRow>{};
    final totals = GeoStatsRow(key: 'total', label: 'Total');

    GeoStatsRow person(String key, String name, String role) =>
        persons.putIfAbsent(
            '$role:$key', () => GeoStatsRow(key: key, label: name, role: role));
    GeoStatsRow device(String? model) {
      final label = model ?? unknownDeviceLabel;
      return devices.putIfAbsent(
          label, () => GeoStatsRow(key: label, label: label));
    }

    GeoStatsRow version(String? appVersion) {
      final label = appVersion ?? unknownVersionLabel;
      return versions.putIfAbsent(
          label, () => GeoStatsRow(key: label, label: label));
    }

    for (final p in pointings) {
      for (final row in [
        person(p.personKey, p.personName, p.role),
        device(p.deviceModel),
        version(p.appVersion),
        totals,
      ]) {
        row.addPointing(p.method);
      }
    }
    for (final a in attempts) {
      for (final row in [
        person(a.personKey, a.personName, a.role),
        device(a.deviceModel),
        version(a.appVersion),
        totals,
      ]) {
        row.addAttempt(a.outcome);
      }
    }

    int byProblems(GeoStatsRow a, GeoStatsRow b) {
      final fallbacks = b.photoFallback.compareTo(a.photoFallback);
      if (fallbacks != 0) return fallbacks;
      final failures = b.failedAttempts.compareTo(a.failedAttempts);
      if (failures != 0) return failures;
      final total = b.totalPointings.compareTo(a.totalPointings);
      return total != 0 ? total : a.label.compareTo(b.label);
    }

    return GeoStatsReport(
      byPerson: persons.values.toList()..sort(byProblems),
      byDeviceModel: devices.values.toList()..sort(byProblems),
      byAppVersion: versions.values.toList()..sort(byProblems),
      totals: totals,
    );
  }
}

String formatRate(double? rate) {
  if (rate == null) return '—';
  if (rate == 0) return '0 %';
  return '${(rate * 100).toStringAsFixed(rate < 0.1 ? 1 : 0)} %';
}
