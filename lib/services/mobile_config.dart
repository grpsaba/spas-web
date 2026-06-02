import 'package:cloud_firestore/cloud_firestore.dart';

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

  Future<void> saveConfig(MobileConfig config) {
    final data = <String, dynamic>{
      backgroundTrackingEnabledField: config.backgroundTrackingEnabled,
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

  Future<void> resetToDefaults() {
    return _documentReference.set(
      <String, dynamic>{
        backgroundTrackingEnabledField: FieldValue.delete(),
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

  const MobileConfig({
    required this.backgroundTrackingEnabled,
    required this.pointingPhotoQuality,
    this.pointingPhotoMaxWidth,
    this.pointingPhotoMaxHeight,
    this.pointingPhotoUploadTimeoutSeconds,
  });

  const MobileConfig.defaults()
      : backgroundTrackingEnabled = defaultBackgroundTrackingEnabled,
        pointingPhotoQuality = defaultPointingPhotoQuality,
        pointingPhotoMaxWidth = null,
        pointingPhotoMaxHeight = null,
        pointingPhotoUploadTimeoutSeconds = null;

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
    );
  }

  MobileConfig copyWith({
    bool? backgroundTrackingEnabled,
    int? pointingPhotoQuality,
    double? pointingPhotoMaxWidth,
    double? pointingPhotoMaxHeight,
    int? pointingPhotoUploadTimeoutSeconds,
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
