import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Model representing a pointing error log from Firestore
/// Note: supervisor, site, agent are simplified Maps, NOT full model objects
class ErrorLog {
  final String id;
  final String type; // pointing_site | pointing_agent
  final String errorType;
  final DateTime timestamp;
  final String? customMessage;
  final String? technicalError;
  final String? stackTrace;
  
  // These are Maps, NOT typed objects!
  final Map<String, dynamic>? supervisor;
  final Map<String, dynamic>? supervisorPosition;
  final Map<String, dynamic>? site;
  final Map<String, dynamic>? sitePosition;
  final Map<String, dynamic>? agent;
  
  final bool? agentFound;
  final double? distance;
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
    this.site,
    this.sitePosition,
    this.agent,
    this.agentFound,
    this.distance,
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
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
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
      site: data['site'] != null
          ? Map<String, dynamic>.from(data['site'])
          : null,
      sitePosition: data['sitePosition'] != null
          ? Map<String, dynamic>.from(data['sitePosition'])
          : null,
      agent: data['agent'] != null
          ? Map<String, dynamic>.from(data['agent'])
          : null,
      agentFound: data['agentFound'],
      distance: data['distance']?.toDouble(),
      isOnline: data['isOnline'],
      devicePlatform: data['devicePlatform'],
      isResolved: data['isResolved'] ?? false,
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
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
      'site': site,
      'sitePosition': sitePosition,
      'agent': agent,
      'agentFound': agentFound,
      'distance': distance,
      'isOnline': isOnline,
      'devicePlatform': devicePlatform,
      'isResolved': isResolved,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
    };
  }

  // Getters for easy access to supervisor data
  String get supervisorName {
    if (supervisor == null) return 'N/A';
    final firstName = supervisor!['firstName'] ?? '';
    final lastName = supervisor!['lastName'] ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'N/A' : name;
  }

  String get supervisorCode => supervisor?['code'] ?? 'N/A';
  String get supervisorPhone => supervisor?['phone'] ?? 'N/A';
  String get supervisorEmail => supervisor?['email'] ?? 'N/A';
  String? get supervisorUID => supervisor?['UID'];

  // Getters for easy access to site data
  String get siteName => site?['name'] ?? 'N/A';
  String get siteCode => site?['codeSite'] ?? 'N/A';
  String get siteAddress => site?['adresse'] ?? 'N/A';
  String get sitePhone => site?['phone'] ?? 'N/A';
  String? get siteUID => site?['UID'];

  // Getters for easy access to agent data
  String get agentName {
    if (agent == null) return 'N/A';
    final firstName = agent!['firstName'] ?? '';
    final lastName = agent!['lastName'] ?? '';
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'N/A' : name;
  }

  String get agentCode => agent?['code'] ?? 'N/A';
  String get agentPhone => agent?['phone'] ?? 'N/A';
  String? get agentSiteName => agent?['siteName'];
  bool get agentActif => agent?['actif'] ?? false;

  // Getters for positions
  double? get supervisorLat => supervisorPosition?['lat']?.toDouble();
  double? get supervisorLng => supervisorPosition?['lng']?.toDouble();
  double? get siteLat => sitePosition?['lat']?.toDouble();
  double? get siteLng => sitePosition?['lng']?.toDouble();

  bool get hasValidSupervisorPosition =>
      supervisorLat != null && supervisorLng != null;
  bool get hasValidSitePosition => siteLat != null && siteLng != null;

  /// Get display name for the entity (site or agent)
  String get entityName {
    if (type == 'pointing_site') return siteName;
    if (type == 'pointing_agent') return agentName;
    return 'N/A';
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
      site: site,
      sitePosition: sitePosition,
      agent: agent,
      agentFound: agentFound,
      distance: distance,
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
  final String? type; // pointing_site | pointing_agent

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
