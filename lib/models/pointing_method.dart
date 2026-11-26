/// How a site visit was recorded by the phone (`pointingMethod`).
enum PointingMethod { geo, photo, photoFallback }

/// GPS failure that led the phone to offer the photo
/// (`geoAttempts.fallbackReason`).
class GeoFallbackReason {
  static const String noSignal = 'no_signal';
  static const String timeout = 'timeout';
  static const String edgeUncertain = 'edge_uncertain';
  static const String frozenPosition = 'frozen_position';

  static String label(String? reason) {
    switch (reason) {
      case noSignal:
        return 'Aucun signal GPS';
      case timeout:
        return 'GPS trop lent (temps d\'attente dépassé)';
      case edgeUncertain:
        return 'Position en bordure du site, trop imprécise pour trancher';
      case frozenPosition:
        return 'Position GPS figée';
      default:
        return reason == null || reason.isEmpty
            ? 'Raison non précisée'
            : reason;
    }
  }
}

/// Display information for the pointing method of a visit, tolerant of old
/// documents written before `pointingMethod` existed.
class PointingMethodInfo {
  const PointingMethodInfo({
    required this.method,
    this.inferred = false,
    this.fallbackReason,
    this.attemptCount,
    this.totalWaitMs,
  });

  final PointingMethod method;

  /// True when the method was guessed from an old document.
  final bool inferred;
  final String? fallbackReason;
  final int? attemptCount;
  final int? totalWaitMs;

  static const String geoValue = 'geo';
  static const String photoValue = 'photo';
  static const String photoFallbackValue = 'photo_fallback';

  static PointingMethod? parse(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case geoValue:
        return PointingMethod.geo;
      case photoValue:
        return PointingMethod.photo;
      case photoFallbackValue:
        return PointingMethod.photoFallback;
      default:
        return null;
    }
  }

  static String valueOf(PointingMethod method) {
    switch (method) {
      case PointingMethod.geo:
        return geoValue;
      case PointingMethod.photo:
        return photoValue;
      case PointingMethod.photoFallback:
        return photoFallbackValue;
    }
  }

  /// Returns null when nothing allows to tell (never throws).
  static PointingMethodInfo? resolve({
    Object? pointingMethod,
    Object? geoAttempts,
    bool hasGeoMetadata = false,
    Object? photoUrl,
  }) {
    final attempts = geoAttempts is Map ? geoAttempts : null;
    final explicit = parse(pointingMethod);
    if (explicit != null) {
      final reason = attempts?['fallbackReason']?.toString();
      return PointingMethodInfo(
        method: explicit,
        fallbackReason: reason == null || reason.isEmpty ? null : reason,
        attemptCount: _int(attempts?['count']),
        totalWaitMs: _int(attempts?['totalWaitMs']),
      );
    }
    final hasPhoto = photoUrl is String && photoUrl.trim().isNotEmpty;
    if (hasPhoto) {
      return const PointingMethodInfo(
          method: PointingMethod.photo, inferred: true);
    }
    if (hasGeoMetadata) {
      return const PointingMethodInfo(
          method: PointingMethod.geo, inferred: true);
    }
    return null;
  }

  /// Reads a raw `sitePointings` / `zonePointings` document.
  static PointingMethodInfo? fromDocument(Map<String, dynamic>? json) {
    if (json == null) return null;
    return resolve(
      pointingMethod: json['pointingMethod'],
      geoAttempts: json['geoAttempts'],
      hasGeoMetadata:
          json['geoMetadata'] is Map || json['hasGeoMetadata'] == true,
      photoUrl: json['agentPhotoUrl'],
    );
  }

  static int? _int(Object? value) => value is num ? value.round() : null;

  String get value => valueOf(method);

  String get label {
    switch (method) {
      case PointingMethod.geo:
        return 'Géo';
      case PointingMethod.photo:
        return 'Photo';
      case PointingMethod.photoFallback:
        return 'Photo (GPS indisponible)';
    }
  }

  String get tooltip {
    switch (method) {
      case PointingMethod.geo:
        return inferred
            ? 'Pointé par géolocalisation (déduit d\'un ancien pointage).'
            : 'Pointé par géolocalisation.';
      case PointingMethod.photo:
        return inferred
            ? 'Pointé avec une photo (déduit d\'un ancien pointage).'
            : 'Pointé avec une photo.';
      case PointingMethod.photoFallback:
        final buffer = StringBuffer(
            'Le GPS n\'a pas permis de pointer, la photo a été utilisée.\n'
            'Raison : ${GeoFallbackReason.label(fallbackReason)}');
        final details = [
          if (attemptCount != null) 'Essais GPS : $attemptCount',
          if (totalWaitMs != null)
            'attente totale ${(totalWaitMs! / 1000).round()} s',
        ];
        if (details.isNotEmpty) buffer.write('\n${details.join(' · ')}');
        return buffer.toString();
    }
  }
}
