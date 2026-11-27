import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/geo_tracking/models/geo_stats.dart';
import 'package:spas_web/geo_tracking/models/pointing_duration.dart';
import 'package:spas_web/geo_tracking/services/geo_tracking_service.dart';
import 'package:spas_web/models/pointing_method.dart';

import 'duration_fixtures.dart';

PointingDurationRecord _record(
  String id,
  int totalMs, {
  String person = 'sup-1',
  String role = GeoRole.supervisor,
  String site = 'site-1',
  String method = 'geo',
  int gpsWaitMs = 0,
  int relaunches = 0,
  DateTime? at,
}) =>
    PointingDurationRecord.fromDocument(
      id,
      durationPointing(
        personUid: person,
        personName: 'Personne $person',
        siteUid: site,
        siteCode: site.toUpperCase(),
        siteName: 'Site $site',
        at: at ?? DateTime(2026, 11, 26, 9),
        zone: role == GeoRole.zoneChief,
        method: method,
        duration:
            durationMap(totalMs, gpsWaitMs: gpsWaitMs, relaunches: relaunches),
      ),
      role: role,
    );

void main() {
  group('formatDuration', () {
    test('French minutes and seconds', () {
      expect(formatDuration(83000), '1 min 23 s');
      expect(formatDuration(65000), '1 min 05 s');
      expect(formatDuration(45000), '45 s');
      expect(formatDuration(59600), '1 min 00 s');
      expect(formatDuration(4200), '4,2 s');
      expect(formatDuration(1990), '2 s');
      expect(formatDuration(9949), '9,9 s');
      expect(formatDuration(40), '0 s');
      expect(formatDuration(1000), '1 s');
      expect(formatDuration(0), '0 s');
      expect(formatDuration(3723000), '1 h 02 min');
      expect(formatDuration(null), '—');
      expect(formatDuration(-5), '—');
      expect(formatDuration(67000.4), '1 min 07 s');
    });

    test('shares', () {
      expect(formatShare(null), '—');
      expect(formatShare(0), '0 %');
      expect(formatShare(0.25), '25 %');
      expect(formatShare(0.045), '4,5 %');
    });
  });

  group('DurationSummary', () {
    test('median, average, p90, max and share over 2 min', () {
      // 10 values (s): 20 30 40 50 60 70 80 90 150 600
      final summary = DurationSummary.of(
          [60, 20, 600, 30, 40, 150, 50, 70, 80, 90].map((s) => s * 1000));
      expect(summary.count, 10);
      expect(summary.medianMs, 65000); // (60 + 70) / 2
      expect(summary.meanMs, 119000); // 1190 s / 10
      // p90 by linear interpolation: rank 8.1 → 150 + 0.1 × 450 = 195 s.
      expect(summary.p90Ms, closeTo(195000, 1e-6));
      expect(summary.maxMs, 600000);
      expect(summary.overTwoMinutesShare, 0.2); // 150 s and 600 s
    });

    test('odd count, single value, exactly 2 min, empty', () {
      final odd = DurationSummary.of([30000, 10000, 20000]);
      expect(odd.medianMs, 20000);
      expect(odd.p90Ms, closeTo(28000, 1e-6));
      final single = DurationSummary.of([120000]);
      expect(single.medianMs, 120000);
      expect(single.p90Ms, 120000);
      // "over 2 min" is strict.
      expect(single.overTwoMinutesShare, 0);
      final empty = DurationSummary.of(const []);
      expect(empty.count, 0);
      expect(empty.medianMs, isNull);
      expect(empty.overTwoMinutesShare, isNull);
    });

    test('percentile helper', () {
      expect(percentile([10], 0.9), 10);
      expect(percentile([10, 20], 0.5), 15);
      expect(percentile([10, 20, 30, 40, 50], 0.9), 46);
    });
  });

  group('records', () {
    test('read pointingDuration from the pointing document', () {
      final record = PointingDurationRecord.fromDocument(
        'p1',
        durationPointing(
          personUid: 'zc-1',
          personName: 'Chef Test',
          siteUid: 'site-9',
          siteCode: 'S-9',
          siteName: 'Site neuf',
          at: DateTime(2026, 11, 26, 10, 30),
          zone: true,
          method: 'photo_fallback',
          visitId: 'v1',
          duration: {
            'version': 1,
            'totalMs': 83000,
            'gpsWaitMs': 45000,
            'firstFixMs': null,
            'decisionMs': 4000,
            'photoMs': 9000,
            'saveMs': 1500,
            'relaunches': 1,
            'startedAt': '2026-11-26T10:28:37.000Z',
          },
        ),
        role: GeoRole.zoneChief,
      );
      expect(record.personKey, 'zc-1');
      expect(record.personName, 'Chef Test');
      expect(record.role, GeoRole.zoneChief);
      expect(record.siteKey, 'site-9');
      expect(record.siteLabel, 'S-9 · Site neuf');
      expect(record.method, PointingMethod.photoFallback);
      expect(record.totalMs, 83000);
      expect(record.duration!.firstFixMs, isNull);
      expect(record.duration!.relaunches, 1);
      expect(record.duration!.startedAt, DateTime.utc(2026, 11, 26, 10, 28, 37));
      expect(record.estimated, isFalse);
      expect(record.sourceLabel, 'mesuré');
      expect(record.duration!.summary,
          'Attente GPS 45 s · Décision 4 s · Photo 9 s · Enregistrement 1,5 s · 1 relance');
    });

    test('estimate only when the document has no duration', () {
      const estimate = PointingDurationBreakdown(totalMs: 70000, gpsWaitMs: 50000);
      final data = durationPointing(
          personUid: 'a',
          personName: 'A B',
          siteUid: 's',
          at: DateTime(2026, 11, 26),
          visitId: 'v');
      final estimated = PointingDurationRecord.fromDocument('p', data,
          role: GeoRole.supervisor, estimate: estimate);
      expect(estimated.estimated, isTrue);
      expect(estimated.hasDuration, isTrue);
      expect(estimated.totalMs, 70000);
      expect(estimated.sourceLabel, 'estimé (journal)');
      // Invalid maps are ignored.
      expect(PointingDurationBreakdown.fromMap({'totalMs': 'abc'}), isNull);
      expect(PointingDurationBreakdown.fromMap({'totalMs': -4}), isNull);
      expect(PointingDurationBreakdown.fromMap('x'), isNull);
      // pointing_saved data uses durationMs.
      expect(PointingDurationBreakdown.fromMap({'durationMs': 65000})!.totalMs,
          65000);
    });

    test('without duration nor estimate: « non mesuré », never 0', () {
      final data = durationPointing(
          personUid: 'a',
          personName: 'A B',
          siteUid: 's',
          at: DateTime(2026, 11, 26),
          visitId: 'v');
      final unmeasured = PointingDurationRecord.fromDocument('p', data,
          role: GeoRole.supervisor);
      expect(unmeasured.hasDuration, isFalse);
      expect(unmeasured.duration, isNull);
      expect(unmeasured.totalMs, isNull);
      expect(unmeasured.estimated, isFalse);
      expect(unmeasured.sourceLabel, 'non mesuré');
      // Still identified: it is listed, with its person, site and method.
      expect(unmeasured.personName, 'A B');
      expect(unmeasured.method, PointingMethod.geo);

      // A total of 0 is not a measure: « non mesuré », and the estimate
      // (when there is one) is used instead.
      expect(PointingDurationBreakdown.fromMap({'totalMs': 0}), isNull);
      expect(PointingDurationBreakdown.fromMap({'totalMs': 0.4}), isNull);
      expect(PointingDurationBreakdown.fromMap({'durationMs': 0}), isNull);
      final zero = {...data, 'pointingDuration': durationMap(0)};
      expect(PointingDurationRecord.hasMeasuredDuration(zero), isFalse);
      final zeroRecord = PointingDurationRecord.fromDocument('z', zero,
          role: GeoRole.supervisor);
      expect(zeroRecord.hasDuration, isFalse);
      expect(zeroRecord.sourceLabel, 'non mesuré');
      final zeroEstimated = PointingDurationRecord.fromDocument('z', zero,
          role: GeoRole.supervisor,
          estimate: const PointingDurationBreakdown(totalMs: 42000));
      expect(zeroEstimated.totalMs, 42000);
      expect(zeroEstimated.estimated, isTrue);
    });

    test('load result: measured, estimated and unmeasured pointings', () {
      DurationSourceDocument doc(String id,
              {Map<String, dynamic>? duration,
              String? visitId,
              bool zone = false,
              String method = 'geo'}) =>
          DurationSourceDocument(
            id,
            durationPointing(
              personUid: 'p',
              personName: 'P Q',
              siteUid: 's',
              at: DateTime(2026, 11, 26),
              duration: duration,
              visitId: visitId,
              zone: zone,
              method: method,
            ),
            role: zone ? GeoRole.zoneChief : GeoRole.supervisor,
          );
      final result = PointingDurationLoadResult.build([
        doc('measured', duration: durationMap(60000), visitId: 'v0'),
        doc('estimated', visitId: 'v1'),
        doc('incomplete', visitId: 'v2', zone: true),
        doc('old', method: 'photo'),
      ], estimates: {
        'v1': const PointingDurationBreakdown(totalMs: 90000),
        // Ignored: the document already has its measured duration.
        'v0': const PointingDurationBreakdown(totalMs: 1),
      }, truncatedCollections: ['mobile_events', 'mobile_events']);
      // Every pointing is kept, « non mesuré » ones included.
      expect(result.records.map((r) => r.id),
          ['measured', 'estimated', 'incomplete', 'old']);
      expect(result.records.first.totalMs, 60000);
      expect(result.records.first.estimated, isFalse);
      expect(result.records[1].estimated, isTrue);
      expect(result.records[1].totalMs, 90000);
      expect(result.records.map((r) => r.sourceLabel),
          ['mesuré', 'estimé (journal)', 'non mesuré', 'non mesuré']);
      expect(result.unmeasured.map((r) => r.id), ['incomplete', 'old']);
      expect(result.unmeasured.where((r) => r.visitId != null), hasLength(1));
      expect(result.truncatedCollections, ['mobile_events']);

      List<String> unmeasured(DurationFilter filter) =>
          PointingDurationReport.aggregate(result.records, filter: filter)
              .unmeasured
              .map((r) => r.id)
              .toList();
      expect(unmeasured(const DurationFilter()), hasLength(2));
      expect(unmeasured(const DurationFilter(role: GeoRole.supervisor)),
          ['old']);
      expect(unmeasured(const DurationFilter(role: GeoRole.zoneChief)),
          ['incomplete']);
      expect(unmeasured(const DurationFilter(method: PointingMethod.photo)),
          ['old']);
    });
  });

  group('report', () {
    final records = [
      _record('1', 40000, person: 'sup-1', site: 'a', gpsWaitMs: 30000),
      _record('2', 80000,
          person: 'sup-1',
          site: 'b',
          method: 'photo_fallback',
          gpsWaitMs: 50000,
          relaunches: 1),
      _record('3', 200000,
          person: 'sup-1', site: 'b', gpsWaitMs: 150000, at: DateTime(2026, 11, 25, 8)),
      _record('4', 30000, person: 'sup-1', site: 'a', method: 'photo'),
      _record('5', 60000,
          person: 'zc-1',
          role: GeoRole.zoneChief,
          site: 'a',
          gpsWaitMs: 40000,
          at: DateTime(2026, 11, 25, 9)),
    ];

    test('per person, site, day and method', () {
      final report = PointingDurationReport.aggregate(records);
      expect(report.summary.count, 5);
      expect(report.summary.medianMs, 60000);
      expect(report.summary.meanMs, 82000);
      expect(report.summary.overTwoMinutesShare, 0.2);
      // GPS wait: geolocation-mode pointings only (photo excluded).
      expect(report.averageGpsWaitMs, (30000 + 50000 + 150000 + 40000) / 4);

      final sup = report.byPerson.firstWhere((g) => g.key == 'supervisor:sup-1');
      expect(sup.count, 4);
      expect(sup.label, 'Personne sup-1');
      expect(sup.summary.medianMs, 60000); // 30 40 80 200
      expect(sup.relaunches, 1);
      expect(sup.photoFallbackRate, closeTo(1 / 3, 1e-9));
      expect(sup.averageGpsWaitMs, closeTo(230000 / 3, 1e-6));
      final chief = report.byPerson.firstWhere((g) => g.role == GeoRole.zoneChief);
      expect(chief.count, 1);
      // Slowest median first (same median here: then by name).
      expect(report.byPerson.first.key, 'supervisor:sup-1');

      final siteB = report.bySite.firstWhere((g) => g.key == 'b');
      expect(siteB.label, 'B · Site b');
      expect(siteB.summary.maxMs, 200000);
      expect(siteB.slowest!.id, '3');
      expect(report.bySite.first.key, 'b');

      expect(report.byDay.map((g) => g.day),
          [DateTime(2026, 11, 25), DateTime(2026, 11, 26)]);
      expect(report.byDay.first.label, 'mer. 25/11');
      expect(report.byDay.first.count, 2);

      expect(report.byMethod.map((g) => g.label),
          ['GPS', 'Photo après échec GPS', 'Photo']);
      expect(report.byMethod.first.count, 3);
      // Newest first in the record list.
      expect(report.records.first.date, DateTime(2026, 11, 26, 9));
    });

    test('filters by method and role', () {
      final chiefs = PointingDurationReport.aggregate(records,
          filter: const DurationFilter(role: GeoRole.zoneChief));
      expect(chiefs.summary.count, 1);
      expect(chiefs.byPerson.single.role, GeoRole.zoneChief);
      final fallback = PointingDurationReport.aggregate(records,
          filter: const DurationFilter(method: PointingMethod.photoFallback));
      expect(fallback.records.single.id, '2');
      final none = PointingDurationReport.aggregate(records,
          filter: const DurationFilter(
              method: PointingMethod.photo, role: GeoRole.zoneChief));
      expect(none.summary.count, 0);
      expect(none.byPerson, isEmpty);
      expect(none.averageGpsWaitMs, isNull);
    });

    test('« non mesuré » pointings are listed but never counted as 0', () {
      PointingDurationRecord unmeasured(String id,
              {String person = 'sup-1',
              String site = 'a',
              String method = 'geo',
              DateTime? at}) =>
          PointingDurationRecord.fromDocument(
            id,
            durationPointing(
              personUid: person,
              personName: 'Personne $person',
              siteUid: site,
              siteCode: site.toUpperCase(),
              siteName: 'Site $site',
              at: at ?? DateTime(2026, 11, 26, 10),
              method: method,
              // A zero total is « non mesuré » too.
              duration: id == 'zero' ? durationMap(0) : null,
            ),
            role: GeoRole.supervisor,
          );
      final report = PointingDurationReport.aggregate([
        ...records,
        unmeasured('u1'),
        unmeasured('zero', site: 'c', method: 'photo_fallback'),
        unmeasured('u3', at: DateTime(2026, 11, 24, 8)),
      ]);
      // Same statistics as without them.
      expect(report.records, hasLength(8));
      expect(report.summary.count, 5);
      expect(report.summary.medianMs, 60000);
      expect(report.summary.meanMs, 82000);
      expect(report.averageGpsWaitMs, (30000 + 50000 + 150000 + 40000) / 4);
      expect(report.unmeasured.map((r) => r.id).toSet(), {'u1', 'zero', 'u3'});
      expect(report.all.unmeasuredCount, 3);

      final sup = report.byPerson.firstWhere((g) => g.key == 'supervisor:sup-1');
      expect(sup.records, hasLength(7));
      expect(sup.count, 4);
      expect(sup.unmeasuredCount, 3);
      expect(sup.summary.medianMs, 60000);
      expect(sup.summary.meanMs, 87500);
      // The method is known without a duration: the fallback rate counts it.
      // (geo 1, 3, u1, u3; photo after GPS failure 2, zero).
      expect(sup.photoFallbackRate, closeTo(2 / 6, 1e-9));

      // A site with only « non mesuré » pointings: no statistic, not 0.
      final siteC = report.bySite.firstWhere((g) => g.key == 'c');
      expect(siteC.count, 0);
      expect(siteC.unmeasuredCount, 1);
      expect(siteC.summary.medianMs, isNull);
      expect(siteC.summary.meanMs, isNull);
      expect(siteC.summary.maxMs, isNull);
      expect(siteC.slowest, isNull);
      expect(siteC.averageGpsWaitMs, isNull);
      expect(formatDuration(siteC.summary.medianMs), '—');
      // Listed after the sites that have a median.
      expect(report.bySite.last.key, 'c');

      // A day with only « non mesuré » pointings.
      final day24 = report.byDay.first;
      expect(day24.day, DateTime(2026, 11, 24));
      expect(day24.count, 0);
      expect(day24.unmeasuredCount, 1);
      expect(day24.summary.medianMs, isNull);

      final fallback = report.byMethod
          .firstWhere((g) => g.method == PointingMethod.photoFallback);
      expect(fallback.count, 1);
      expect(fallback.unmeasuredCount, 1);
      expect(fallback.summary.medianMs, 80000);

      final siteA = report.bySite.firstWhere((g) => g.key == 'a');
      expect(siteA.slowest!.id, '5');
    });

    test('synthetic fixture is consistent', () {
      final result = syntheticDurationResult();
      final report = PointingDurationReport.aggregate(result.records);
      expect(report.byDay, hasLength(7));
      expect(report.byPerson, hasLength(6));
      expect(report.estimatedCount, greaterThan(0));
      expect(result.unmeasured, isNotEmpty);
      expect(report.summary.medianMs, isNotNull);
    });
  });
}
