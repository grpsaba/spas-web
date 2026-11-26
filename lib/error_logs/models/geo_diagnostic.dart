import 'package:spas_web/services/geo_pointing_config.dart';

/// Outcome of one geolocation attempt (`attemptOutcome` in error_logs).
class AttemptOutcome {
  static const String timeout = 'timeout';
  static const String noSignal = 'no_signal';
  static const String outOfZone = 'out_of_zone';
  static const String edgeUncertain = 'edge_uncertain';
  static const String frozenPosition = 'frozen_position';
  static const String cancelled = 'cancelled';
  static const String gpsOff = 'gps_off';
  static const String permissionDenied = 'permission_denied';
  static const String mockLocation = 'mock_location';
  static const String error = 'error';

  static const List<String> all = [
    timeout,
    noSignal,
    outOfZone,
    edgeUncertain,
    frozenPosition,
    cancelled,
    gpsOff,
    permissionDenied,
    mockLocation,
    error,
  ];

  static String label(String? outcome) {
    switch (outcome) {
      case timeout:
        return 'GPS trop lent';
      case noSignal:
        return 'Aucun signal GPS';
      case outOfZone:
        return 'Hors du site';
      case edgeUncertain:
        return 'Bordure du site incertaine';
      case frozenPosition:
        return 'Position figée';
      case cancelled:
        return 'Annulé par la personne';
      case gpsOff:
        return 'GPS désactivé';
      case permissionDenied:
        return 'Localisation refusée';
      case mockLocation:
        return 'Position simulée';
      case error:
        return 'Erreur technique';
      default:
        return outcome == null || outcome.isEmpty ? 'Inconnu' : outcome;
    }
  }
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _int(Object? value) {
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

Map<String, dynamic>? asStringMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

/// Phone description from `deviceInfo` (error_logs, pointings: brand, model,
/// androidVersion, apiLevel, hardware… ; mobile_events: brand, model, os).
class DeviceInfoView {
  const DeviceInfoView({
    this.brand,
    this.model,
    this.os,
    this.hardware,
    this.platform,
  });

  final String? brand;
  final String? model;
  final String? os;
  final String? hardware;
  final String? platform;

  static DeviceInfoView? fromMap(Object? raw) {
    final map = asStringMap(raw);
    if (map == null) return null;
    final android = _text(map['androidVersion']);
    final api = _int(map['apiLevel']);
    final ios = _text(map['systemVersion']) ?? _text(map['iosVersion']);
    String? os = _text(map['os']) ?? _text(map['osVersion']);
    if (os == null && android != null) {
      os = 'Android $android${api != null ? ' (API $api)' : ''}';
    } else if (os == null && ios != null) {
      os = 'iOS $ios';
    }
    final view = DeviceInfoView(
      brand: _text(map['brand']) ?? _text(map['manufacturer']),
      model: _text(map['model']),
      os: os,
      hardware: _text(map['hardware']),
      platform: _text(map['platform']),
    );
    return view.brand == null && view.model == null && view.os == null
        ? null
        : view;
  }

  /// "Tecno KG5" — the brand is not repeated when the model already has it.
  String get modelLabel {
    final b = brand;
    final m = model;
    if (m == null) return b ?? 'Inconnu';
    if (b == null || m.toLowerCase().startsWith(b.toLowerCase())) return m;
    return '${_capitalize(b)} $m';
  }

  String get fullLabel => [modelLabel, if (os != null) os].join(' · ');

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}

/// One GPS reading from `geoDiagnostic.recentReadings`, in the new contract
/// shape ({tMs, latitude, longitude, accuracy, speed, ageMs, isMocked}) or the
/// v1.7 shape (accuracyMeters, speedMps, ageMillisAtReceipt…).
class GeoReadingView {
  const GeoReadingView({
    this.tMs,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.speed,
    this.ageMs,
    this.isMocked,
    this.quality,
  });

  final int? tMs;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final double? speed;
  final int? ageMs;
  final bool? isMocked;
  final String? quality;

  static GeoReadingView? fromMap(Object? raw) {
    final map = asStringMap(raw);
    if (map == null) return null;
    return GeoReadingView(
      tMs: _int(map['tMs'] ?? map['receivedElapsedMillis']),
      latitude: _double(map['latitude']),
      longitude: _double(map['longitude']),
      accuracy: _double(map['accuracy'] ?? map['accuracyMeters']),
      speed: _double(map['speed'] ?? map['speedMps']),
      ageMs: _int(map['ageMs'] ?? map['ageMillisAtReceipt']),
      isMocked: map['isMocked'] is bool ? map['isMocked'] as bool : null,
      quality: _text(map['qualityCode']),
    );
  }

  String get summary {
    final parts = <String>[
      if (tMs != null) 't+${(tMs! / 1000).toStringAsFixed(1)} s',
      if (accuracy != null) '± ${accuracy!.round()} m',
      if (ageMs != null) 'âge ${(ageMs! / 1000).toStringAsFixed(1)} s',
      if (speed != null) '${speed!.toStringAsFixed(1)} m/s',
      if (quality != null) quality!,
      if (isMocked == true) 'SIMULÉE',
    ];
    return parts.isEmpty ? 'Lecture sans détail' : parts.join(' · ');
  }
}

/// Readable view of the (large, evolving) `geoDiagnostic` map. Unknown keys
/// are ignored; nothing here throws on unexpected types.
class GeoDiagnosticSummary {
  const GeoDiagnosticSummary({
    required this.facts,
    required this.readings,
  });

  /// Ordered (label, value) pairs for the detail page.
  final List<MapEntry<String, String>> facts;
  final List<GeoReadingView> readings;

  static GeoDiagnosticSummary? fromMap(Object? raw) {
    final map = asStringMap(raw);
    if (map == null || map.isEmpty) return null;
    final facts = <MapEntry<String, String>>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) facts.add(MapEntry(label, value));
    }

    String? meters(Object? v) {
      final d = _double(v);
      return d == null ? null : '${d.round()} m';
    }

    add('Résultat', _text(map['result']) ?? _text(map['status']));
    final failure = _text(map['failureCode']);
    final stage = _text(map['failureStage']);
    if (failure != null) {
      add('Échec', stage == null ? failure : '$failure (étape : $stage)');
    }
    final elapsed = _double(map['elapsedSeconds']);
    final timeout = _int(map['timeoutSeconds']);
    if (elapsed != null || timeout != null) {
      add(
        'Durée',
        [
          if (elapsed != null) '${elapsed.round()} s',
          if (timeout != null) 'limite $timeout s',
        ].join(' / '),
      );
    }
    final distance = meters(map['distanceMeters']);
    final radius = meters(map['siteRadiusMeters']);
    if (distance != null || radius != null) {
      add(
        'Distance au site',
        [
          if (distance != null) distance,
          if (radius != null) 'rayon $radius',
        ].join(' / '),
      );
    }
    final accuracy = meters(map['latestAccuracyMeters']);
    final target = meters(map['targetAccuracyMeters']);
    final maxAccuracy = meters(map['maxAccuracyMeters']);
    if (accuracy != null || target != null || maxAccuracy != null) {
      add(
        'Précision',
        [
          if (accuracy != null) 'dernière $accuracy',
          if (target != null) 'visée $target',
          if (maxAccuracy != null) 'max acceptée $maxAccuracy',
        ].join(' · '),
      );
    }
    final received = _int(map['receivedCount']);
    final samples = _int(map['samplesCount']);
    if (received != null || samples != null) {
      add(
        'Positions',
        [
          if (received != null) '$received reçues',
          if (samples != null) '$samples retenues',
        ].join(' · '),
      );
    }
    final decisions = asStringMap(map['receivedDecisionCounts']);
    if (decisions != null && decisions.isNotEmpty) {
      add('Décisions',
          decisions.entries.map((e) => '${e.key}: ${e.value}').join(', '));
    }
    final measurement = asStringMap(map['measurement']);
    add('Qualité', _text(measurement?['qualityTier']));
    add('Fournisseur',
        _text(map['providerSelection']) ?? _text(map['actualProvider']));
    final background = map['backgroundTrackingActive'];
    if (background is bool) {
      add('Suivi continu', background ? 'Actif' : 'Inactif');
    }
    add('Mode', _text(map['pointageMode']));
    add('Version diagnostic', _text(map['diagnosticVersion']));

    final readingsRaw = map['recentReadings'];
    final readings = <GeoReadingView>[
      if (readingsRaw is List)
        ...readingsRaw.map(GeoReadingView.fromMap).whereType<GeoReadingView>(),
    ];
    if (facts.isEmpty && readings.isEmpty) return null;
    return GeoDiagnosticSummary(facts: facts, readings: readings);
  }

  /// One line for the list page.
  String get shortLabel {
    final wanted = {'Résultat', 'Durée', 'Précision'};
    final parts = [
      for (final fact in facts)
        if (wanted.contains(fact.key)) fact.value,
      if (readings.isNotEmpty) '${readings.length} lecture(s)',
    ];
    return parts.join(' · ');
  }
}

/// "25 s × 2 essais · photo de secours : oui · précision normale".
String? geoSettingsLabel(Object? raw) {
  final map = asStringMap(raw);
  if (map == null || map.isEmpty) return null;
  final config = GeoPointingConfig.fromJson(map);
  return '${config.attemptTimeoutSeconds} s × ${config.attemptsBeforePhoto} '
      'essai${config.attemptsBeforePhoto > 1 ? 's' : ''} · photo de secours : '
      '${config.photoFallbackEnabled ? 'oui' : 'non'} · précision '
      '${GeoAccuracyRule.label(config.accuracyRule).toLowerCase()}';
}

String formatDurationMs(int? ms) {
  if (ms == null) return '—';
  if (ms < 1000) return '$ms ms';
  return '${(ms / 1000).toStringAsFixed(ms < 10000 ? 1 : 0)} s';
}
