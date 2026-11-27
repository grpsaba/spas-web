import 'package:cloud_firestore/cloud_firestore.dart';

import 'geo_pointing_config.dart';

export 'geo_pointing_config.dart';

class MobileConfigService {
  MobileConfigService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'app_config';
  static const String documentId = 'global';

  static const String backgroundTrackingEnabledField =
      'backgroundTrackingEnabled';
  static const String pointingPhotoQualityField = 'pointingPhotoQuality';
  static const String pointingPhotoMaxWidthField = 'pointingPhotoMaxWidth';
  static const String pointingPhotoMaxHeightField = 'pointingPhotoMaxHeight';
  static const String pointingPhotoUploadTimeoutSecondsField =
      'pointingPhotoUploadTimeoutSeconds';

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _documentReference =>
      _firestore.collection(collectionName).doc(documentId);

  Future<MobileConfig> getConfig() async {
    final snapshot = await _documentReference.get();

    if (!snapshot.exists) {
      return const MobileConfig.defaults();
    }

    return MobileConfig.fromJson(snapshot.data() ?? <String, dynamic>{});
  }

  Stream<MobileConfig> watchConfig() => _documentReference.snapshots().map(
        (snapshot) => MobileConfig.fromJson(snapshot.data() ?? {}),
      );

  Future<void> setBackgroundTrackingEnabled(bool enabled) =>
      _documentReference.set({
        backgroundTrackingEnabledField: enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

  Future<void> saveConfig(MobileConfig config) {
    final data = <String, dynamic>{
      pointingPhotoQualityField: config.pointingPhotoQuality,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    data[pointingPhotoMaxWidthField] =
        config.pointingPhotoMaxWidth ?? FieldValue.delete();
    data[pointingPhotoMaxHeightField] =
        config.pointingPhotoMaxHeight ?? FieldValue.delete();
    data[pointingPhotoUploadTimeoutSecondsField] =
        config.pointingPhotoUploadTimeoutSeconds ?? FieldValue.delete();

    return _documentReference.set(data, SetOptions(merge: true));
  }

  /// Writes only the `geoPointing` sub-fields of
  /// [GeoPointingConfig.writtenFields], through a field mask. Every other
  /// field of app_config/global (photo settings, menus, tracking gate...)
  /// and every other `geoPointing` sub-field are left exactly as they are:
  /// in particular the legacy `attemptTimeoutSeconds` / `attemptsBeforePhoto`
  /// still read by phones that run app 1.8.0+18.
  Future<void> saveGeoPointing(
    GeoPointingConfig config, {
    required GeoConfigAuthor author,
  }) =>
      _documentReference.set(
        geoPointingWritePayload(config, author: author),
        geoPointingWriteOptions,
      );

  /// `geoPointing.<field>` paths: Firestore replaces these values only (the
  /// `geoPointing` map itself is never replaced as a whole).
  static final SetOptions geoPointingWriteOptions = SetOptions(
    mergeFields: <Object>[
      for (final field in GeoPointingConfig.writtenFields)
        FieldPath(<String>[GeoPointingConfig.firestoreField, field]),
    ],
  );

  static Map<String, dynamic> geoPointingWritePayload(
    GeoPointingConfig config, {
    required GeoConfigAuthor author,
  }) =>
      <String, dynamic>{
        GeoPointingConfig.firestoreField: <String, dynamic>{
          ...config.copyWith().settingsToJson(),
          GeoPointingConfig.updatedAtField: FieldValue.serverTimestamp(),
          GeoPointingConfig.updatedByField: author.toJson(),
        },
      };

  Future<void> resetToDefaults() {
    return _documentReference.set(
      <String, dynamic>{
        pointingPhotoQualityField: FieldValue.delete(),
        pointingPhotoMaxWidthField: FieldValue.delete(),
        pointingPhotoMaxHeightField: FieldValue.delete(),
        pointingPhotoUploadTimeoutSecondsField: FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}

class MobileConfig {
  static const bool defaultBackgroundTrackingEnabled = true;
  static const int defaultPointingPhotoQuality = 100;

  final bool backgroundTrackingEnabled;
  final int pointingPhotoQuality;
  final double? pointingPhotoMaxWidth;
  final double? pointingPhotoMaxHeight;
  final int? pointingPhotoUploadTimeoutSeconds;
  final GeoPointingConfig geoPointing;

  const MobileConfig({
    required this.backgroundTrackingEnabled,
    required this.pointingPhotoQuality,
    this.pointingPhotoMaxWidth,
    this.pointingPhotoMaxHeight,
    this.pointingPhotoUploadTimeoutSeconds,
    this.geoPointing = const GeoPointingConfig.recommended(),
  });

  const MobileConfig.defaults()
      : backgroundTrackingEnabled = defaultBackgroundTrackingEnabled,
        pointingPhotoQuality = defaultPointingPhotoQuality,
        pointingPhotoMaxWidth = null,
        pointingPhotoMaxHeight = null,
        pointingPhotoUploadTimeoutSeconds = null,
        geoPointing = const GeoPointingConfig.recommended();

  factory MobileConfig.fromJson(Map<String, dynamic> json) {
    const defaults = MobileConfig.defaults();

    return MobileConfig(
      backgroundTrackingEnabled: _readBool(
            json[MobileConfigService.backgroundTrackingEnabledField],
          ) ??
          defaults.backgroundTrackingEnabled,
      pointingPhotoQuality: _normalizeQuality(
        _readInt(json[MobileConfigService.pointingPhotoQualityField]),
      ),
      pointingPhotoMaxWidth: _readPositiveDouble(
        json[MobileConfigService.pointingPhotoMaxWidthField],
      ),
      pointingPhotoMaxHeight: _readPositiveDouble(
        json[MobileConfigService.pointingPhotoMaxHeightField],
      ),
      pointingPhotoUploadTimeoutSeconds: _readPositiveInt(
        json[MobileConfigService.pointingPhotoUploadTimeoutSecondsField],
      ),
      geoPointing: GeoPointingConfig.fromJson(
        json[GeoPointingConfig.firestoreField],
      ),
    );
  }

  MobileConfig copyWith({
    bool? backgroundTrackingEnabled,
    int? pointingPhotoQuality,
    double? pointingPhotoMaxWidth,
    double? pointingPhotoMaxHeight,
    int? pointingPhotoUploadTimeoutSeconds,
    GeoPointingConfig? geoPointing,
  }) {
    return MobileConfig(
      backgroundTrackingEnabled:
          backgroundTrackingEnabled ?? this.backgroundTrackingEnabled,
      pointingPhotoQuality: pointingPhotoQuality ?? this.pointingPhotoQuality,
      pointingPhotoMaxWidth:
          pointingPhotoMaxWidth ?? this.pointingPhotoMaxWidth,
      pointingPhotoMaxHeight:
          pointingPhotoMaxHeight ?? this.pointingPhotoMaxHeight,
      pointingPhotoUploadTimeoutSeconds: pointingPhotoUploadTimeoutSeconds ??
          this.pointingPhotoUploadTimeoutSeconds,
      geoPointing: geoPointing ?? this.geoPointing,
    );
  }

  static bool? _readBool(dynamic value) {
    if (value is bool) return value;
    return null;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return null;
  }

  static int? _readPositiveInt(dynamic value) {
    final parsed = _readInt(value);
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static double? _readPositiveDouble(dynamic value) {
    if (value is! num || value <= 0) return null;
    return value.toDouble();
  }

  static int _normalizeQuality(int? value) {
    if (value == null || value < 1) {
      return defaultPointingPhotoQuality;
    }

    if (value > 100) {
      return 100;
    }

    return value;
  }
}
