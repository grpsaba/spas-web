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
///
/// The phone runs one continuous GPS search per visit (hard cap
/// [gpsSearchMaxSeconds]) and shows the photo button after
/// [photoOfferAfterSeconds] while the search goes on. The former
/// `attemptTimeoutSeconds` / `attemptsBeforePhoto` may still exist on old
/// documents and are still read by phones that are not updated yet (app
/// 1.8.0+18): the web only displays them and never writes them (see
/// [writtenFields] and `MobileConfigService.saveGeoPointing`).
class GeoPointingConfig {
  static const String firestoreField = 'geoPointing';
  static const String photoOfferAfterSecondsField = 'photoOfferAfterSeconds';
  static const String photoFallbackEnabledField = 'photoFallbackEnabled';
  static const String accuracyRuleField = 'accuracyRule';
  static const String updatedAtField = 'updatedAt';
  static const String updatedByField = 'updatedBy';

  /// Legacy fields (app builds before the continuous GPS search). Read only:
  /// never part of a web write.
  static const String attemptTimeoutSecondsField = 'attemptTimeoutSeconds';
  static const String attemptsBeforePhotoField = 'attemptsBeforePhoto';

  /// The only `geoPointing` sub-fields the web writes. Every other sub-field
  /// (the legacy ones above included) is left as it is in Firestore.
  static const List<String> writtenFields = [
    photoOfferAfterSecondsField,
    photoFallbackEnabledField,
    accuracyRuleField,
    updatedAtField,
    updatedByField,
  ];

  static const int minPhotoOfferSeconds = 15;
  static const int maxPhotoOfferSeconds = 120;
  static const int recommendedPhotoOfferSeconds = 45;
  static const int photoOfferStepSeconds = 5;

  /// Constant of the app: after this, it shows « GPS introuvable ».
  static const int gpsSearchMaxSeconds = 180;

  static const bool recommendedPhotoFallbackEnabled = true;
  static const String recommendedAccuracyRule = GeoAccuracyRule.normal;

  const GeoPointingConfig({
    required this.photoOfferAfterSeconds,
    required this.photoFallbackEnabled,
    required this.accuracyRule,
    this.legacyAttemptTimeoutSeconds,
    this.legacyAttemptsBeforePhoto,
    this.updatedAt,
    this.updatedBy,
    this.isStored = false,
  });

  const GeoPointingConfig.recommended()
      : photoOfferAfterSeconds = recommendedPhotoOfferSeconds,
        photoFallbackEnabled = recommendedPhotoFallbackEnabled,
        accuracyRule = recommendedAccuracyRule,
        legacyAttemptTimeoutSeconds = null,
        legacyAttemptsBeforePhoto = null,
        updatedAt = null,
        updatedBy = null,
        isStored = false;

  final int photoOfferAfterSeconds;
  final bool photoFallbackEnabled;
  final String accuracyRule;

  /// Legacy values found in the document (null when absent or invalid).
  final int? legacyAttemptTimeoutSeconds;
  final int? legacyAttemptsBeforePhoto;
  final DateTime? updatedAt;
  final GeoConfigAuthor? updatedBy;

  /// False when `geoPointing` is absent: the phones then use the
  /// recommended values, which is what the page shows.
  final bool isStored;

  factory GeoPointingConfig.fromJson(Object? raw) {
    if (raw is! Map) return const GeoPointingConfig.recommended();
    return GeoPointingConfig(
      photoOfferAfterSeconds: clampPhotoOffer(raw[photoOfferAfterSecondsField]),
      photoFallbackEnabled: raw[photoFallbackEnabledField] is bool
          ? raw[photoFallbackEnabledField] as bool
          : recommendedPhotoFallbackEnabled,
      accuracyRule: raw[accuracyRuleField] == null
          ? recommendedAccuracyRule
          : GeoAccuracyRule.normalize(raw[accuracyRuleField]),
      legacyAttemptTimeoutSeconds:
          readPositiveInt(raw[attemptTimeoutSecondsField]),
      legacyAttemptsBeforePhoto: readPositiveInt(raw[attemptsBeforePhotoField]),
      updatedAt: dateTimeFromJsonValue(raw[updatedAtField]),
      updatedBy: GeoConfigAuthor.fromJson(raw[updatedByField]),
      isStored: true,
    );
  }

  static int clampPhotoOffer(Object? value) => _clampInt(value,
      minPhotoOfferSeconds, maxPhotoOfferSeconds, recommendedPhotoOfferSeconds);

  static num? _parse(Object? value) {
    num? parsed;
    if (value is num) parsed = value;
    if (value is String) parsed = num.tryParse(value.trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
    return parsed;
  }

  /// Positive int or null (legacy fields are kept as they are).
  static int? readPositiveInt(Object? value) {
    final parsed = _parse(value);
    if (parsed == null || parsed.round() <= 0) return null;
    return parsed.round();
  }

  static int _clampInt(Object? value, int min, int max, int fallback) {
    final parsed = _parse(value);
    if (parsed == null) return fallback;
    final rounded = parsed.round();
    if (rounded < min) return min;
    if (rounded > max) return max;
    return rounded;
  }

  GeoPointingConfig copyWith({
    int? photoOfferAfterSeconds,
    bool? photoFallbackEnabled,
    String? accuracyRule,
  }) {
    return GeoPointingConfig(
      photoOfferAfterSeconds:
          clampPhotoOffer(photoOfferAfterSeconds ?? this.photoOfferAfterSeconds),
      photoFallbackEnabled: photoFallbackEnabled ?? this.photoFallbackEnabled,
      accuracyRule:
          GeoAccuracyRule.normalize(accuracyRule ?? this.accuracyRule),
      legacyAttemptTimeoutSeconds: legacyAttemptTimeoutSeconds,
      legacyAttemptsBeforePhoto: legacyAttemptsBeforePhoto,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
      isStored: isStored,
    );
  }

  /// Returns the recommended settings, keeping the audit and legacy fields.
  GeoPointingConfig withRecommendedValues() => copyWith(
        photoOfferAfterSeconds: recommendedPhotoOfferSeconds,
        photoFallbackEnabled: recommendedPhotoFallbackEnabled,
        accuracyRule: recommendedAccuracyRule,
      );

  bool hasSameSettingsAs(GeoPointingConfig other) =>
      photoOfferAfterSeconds == other.photoOfferAfterSeconds &&
      photoFallbackEnabled == other.photoFallbackEnabled &&
      accuracyRule == other.accuracyRule;

  bool get isRecommended =>
      hasSameSettingsAs(const GeoPointingConfig.recommended());

  bool get hasLegacySettings =>
      legacyAttemptTimeoutSeconds != null || legacyAttemptsBeforePhoto != null;

  /// The edited settings, as the mobile app reads them. The legacy values
  /// are deliberately absent: the save leaves them untouched in Firestore,
  /// so phones that still run an older build keep their behaviour.
  Map<String, dynamic> settingsToJson() => {
        photoOfferAfterSecondsField: photoOfferAfterSeconds,
        photoFallbackEnabledField: photoFallbackEnabled,
        accuracyRuleField: accuracyRule,
      };

  /// Plain-French description of what the person will live.
  String get summary {
    if (photoFallbackEnabled) {
      return 'Le bouton photo apparaît après $photoOfferAfterSeconds s de '
          'recherche GPS. Le GPS continue de chercher : s\'il trouve la '
          'position avant que la personne choisisse la photo, le pointage est '
          'enregistré par GPS. Après $gpsSearchMaxSeconds s sans position, '
          'l\'app affiche « GPS introuvable ».';
    }
    return 'Aucune photo n\'est proposée : le GPS cherche jusqu\'à '
        '$gpsSearchMaxSeconds s, puis l\'app affiche « GPS introuvable » et '
        'la personne ne peut pas pointer.';
  }

  /// « Anciennes versions de l'app : 25 s × 2 essais », or null.
  String? get legacySummary {
    if (!hasLegacySettings) return null;
    return 'Anciennes versions de l\'app : ${legacyAttemptsLabel(legacyAttemptTimeoutSeconds, legacyAttemptsBeforePhoto)}'
        ' (conservé pour les téléphones pas encore mis à jour).';
  }

  /// « 25 s × 2 essais » (missing parts are left out).
  static String legacyAttemptsLabel(int? timeoutSeconds, int? attempts) {
    final parts = [
      if (timeoutSeconds != null) '$timeoutSeconds s',
      if (attempts != null) '$attempts essai${attempts > 1 ? 's' : ''}',
    ];
    return parts.join(' × ');
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
