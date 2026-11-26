import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'geo_diagnostic.dart';

/// Model representing a pointing error log from Firestore
/// Note: supervisor, site, agent are simplified Maps, NOT full model objects
class ErrorLog {
  final String id;
  final String type; // pointing_site | pointing_agent | pointing_zone
  final String errorType;
  final DateTime timestamp;
  final String? customMessage;
  final String? technicalError;
  final String? stackTrace;

  // These are Maps, NOT typed objects!
  final Map<String, dynamic>? supervisor;
  final Map<String, dynamic>? supervisorPosition;
  final Map<String, dynamic>? zoneMember;
  final Map<String, dynamic>? zoneMemberPosition;
  final Map<String, dynamic>? site;
  final Map<String, dynamic>? sitePosition;
  final Map<String, dynamic>? agent;

  final bool? agentFound;
  final double? distance;
  final double? gpsAccuracy; // GPS accuracy in meters
  final String?
      gpsSource; // "cache" (background tracking) or "fresh" (direct request)
  final int? gpsAgeSeconds; // Age of GPS position in seconds
  final DateTime? gpsTimestamp; // Exact timestamp of GPS reading
  final bool? backgroundTrackerActive;
  final int? backgroundCacheAgeSeconds;
  final double? backgroundCacheAccuracy;
  final DateTime? backgroundCacheTimestamp;
  final bool? freshGpsAttempted;
  final String? freshGpsFailedReason;
  final bool? isOnline;
  final String? devicePlatform;
  final bool isResolved;
  final DateTime? resolvedAt;
  final String? resolvedBy;

  // Mobile app / phone (v1.7+) and geolocation attempt fields.
  final String? appVersion;
  final Map<String, dynamic>? deviceInfo;
  final Map<String, dynamic>? geoDiagnostic;
  final String? visitId;
  final int? attemptNumber;
  final String? attemptOutcome;
  final int? attemptDurationMs;
  final Map<String, dynamic>? geoSettings;
  final int? geoRuleVersion;

  ErrorLog({
    required this.id,
    required this.type,
    required this.errorType,
    required this.timestamp,
    this.customMessage,
    this.technicalError,
    this.stackTrace,
    this.supervisor,
    this.supervisorPosition,
    this.zoneMember,
    this.zoneMemberPosition,
    this.site,
    this.sitePosition,
    this.agent,
    this.agentFound,
    this.distance,
    this.gpsAccuracy,
    this.gpsSource,
    this.gpsAgeSeconds,
    this.gpsTimestamp,
    this.backgroundTrackerActive,
    this.backgroundCacheAgeSeconds,
    this.backgroundCacheAccuracy,
    this.backgroundCacheTimestamp,
    this.freshGpsAttempted,
    this.freshGpsFailedReason,
    this.isOnline,
    this.devicePlatform,
    this.isResolved = false,
    this.resolvedAt,
    this.resolvedBy,
    this.appVersion,
    this.deviceInfo,
    this.geoDiagnostic,
    this.visitId,
    this.attemptNumber,
    this.attemptOutcome,
    this.attemptDurationMs,
    this.geoSettings,
    this.geoRuleVersion,
  });

  factory ErrorLog.fromFirestore(DocumentSnapshot doc) {
    return ErrorLog.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  factory ErrorLog.fromMap(String id, Map<String, dynamic> data) {
    return ErrorLog(
      id: id,
      type: data['type'] ?? 'unknown',
      errorType: data['errorType'] ?? 'unknown',
      timestamp: _parseDateTime(data['timestamp']) ?? DateTime.now(),
      customMessage: data['customMessage'],
      technicalError: data['technicalError'],
      stackTrace: data['stackTrace'],
      // Keep as Map, don't parse to typed objects!
      supervisor: data['supervisor'] != null
          ? Map<String, dynamic>.from(data['supervisor'])
          : null,
      supervisorPosition: data['supervisorPosition'] != null
          ? Map<String, dynamic>.from(data['supervisorPosition'])
          : null,
      zoneMember: data['zoneMember'] != null
          ? Map<String, dynamic>.from(data['zoneMember'])
          : null,
      zoneMemberPosition: data['zoneMemberPosition'] != null
          ? Map<String, dynamic>.from(data['zoneMemberPosition'])
          : null,
      site:
          data['site'] != null ? Map<String, dynamic>.from(data['site']) : null,
      sitePosition: data['sitePosition'] != null
          ? Map<String, dynamic>.from(data['sitePosition'])
          : null,
      agent: data['agent'] != null
          ? Map<String, dynamic>.from(data['agent'])
          : null,
      agentFound: data['agentFound'] as bool?,
      distance: _parseDouble(data['distance']),
      gpsAccuracy: _parseDouble(data['gpsAccuracy']),
      gpsSource: data['gpsSource'] as String?,
      gpsAgeSeconds: _parseInt(data['gpsAgeSeconds']),
      gpsTimestamp: _parseDateTime(data['gpsTimestamp']),
      backgroundTrackerActive: data['backgroundTrackerActive'] as bool?,
      backgroundCacheAgeSeconds: _parseInt(data['backgroundCacheAgeSeconds']),
      backgroundCacheAccuracy: _parseDouble(data['backgroundCacheAccuracy']),
      backgroundCacheTimestamp:
          _parseDateTime(data['backgroundCacheTimestamp']),
      freshGpsAttempted: data['freshGpsAttempted'] as bool?,
      freshGpsFailedReason: data['freshGpsFailedReason'] as String?,
      isOnline: data['isOnline'] as bool?,
      devicePlatform: data['devicePlatform'] as String?,
      isResolved: data['isResolved'] ?? false,
      resolvedAt: _parseDateTime(data['resolvedAt']),
      resolvedBy: data['resolvedBy'],
      appVersion: _parseText(data['appVersion']),
      deviceInfo: asStringMap(data['deviceInfo']),
      geoDiagnostic: asStringMap(data['geoDiagnostic']),
      visitId: _parseText(data['visitId']),
      attemptNumber: _parseInt(data['attemptNumber']),
      attemptOutcome: _parseText(data['attemptOutcome']),
      attemptDurationMs: _parseInt(data['attemptDurationMs']),
      geoSettings: asStringMap(data['geoSettings']),
      geoRuleVersion: _parseInt(data['geoRuleVersion']),
    );
  }

  static String? _parseText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'errorType': errorType,
      'timestamp': Timestamp.fromDate(timestamp),
      'customMessage': customMessage,
      'technicalError': technicalError,
      'stackTrace': stackTrace,
      'supervisor': supervisor,
      'supervisorPosition': supervisorPosition,
      'zoneMember': zoneMember,
      'zoneMemberPosition': zoneMemberPosition,
      'site': site,
      'sitePosition': sitePosition,
      'agent': agent,
      'agentFound': agentFound,
      'distance': distance,
      'gpsAccuracy': gpsAccuracy,
      'gpsSource': gpsSource,
      'gpsAgeSeconds': gpsAgeSeconds,
      'gpsTimestamp':
          gpsTimestamp != null ? Timestamp.fromDate(gpsTimestamp!) : null,
      'backgroundTrackerActive': backgroundTrackerActive,
      'backgroundCacheAgeSeconds': backgroundCacheAgeSeconds,
      'backgroundCacheAccuracy': backgroundCacheAccuracy,
      'backgroundCacheTimestamp': backgroundCacheTimestamp != null
          ? Timestamp.fromDate(backgroundCacheTimestamp!)
          : null,
      'freshGpsAttempted': freshGpsAttempted,
      'freshGpsFailedReason': freshGpsFailedReason,
      'isOnline': isOnline,
      'devicePlatform': devicePlatform,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'appVersion': appVersion,
      'deviceInfo': deviceInfo,
      'geoDiagnostic': geoDiagnostic,
      'visitId': visitId,
      'attemptNumber': attemptNumber,
      'attemptOutcome': attemptOutcome,
      'attemptDurationMs': attemptDurationMs,
      'geoSettings': geoSettings,
      'geoRuleVersion': geoRuleVersion,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static String _mapString(Map<String, dynamic>? data, String key) {
    final value = data?[key];
    if (value == null) return 'N/A';
    final text = value.toString().trim();
    return text.isEmpty ? 'N/A' : text;
  }

  static String _mapFullName(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    final firstName = data['firstName']?.toString().trim() ?? '';
    final lastName = data['lastName']?.toString().trim() ?? '';
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    return _mapString(data, 'name');
  }

  DeviceInfoView? get device => DeviceInfoView.fromMap(deviceInfo);

  /// Raw `deviceInfo.model`, the value used by the phone model filter.
  String? get deviceModel => _parseText(deviceInfo?['model']);

  GeoDiagnosticSummary? get geoDiagnosticSummary =>
      GeoDiagnosticSummary.fromMap(geoDiagnostic);

  bool get hasAttemptInfo =>
      attemptNumber != null ||
      attemptOutcome != null ||
      attemptDurationMs != null;

  /// "Essai 2 · GPS trop lent · 25 s", or null for older logs.
  String? get attemptLabel {
    if (!hasAttemptInfo) return null;
    return [
      if (attemptNumber != null) 'Essai $attemptNumber',
      if (attemptOutcome != null) AttemptOutcome.label(attemptOutcome),
      if (attemptDurationMs != null) formatDurationMs(attemptDurationMs),
    ].join(' · ');
  }

  /// "v1.7.0+16 · Tecno KG5" for the list rows.
  String? get appAndDeviceLabel {
    final parts = [
      if (appVersion != null) 'v$appVersion',
      if (device != null) device!.modelLabel,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  bool get isSitePointing => type == 'pointing_site';
  bool get isAgentPointing => type == 'pointing_agent';
  bool get isZonePointing => type == 'pointing_zone';

  Map<String, dynamic>? get actor => isZonePointing ? zoneMember : supervisor;
  Map<String, dynamic>? get actorPosition =>
      isZonePointing ? zoneMemberPosition : supervisorPosition;

  String get actorRoleLabel => isZonePointing ? 'Chef de zone' : 'Superviseur';
  String get actorPositionLabel =>
      'position du ${actorRoleLabel.toLowerCase()}';
  String get actorName => _mapFullName(actor);
  String get actorCode => _mapString(actor, 'code');
  String get actorPhone => _mapString(actor, 'phone');
  String get actorEmail => _mapString(actor, 'email');
  String? get actorUID => actor?['UID']?.toString();

  Map<String, dynamic>? get zoneMemberZone {
    final zone = zoneMember?['zone'];
    if (zone is Map<String, dynamic>) return zone;
    if (zone is Map) return Map<String, dynamic>.from(zone);
    return null;
  }

  String get zoneName => _mapString(zoneMemberZone, 'name');
  String get zoneCode => _mapString(zoneMemberZone, 'codeZone');
  String get zoneMemberPoste => _mapString(zoneMember, 'poste');
  String get zoneDisplayName {
    if (zoneName == 'N/A') return 'N/A';
    if (zoneCode == 'N/A') return zoneName;
    return '$zoneName ($zoneCode)';
  }

  // Getters for easy access to supervisor data
  String get supervisorName {
    return _mapFullName(supervisor);
  }

  String get supervisorCode => _mapString(supervisor, 'code');
  String get supervisorPhone => _mapString(supervisor, 'phone');
  String get supervisorEmail => _mapString(supervisor, 'email');
  String? get supervisorUID => supervisor?['UID']?.toString();

  // Getters for easy access to site data
  String get siteName => site?['name'] ?? 'N/A';
  String get siteCode => site?['codeSite'] ?? 'N/A';
  String get siteAddress => site?['adresse'] ?? 'N/A';
  String get sitePhone => site?['phone'] ?? 'N/A';
  String? get siteUID => site?['UID'];

  // Getters for easy access to agent data
  String get agentName {
    return _mapFullName(agent);
  }

  String get agentCode => _mapString(agent, 'code');
  String get agentPhone => _mapString(agent, 'phone');
  String? get agentSiteName => agent?['siteName']?.toString();
  bool get agentActif => agent?['actif'] ?? false;

  // Getters for positions
  double? get supervisorLat => _parseDouble(supervisorPosition?['lat']);
  double? get supervisorLng => _parseDouble(supervisorPosition?['lng']);
  double? get zoneMemberLat => _parseDouble(zoneMemberPosition?['lat']);
  double? get zoneMemberLng => _parseDouble(zoneMemberPosition?['lng']);
  double? get actorLat => _parseDouble(actorPosition?['lat']);
  double? get actorLng => _parseDouble(actorPosition?['lng']);
  double? get siteLat => _parseDouble(sitePosition?['lat']);
  double? get siteLng => _parseDouble(sitePosition?['lng']);

  bool get hasValidSupervisorPosition =>
      supervisorLat != null && supervisorLng != null;
  bool get hasValidZoneMemberPosition =>
      zoneMemberLat != null && zoneMemberLng != null;
  bool get hasValidActorPosition => actorLat != null && actorLng != null;
  bool get hasValidSitePosition => siteLat != null && siteLng != null;

  /// Get display name for the entity (site or agent)
  String get entityName {
    if (isSitePointing || isZonePointing) return siteName;
    if (isAgentPointing) return agentName;
    return 'N/A';
  }

  String get entityTypeLabel => isAgentPointing ? 'Agent' : 'Site';

  String get referenceSiteLabel =>
      isAgentPointing ? 'Site de reference' : 'Site';

  String get pointageTypeLabel {
    switch (type) {
      case 'pointing_site':
        return 'Pointage Site';
      case 'pointing_agent':
        return 'Pointage Agent';
      case 'pointing_zone':
        return 'Pointage Chef de zone';
      default:
        return type;
    }
  }

  IconData get pointageTypeIcon {
    switch (type) {
      case 'pointing_agent':
        return Icons.person;
      case 'pointing_zone':
        return Icons.map;
      case 'pointing_site':
        return Icons.location_on;
      default:
        return Icons.help_outline;
    }
  }

  /// Get severity level (1-5, 5 being most severe)
  int get severity {
    switch (errorType) {
      case 'unauthorized':
      case 'agentInactive':
        return 5;
      case 'firebaseError':
      case 'technicalError':
        return 4;
      case 'distanceError':
        return 3;
      case 'validationError':
      case 'geolocationError':
      case 'gpsTimeoutError':
        return 2;
      case 'siteNotFound':
      case 'agentNotFound':
      case 'geoAttemptCancelled':
      case 'sitePositionReported':
        return 1;
      default:
        return 1;
    }
  }

  /// Create a copy with updated resolution status
  ErrorLog copyWithResolved({
    required String resolvedBy,
    required DateTime resolvedAt,
  }) {
    return ErrorLog(
      id: id,
      type: type,
      errorType: errorType,
      timestamp: timestamp,
      customMessage: customMessage,
      technicalError: technicalError,
      stackTrace: stackTrace,
      supervisor: supervisor,
      supervisorPosition: supervisorPosition,
      zoneMember: zoneMember,
      zoneMemberPosition: zoneMemberPosition,
      site: site,
      sitePosition: sitePosition,
      agent: agent,
      agentFound: agentFound,
      distance: distance,
      gpsAccuracy: gpsAccuracy,
      gpsSource: gpsSource,
      gpsAgeSeconds: gpsAgeSeconds,
      gpsTimestamp: gpsTimestamp,
      backgroundTrackerActive: backgroundTrackerActive,
      backgroundCacheAgeSeconds: backgroundCacheAgeSeconds,
      backgroundCacheAccuracy: backgroundCacheAccuracy,
      backgroundCacheTimestamp: backgroundCacheTimestamp,
      freshGpsAttempted: freshGpsAttempted,
      freshGpsFailedReason: freshGpsFailedReason,
      isOnline: isOnline,
      devicePlatform: devicePlatform,
      isResolved: true,
      resolvedAt: resolvedAt,
      resolvedBy: resolvedBy,
      appVersion: appVersion,
      deviceInfo: deviceInfo,
      geoDiagnostic: geoDiagnostic,
      visitId: visitId,
      attemptNumber: attemptNumber,
      attemptOutcome: attemptOutcome,
      attemptDurationMs: attemptDurationMs,
      geoSettings: geoSettings,
      geoRuleVersion: geoRuleVersion,
    );
  }
}

/// Error type labels and colors
class ErrorTypeConfig {
  static String getLabel(String errorType) {
    switch (errorType) {
      case 'distanceError':
        return 'Erreur distance';
      case 'siteNotFound':
        return 'Site non trouvé';
      case 'agentNotFound':
        return 'Agent non trouvé';
      case 'unauthorized':
        return 'Non autorisé';
      case 'agentInactive':
        return 'Agent inactif';
      case 'validationError':
        return 'Erreur validation';
      case 'geolocationError':
        return 'Erreur GPS';
      case 'gpsTimeoutError':
        return 'Timeout GPS';
      case 'firebaseError':
        return 'Erreur serveur';
      case 'technicalError':
        return 'Erreur technique';
      case 'geoAttemptCancelled':
        return 'Essai GPS annulé';
      case 'sitePositionReported':
        return 'Position de site signalée';
      default:
        return errorType;
    }
  }

  static Color getColor(String errorType) {
    switch (errorType) {
      case 'distanceError':
        return const Color(0xFFFF9800); // Orange
      case 'unauthorized':
      case 'agentInactive':
        return const Color(0xFFF44336); // Red
      case 'validationError':
        return const Color(0xFFFFC107); // Amber
      case 'firebaseError':
      case 'technicalError':
        return const Color(0xFF9C27B0); // Purple
      case 'geolocationError':
        return const Color(0xFF2196F3); // Blue
      case 'gpsTimeoutError':
        return const Color(0xFFFF5722); // Deep Orange
      case 'siteNotFound':
      case 'agentNotFound':
        return const Color(0xFF607D8B); // Blue Grey
      case 'geoAttemptCancelled':
        return const Color(0xFF795548); // Brown
      case 'sitePositionReported':
        return const Color(0xFF009688); // Teal
      default:
        return const Color(0xFF9E9E9E); // Grey
    }
  }

  static IconData getIcon(String errorType) {
    switch (errorType) {
      case 'distanceError':
        return Icons.social_distance;
      case 'siteNotFound':
        return Icons.location_off;
      case 'agentNotFound':
        return Icons.person_off;
      case 'unauthorized':
        return Icons.block;
      case 'agentInactive':
        return Icons.person_remove;
      case 'validationError':
        return Icons.warning_amber;
      case 'geolocationError':
        return Icons.gps_off;
      case 'gpsTimeoutError':
        return Icons.timer_off;
      case 'firebaseError':
        return Icons.cloud_off;
      case 'technicalError':
        return Icons.error_outline;
      case 'geoAttemptCancelled':
        return Icons.cancel_schedule_send;
      case 'sitePositionReported':
        return Icons.wrong_location;
      default:
        return Icons.help_outline;
    }
  }

  static const List<String> allErrorTypes = [
    'distanceError',
    'siteNotFound',
    'agentNotFound',
    'unauthorized',
    'agentInactive',
    'validationError',
    'geolocationError',
    'gpsTimeoutError',
    'firebaseError',
    'technicalError',
    'geoAttemptCancelled',
    'sitePositionReported',
  ];
}

/// Filter model for error logs
class ErrorLogFilters {
  final String? errorType;
  final String? supervisorId;
  final DateTimeRange? dateRange;
  final bool? isResolved;
  final String? searchQuery;
  final String? type; // pointing_site | pointing_agent | pointing_zone
  final String? attemptOutcome;
  final String? appVersion;
  final String? deviceModel; // raw deviceInfo.model

  const ErrorLogFilters({
    this.errorType,
    this.supervisorId,
    this.dateRange,
    this.isResolved,
    this.searchQuery,
    this.type,
    this.attemptOutcome,
    this.appVersion,
    this.deviceModel,
  });

  ErrorLogFilters copyWith({
    String? errorType,
    String? supervisorId,
    DateTimeRange? dateRange,
    bool? isResolved,
    String? searchQuery,
    String? type,
    String? attemptOutcome,
    String? appVersion,
    String? deviceModel,
    bool clearErrorType = false,
    bool clearSupervisorId = false,
    bool clearDateRange = false,
    bool clearIsResolved = false,
    bool clearSearchQuery = false,
    bool clearType = false,
    bool clearAttemptOutcome = false,
    bool clearAppVersion = false,
    bool clearDeviceModel = false,
  }) {
    return ErrorLogFilters(
      errorType: clearErrorType ? null : (errorType ?? this.errorType),
      supervisorId:
          clearSupervisorId ? null : (supervisorId ?? this.supervisorId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      isResolved: clearIsResolved ? null : (isResolved ?? this.isResolved),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      type: clearType ? null : (type ?? this.type),
      attemptOutcome:
          clearAttemptOutcome ? null : (attemptOutcome ?? this.attemptOutcome),
      appVersion: clearAppVersion ? null : (appVersion ?? this.appVersion),
      deviceModel: clearDeviceModel ? null : (deviceModel ?? this.deviceModel),
    );
  }

  bool get hasActiveFilters =>
      errorType != null ||
      supervisorId != null ||
      dateRange != null ||
      isResolved != null ||
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      type != null ||
      attemptOutcome != null ||
      appVersion != null ||
      deviceModel != null;
}

/// Stats model for error logs
class ErrorLogStats {
  final int total;
  final int resolved;
  final int unresolved;
  final Map<String, int> byErrorType;
  final Map<String, int> byType;

  /// Counts over the recent logs, used to offer the new filter values.
  final Map<String, int> byAttemptOutcome;
  final Map<String, int> byAppVersion;
  final Map<String, int> byDeviceModel; // raw deviceInfo.model

  const ErrorLogStats({
    this.total = 0,
    this.resolved = 0,
    this.unresolved = 0,
    this.byErrorType = const {},
    this.byType = const {},
    this.byAttemptOutcome = const {},
    this.byAppVersion = const {},
    this.byDeviceModel = const {},
  });

  /// Counts by error type, outcome, app version and phone model.
  static Map<String, Map<String, int>> countRecent(
      Iterable<Map<String, dynamic>> docs) {
    final result = <String, Map<String, int>>{
      'errorType': {},
      'type': {},
      'attemptOutcome': {},
      'appVersion': {},
      'deviceModel': {},
    };
    void inc(String bucket, Object? key) {
      final text = key?.toString().trim();
      if (text == null || text.isEmpty) return;
      result[bucket]![text] = (result[bucket]![text] ?? 0) + 1;
    }

    for (final data in docs) {
      inc('errorType', data['errorType'] ?? 'unknown');
      inc('type', data['type'] ?? 'unknown');
      inc('attemptOutcome', data['attemptOutcome']);
      inc('appVersion', data['appVersion']);
      final device = data['deviceInfo'];
      inc('deviceModel', device is Map ? device['model'] : null);
    }
    return result;
  }

  factory ErrorLogStats.fromLogs(List<ErrorLog> logs) {
    final byErrorType = <String, int>{};
    final byType = <String, int>{};
    int resolved = 0;
    int unresolved = 0;

    for (final log in logs) {
      byErrorType[log.errorType] = (byErrorType[log.errorType] ?? 0) + 1;
      byType[log.type] = (byType[log.type] ?? 0) + 1;
      if (log.isResolved) {
        resolved++;
      } else {
        unresolved++;
      }
    }

    return ErrorLogStats(
      total: logs.length,
      resolved: resolved,
      unresolved: unresolved,
      byErrorType: byErrorType,
      byType: byType,
    );
  }
}
