import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/services/department_scope.dart';
import 'package:spas_web/services/tenant_scope.dart';

import '../models/geo_stats.dart';
import '../models/mobile_event.dart';

class GeoStatsLoadResult {
  const GeoStatsLoadResult({
    required this.report,
    required this.truncatedCollections,
    required this.warnings,
  });

  final GeoStatsReport report;

  /// Collections whose query hit [GeoTrackingService.maxDocsPerCollection].
  final List<String> truncatedCollections;
  final List<String> warnings;
}

class MobileEventPage {
  const MobileEventPage({
    required this.events,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<MobileEvent> events;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

/// Read-only queries of the "Suivi géolocalisation" view. Every query is
/// bounded by a date range and a document limit.
class GeoTrackingService {
  GeoTrackingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int maxDocsPerCollection = 5000;
  static const int maxRangeDays = 62;
  static const int eventsPageSize = 50;

  Query<Map<String, dynamic>> _scoped(String collection) =>
      DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_firestore.collection(collection)),
      );

  /// [end] is exclusive.
  Future<GeoStatsLoadResult> loadStats(DateTime start, DateTime end) async {
    final truncated = <String>[];
    final warnings = <String>[];

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> read(
      String collection,
      String dateField,
    ) async {
      try {
        // Same range shape as the existing pointage/error log screens, so
        // their existing indexes are reused.
        final snapshot = await TenantScope.getQuery(
          'GeoTracking.$collection',
          _scoped(collection)
              .where(dateField, isGreaterThanOrEqualTo: start)
              .where(dateField, isLessThan: end)
              .limit(maxDocsPerCollection),
        );
        if (snapshot.docs.length >= maxDocsPerCollection) {
          truncated.add(collection);
        }
        return snapshot.docs;
      } catch (error) {
        warnings.add('$collection : $error');
        return const [];
      }
    }

    final results = await Future.wait([
      read('sitePointings', 'datetimestamp'),
      read('zonePointings', 'datetimestamp'),
      read('error_logs', 'timestamp'),
    ]);

    final pointings = <GeoPointingRecord>[
      ...results[0].map((d) =>
          GeoPointingRecord.fromDocument(d.data(), role: GeoRole.supervisor)),
      ...results[1].map((d) =>
          GeoPointingRecord.fromDocument(d.data(), role: GeoRole.zoneChief)),
    ];
    final attempts = results[2]
        .map((d) =>
            GeoAttemptRecord.fromErrorLog(ErrorLog.fromMap(d.id, d.data())))
        .whereType<GeoAttemptRecord>();

    return GeoStatsLoadResult(
      report:
          GeoStatsReport.aggregate(pointings: pointings, attempts: attempts),
      truncatedCollections: truncated,
      warnings: warnings,
    );
  }

  /// One page of `mobile_events`, newest first. `mobile_events` carry no
  /// departmentId in the contract: only the tenant scope applies.
  /// Each combination of filters needs a composite index, see
  /// docs/geo-photo-fallback.md.
  Future<MobileEventPage> loadEvents({
    required DateTime start,
    required DateTime end,
    String? userId,
    String? event,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    Query<Map<String, dynamic>> query =
        TenantScope.applyToQuery(_firestore.collection(MobileEvent.collection));
    if (userId != null) query = query.where('userId', isEqualTo: userId);
    if (event != null) query = query.where('event', isEqualTo: event);
    query = query
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .orderBy('timestamp', descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snapshot = await TenantScope.getQuery(
      'GeoTracking.mobileEvents',
      query.limit(eventsPageSize),
    );
    return MobileEventPage(
      events: snapshot.docs
          .map((doc) => MobileEvent.fromMap(doc.id, doc.data()))
          .toList(),
      lastDocument: snapshot.docs.isEmpty ? null : snapshot.docs.last,
      hasMore: snapshot.docs.length == eventsPageSize,
    );
  }
}
