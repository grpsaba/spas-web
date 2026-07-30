import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  });

  factory ErrorLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ErrorLog(
      id: doc.id,
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
    );
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

  const ErrorLogFilters({
    this.errorType,
    this.supervisorId,
    this.dateRange,
    this.isResolved,
    this.searchQuery,
    this.type,
  });

  ErrorLogFilters copyWith({
    String? errorType,
    String? supervisorId,
    DateTimeRange? dateRange,
    bool? isResolved,
    String? searchQuery,
    String? type,
    bool clearErrorType = false,
    bool clearSupervisorId = false,
    bool clearDateRange = false,
    bool clearIsResolved = false,
    bool clearSearchQuery = false,
    bool clearType = false,
  }) {
    return ErrorLogFilters(
      errorType: clearErrorType ? null : (errorType ?? this.errorType),
      supervisorId:
          clearSupervisorId ? null : (supervisorId ?? this.supervisorId),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      isResolved: clearIsResolved ? null : (isResolved ?? this.isResolved),
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      type: clearType ? null : (type ?? this.type),
    );
  }

  bool get hasActiveFilters =>
      errorType != null ||
      supervisorId != null ||
      dateRange != null ||
      isResolved != null ||
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      type != null;
}

/// Stats model for error logs
class ErrorLogStats {
  final int total;
  final int resolved;
  final int unresolved;
  final Map<String, int> byErrorType;
  final Map<String, int> byType;

  const ErrorLogStats({
    this.total = 0,
    this.resolved = 0,
    this.unresolved = 0,
    this.byErrorType = const {},
    this.byType = const {},
  });

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
