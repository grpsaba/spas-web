import '../model.dart' show dateTimeFromJsonValue;

/// Accuracy rule applied by the mobile app in geolocation mode.
class GeoAccuracyRule {
  static const String normal = 'normal';
  static const String strict = 'strict';

  static String normalize(Object? value) {
    final rule = value?.toString().trim().toLowerCase();
    return rule == strict ? strict : normal;
  }

  static String label(String rule) =>
      normalize(rule) == strict ? 'Stricte' : 'Normale';
}

/// Who last saved the geolocation settings (`geoPointing.updatedBy`).
class GeoConfigAuthor {
  const GeoConfigAuthor({this.uid, this.name, this.email});

  final String? uid;
  final String? name;
  final String? email;

  static GeoConfigAuthor? fromJson(Object? raw) {
    if (raw is! Map) return null;
    String? read(String key) {
      final value = raw[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    final author = GeoConfigAuthor(
        uid: read('uid'), name: read('name'), email: read('email'));
    return author.uid == null && author.name == null && author.email == null
        ? null
        : author;
  }

  Map<String, dynamic> toJson() => {
        if (uid != null) 'uid': uid,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      };

  String get displayName => name ?? email ?? uid ?? 'inconnu';
}

/// Settings of `app_config/global.geoPointing`, shared with the mobile app.
///
/// Every value read from Firestore is clamped to the bounds below, and a
/// missing document/field falls back to the recommended values: the web never
/// shows (nor saves) a value the phones would not accept.
class GeoPointingConfig {
  static const String firestoreField = 'geoPointing';
  static const String attemptTimeoutSecondsField = 'attemptTimeoutSeconds';
  static const String attemptsBeforePhotoField = 'attemptsBeforePhoto';
  static const String photoFallbackEnabledField = 'photoFallbackEnabled';
  static const String accuracyRuleField = 'accuracyRule';
  static const String updatedAtField = 'updatedAt';
  static const String updatedByField = 'updatedBy';

  static const int minTimeoutSeconds = 15;
  static const int maxTimeoutSeconds = 45;
  static const int recommendedTimeoutSeconds = 25;
  static const int timeoutStepSeconds = 5;

  static const int minAttempts = 1;
  static const int maxAttempts = 3;
  static const int recommendedAttempts = 2;

  static const bool recommendedPhotoFallbackEnabled = true;
  static const String recommendedAccuracyRule = GeoAccuracyRule.normal;

  const GeoPointingConfig({
    required this.attemptTimeoutSeconds,
    required this.attemptsBeforePhoto,
    required this.photoFallbackEnabled,
    required this.accuracyRule,
    this.updatedAt,
    this.updatedBy,
    this.isStored = false,
  });

  const GeoPointingConfig.recommended()
      : attemptTimeoutSeconds = recommendedTimeoutSeconds,
        attemptsBeforePhoto = recommendedAttempts,
        photoFallbackEnabled = recommendedPhotoFallbackEnabled,
        accuracyRule = recommendedAccuracyRule,
        updatedAt = null,
        updatedBy = null,
        isStored = false;

  final int attemptTimeoutSeconds;
  final int attemptsBeforePhoto;
  final bool photoFallbackEnabled;
  final String accuracyRule;
  final DateTime? updatedAt;
  final GeoConfigAuthor? updatedBy;

  /// False when `geoPointing` is absent: the phones then use the
  /// recommended values, which is what the page shows.
  final bool isStored;

  factory GeoPointingConfig.fromJson(Object? raw) {
    if (raw is! Map) return const GeoPointingConfig.recommended();
    return GeoPointingConfig(
      attemptTimeoutSeconds: clampTimeout(raw[attemptTimeoutSecondsField]),
      attemptsBeforePhoto: clampAttempts(raw[attemptsBeforePhotoField]),
      photoFallbackEnabled: raw[photoFallbackEnabledField] is bool
          ? raw[photoFallbackEnabledField] as bool
          : recommendedPhotoFallbackEnabled,
      accuracyRule: raw[accuracyRuleField] == null
          ? recommendedAccuracyRule
          : GeoAccuracyRule.normalize(raw[accuracyRuleField]),
      updatedAt: dateTimeFromJsonValue(raw[updatedAtField]),
      updatedBy: GeoConfigAuthor.fromJson(raw[updatedByField]),
      isStored: true,
    );
  }

  static int clampTimeout(Object? value) => _clampInt(
      value, minTimeoutSeconds, maxTimeoutSeconds, recommendedTimeoutSeconds);

  static int clampAttempts(Object? value) =>
      _clampInt(value, minAttempts, maxAttempts, recommendedAttempts);

  static int _clampInt(Object? value, int min, int max, int fallback) {
    num? parsed;
    if (value is num) parsed = value;
    if (value is String) parsed = num.tryParse(value.trim());
    if (parsed == null || parsed.isNaN) return fallback;
    final rounded = parsed.round();
    if (rounded < min) return min;
    if (rounded > max) return max;
    return rounded;
  }

  GeoPointingConfig copyWith({
    int? attemptTimeoutSeconds,
    int? attemptsBeforePhoto,
    bool? photoFallbackEnabled,
    String? accuracyRule,
  }) {
    return GeoPointingConfig(
      attemptTimeoutSeconds:
          clampTimeout(attemptTimeoutSeconds ?? this.attemptTimeoutSeconds),
      attemptsBeforePhoto:
          clampAttempts(attemptsBeforePhoto ?? this.attemptsBeforePhoto),
      photoFallbackEnabled: photoFallbackEnabled ?? this.photoFallbackEnabled,
      accuracyRule:
          GeoAccuracyRule.normalize(accuracyRule ?? this.accuracyRule),
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      isStored: isStored,
    );
  }

  /// Returns the recommended settings, keeping the audit fields.
  GeoPointingConfig withRecommendedValues() => copyWith(
        attemptTimeoutSeconds: recommendedTimeoutSeconds,
        attemptsBeforePhoto: recommendedAttempts,
        photoFallbackEnabled: recommendedPhotoFallbackEnabled,
        accuracyRule: recommendedAccuracyRule,
      );

  bool hasSameSettingsAs(GeoPointingConfig other) =>
      attemptTimeoutSeconds == other.attemptTimeoutSeconds &&
      attemptsBeforePhoto == other.attemptsBeforePhoto &&
      photoFallbackEnabled == other.photoFallbackEnabled &&
      accuracyRule == other.accuracyRule;

  bool get isRecommended =>
      hasSameSettingsAs(const GeoPointingConfig.recommended());

  int get maxTotalWaitSeconds => attemptTimeoutSeconds * attemptsBeforePhoto;

  /// The 4 settings exactly as the mobile app reads them.
  Map<String, dynamic> settingsToJson() => {
        attemptTimeoutSecondsField: attemptTimeoutSeconds,
        attemptsBeforePhotoField: attemptsBeforePhoto,
        photoFallbackEnabledField: photoFallbackEnabled,
        accuracyRuleField: accuracyRule,
      };

  /// One plain-French sentence describing what the person will live.
  String get summary {
    final attempts =
        attemptsBeforePhoto == 1 ? '1 seul essai' : '$attemptsBeforePhoto fois';
    final total =
        attemptsBeforePhoto == 1 ? '' : ' ($maxTotalWaitSeconds s au total)';
    final wait =
        'Le superviseur attend au plus $attemptTimeoutSeconds s, $attempts$total';
    if (photoFallbackEnabled) {
      return '$wait, puis peut pointer avec une photo.';
    }
    return '$wait. Si le GPS ne répond toujours pas, il ne peut pas pointer : '
        'aucune photo n\'est proposée.';
  }

  String get accuracySummary => accuracyRule == GeoAccuracyRule.strict
      ? 'Précision stricte : ancienne règle, plus d\'échecs sur les téléphones bas de gamme.'
      : 'Précision normale : une position moins précise est acceptée si elle est sans aucun doute dans le site.';

  /// "Modifié le 26/11/2026 à 14:05 par Awa Diallo", or null if never saved.
  String? get lastModifiedLabel {
    final date = updatedAt;
    if (date == null && updatedBy == null) return null;
    final buffer = StringBuffer('Modifié');
    if (date != null) {
      final local = date.toLocal();
      String two(int v) => v.toString().padLeft(2, '0');
      buffer.write(' le ${two(local.day)}/${two(local.month)}/${local.year}'
          ' à ${two(local.hour)}:${two(local.minute)}');
    }
    if (updatedBy != null) buffer.write(' par ${updatedBy!.displayName}');
    return buffer.toString();
  }
}
