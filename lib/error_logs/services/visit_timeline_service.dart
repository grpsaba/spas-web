import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:spas_web/geo_tracking/models/mobile_event.dart';
import 'package:spas_web/services/department_scope.dart';
import 'package:spas_web/services/tenant_scope.dart';

import '../models/error_log_model.dart';
import '../models/visit_timeline.dart';

/// Loads every document sharing a `visitId` (read only).
///
/// Only equality filters (visitId + the usual tenant/department scope), no
/// orderBy: Firestore serves them with single-field indexes, so no composite
/// index is needed. Sorting is done client-side.
class VisitTimelineService {
  VisitTimelineService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int _limitPerCollection = 200;

  /// `mobile_events` carry no departmentId in the contract: only the tenant
  /// scope applies to them.
  Query<Map<String, dynamic>> _byVisit(
    String collection,
    String visitId, {
    bool departmentScoped = true,
  }) {
    Query<Map<String, dynamic>> query =
        TenantScope.applyToQuery(_firestore.collection(collection));
    if (departmentScoped) {
      query = DepartmentScope.applyToDepartmentQuery(query);
    }
    return query
        .where('visitId', isEqualTo: visitId)
        .limit(_limitPerCollection);
  }

  /// A collection that cannot be read (missing rule, offline…) does not hide
  /// the others: its error is returned in [VisitTimelineResult.warnings].
  Future<VisitTimelineResult> load(
    String visitId, {
    String? currentErrorLogId,
  }) async {
    final warnings = <String>[];
    Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> read(
      String label,
      Query<Map<String, dynamic>> query,
    ) async {
      try {
        return (await TenantScope.getQuery('VisitTimeline.$label', query)).docs;
      } catch (error) {
        warnings.add('$label : $error');
        return const [];
      }
    }

    final results = await Future.wait([
      read('error_logs', _byVisit('error_logs', visitId)),
      read(
        MobileEvent.collection,
        _byVisit(MobileEvent.collection, visitId, departmentScoped: false),
      ),
      read('sitePointings', _byVisit('sitePointings', visitId)),
      read('zonePointings', _byVisit('zonePointings', visitId)),
    ]);

    final entries = VisitTimeline.build(
      errorLogs: results[0].map((d) => ErrorLog.fromMap(d.id, d.data())),
      events: results[1].map((d) => MobileEvent.fromMap(d.id, d.data())),
      pointings: [
        ...results[2].map((d) => MapEntry(d.id, d.data())),
        ...results[3].map((d) => MapEntry(d.id, d.data())),
      ],
      currentErrorLogId: currentErrorLogId,
    );
    return VisitTimelineResult(entries: entries, warnings: warnings);
  }
}

class VisitTimelineResult {
  const VisitTimelineResult({required this.entries, this.warnings = const []});

  final List<VisitTimelineEntry> entries;
  final List<String> warnings;
}
