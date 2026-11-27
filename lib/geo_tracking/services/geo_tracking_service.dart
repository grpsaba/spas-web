import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/services/department_scope.dart';
import 'package:spas_web/services/tenant_scope.dart';

import '../models/geo_stats.dart';
import '../models/mobile_event.dart';
import '../models/pointing_duration.dart';
import '../models/visit_duration_estimator.dart';

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

/// Raw pointing document read for the « Durée des pointages » view.
class DurationSourceDocument {
  const DurationSourceDocument(this.id, this.data, {required this.role});

  final String id;
  final Map<String, dynamic> data;

  /// [GeoRole.supervisor] (sitePointings) or [GeoRole.zoneChief]
  /// (zonePointings).
  final String role;

  String? get visitId {
    final value = data['visitId']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  bool get hasMeasuredDuration =>
      PointingDurationRecord.hasMeasuredDuration(data);
}

class PointingDurationLoadResult {
  const PointingDurationLoadResult({
    required this.records,
    this.truncatedCollections = const [],
    this.warnings = const [],
  });

  /// Every pointing of the period: measured, `estimated` from the journal,
  /// or « non mesuré » (no duration; a pointing without `visitId` comes from
  /// an app build older than the journal, one with a `visitId` has an
  /// incomplete journal: missing `pointing_started` / `pointing_saved`,
  /// events not synced…).
  final List<PointingDurationRecord> records;
  final List<String> truncatedCollections;
  final List<String> warnings;

  /// « non mesuré » pointings.
  List<PointingDurationRecord> get unmeasured =>
      records.where((r) => !r.hasDuration).toList();

  /// Pure assembly of the documents and the journal estimates (by visitId).
  factory PointingDurationLoadResult.build(
    Iterable<DurationSourceDocument> documents, {
    Map<String, PointingDurationBreakdown> estimates = const {},
    List<String> truncatedCollections = const [],
    List<String> warnings = const [],
  }) {
    return PointingDurationLoadResult(
      records: [
        for (final doc in documents)
          PointingDurationRecord.fromDocument(
            doc.id,
            doc.data,
            role: doc.role,
            estimate: doc.hasMeasuredDuration || doc.visitId == null
                ? null
                : estimates[doc.visitId],
          ),
      ],
      truncatedCollections: truncatedCollections.toSet().toList(),
      warnings: warnings,
    );
  }
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

  /// Firestore `whereIn` accepts at most 30 values.
  static const int whereInChunk = 30;
  static const int maxEventsPerChunk = 2000;

  /// How far before a pointing the journal is searched for earlier,
  /// unsaved visits of the same site (and how long after the period for
  /// events synced late).
  static const Duration journalLookback = Duration(hours: 12);

  Query<Map<String, dynamic>> _scoped(String collection) =>
      DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_firestore.collection(collection)),
      );

  /// Documents of [collection] whose [dateField] is in [start, end), with
  /// the tenant/department scope. Same range shape as the existing
  /// pointage/error log screens, so their existing indexes are reused.
  /// A failure is added to [warnings] and gives no document.
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _readRange(
    String collection,
    String dateField,
    DateTime start,
    DateTime end, {
    required List<String> truncated,
    required List<String> warnings,
  }) async {
    try {
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

  /// [end] is exclusive.
  Future<GeoStatsLoadResult> loadStats(DateTime start, DateTime end) async {
    final truncated = <String>[];
    final warnings = <String>[];

    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> read(
      String collection,
      String dateField,
    ) =>
        _readRange(collection, dateField, start, end,
            truncated: truncated, warnings: warnings);

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

  /// Pointings of [start, end) with their duration: `pointingDuration` when
  /// the phone wrote it, otherwise an estimate from `mobile_events` (only for
  /// pointings that have a `visitId`). [end] is exclusive.
  Future<PointingDurationLoadResult> loadDurations(
      DateTime start, DateTime end) async {
    final truncated = <String>[];
    final warnings = <String>[];
    final results = await Future.wait([
      _readRange('sitePointings', 'datetimestamp', start, end,
          truncated: truncated, warnings: warnings),
      _readRange('zonePointings', 'datetimestamp', start, end,
          truncated: truncated, warnings: warnings),
    ]);
    final documents = <DurationSourceDocument>[
      ...results[0].map((d) =>
          DurationSourceDocument(d.id, d.data(), role: GeoRole.supervisor)),
      ...results[1].map((d) =>
          DurationSourceDocument(d.id, d.data(), role: GeoRole.zoneChief)),
    ];

    final targets = <String>{
      for (final doc in documents)
        if (!doc.hasMeasuredDuration && doc.visitId != null) doc.visitId!,
    };
    var estimates = const <String, PointingDurationBreakdown>{};
    if (targets.isNotEmpty) {
      try {
        estimates = await _estimateFromJournal(
          targets,
          savedVisitIds: {
            for (final doc in documents)
              if (doc.visitId != null) doc.visitId!,
          },
          start: start,
          end: end,
          truncated: truncated,
        );
      } catch (error) {
        warnings.add('${MobileEvent.collection} : $error');
      }
    }
    return PointingDurationLoadResult.build(
      documents,
      estimates: estimates,
      truncatedCollections: truncated,
      warnings: warnings,
    );
  }

  /// 1. events of the pointings' visits (visitId, equality only);
  /// 2. `pointing_started` of the same persons around the period
  ///    (userId + event + timestamp: composite index, see the doc);
  /// 3. events of the earlier visits of the same sites (visitId).
  Future<Map<String, PointingDurationBreakdown>> _estimateFromJournal(
    Set<String> targets, {
    required Set<String> savedVisitIds,
    required DateTime start,
    required DateTime end,
    required List<String> truncated,
  }) async {
    final targetEvents = await _eventsOfVisits(targets, truncated);
    final users = targetEvents.map((e) => e.userId).whereType<String>().toSet();
    final started = await _startedEventsOf(
      users,
      start.subtract(journalLookback),
      end.add(journalLookback),
      truncated,
    );
    final candidates = VisitDurationEstimator.predecessorCandidates(
        targetEvents, started,
        lookback: journalLookback);
    final candidateEvents = await _eventsOfVisits(candidates, truncated);
    return VisitDurationEstimator.estimate(
      [...targetEvents, ...candidateEvents],
      targetVisitIds: targets,
      savedVisitIds: savedVisitIds,
    );
  }

  static List<List<String>> _chunks(Iterable<String> values) {
    final list = values.toList()..sort();
    return [
      for (var i = 0; i < list.length; i += whereInChunk)
        list.sublist(i, (i + whereInChunk).clamp(0, list.length)),
    ];
  }

  /// Runs [read] on each chunk, a few at a time.
  static Future<List<MobileEvent>> _readChunks(
    List<List<String>> chunks,
    Future<List<MobileEvent>> Function(List<String> chunk) read,
  ) async {
    const parallel = 6;
    final events = <MobileEvent>[];
    for (var i = 0; i < chunks.length; i += parallel) {
      final batch = chunks.sublist(i, (i + parallel).clamp(0, chunks.length));
      for (final result in await Future.wait(batch.map(read))) {
        events.addAll(result);
      }
    }
    return events;
  }

  Future<List<MobileEvent>> _eventsOfVisits(
      Set<String> visitIds, List<String> truncated) {
    return _readChunks(_chunks(visitIds), (chunk) async {
      final snapshot = await TenantScope.getQuery(
        'GeoTracking.durationEvents',
        TenantScope.applyToQuery(
                _firestore.collection(MobileEvent.collection))
            .where('visitId', whereIn: chunk)
            .limit(maxEventsPerChunk),
      );
      if (snapshot.docs.length >= maxEventsPerChunk) {
        truncated.add(MobileEvent.collection);
      }
      return snapshot.docs
          .map((doc) => MobileEvent.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<List<MobileEvent>> _startedEventsOf(Set<String> userIds,
      DateTime from, DateTime to, List<String> truncated) {
    return _readChunks(_chunks(userIds), (chunk) async {
      final snapshot = await TenantScope.getQuery(
        'GeoTracking.durationStarts',
        TenantScope.applyToQuery(
                _firestore.collection(MobileEvent.collection))
            .where('userId', whereIn: chunk)
            .where('event', isEqualTo: DurationEvents.pointingStarted)
            .where('timestamp', isGreaterThanOrEqualTo: from)
            .where('timestamp', isLessThan: to)
            .orderBy('timestamp', descending: true)
            .limit(maxDocsPerCollection),
      );
      if (snapshot.docs.length >= maxDocsPerCollection) {
        truncated.add(MobileEvent.collection);
      }
      return snapshot.docs
          .map((doc) => MobileEvent.fromMap(doc.id, doc.data()))
          .toList();
    });
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
