import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/geo_tracking/models/mobile_event.dart';
import 'package:spas_web/geo_tracking/models/visit_duration_estimator.dart';

import 'duration_fixtures.dart';

DateTime _t(int h, int m, [int s = 0]) => DateTime(2026, 11, 26, h, m, s);

/// u1 at site s1: v0 (07:00, abandoned long before), v1 (08:00, abandoned
/// after a 30 s GPS attempt), v2 (08:05, saved with the photo after a 45 s
/// GPS attempt). Plus a visit of the same person at another site.
List<MobileEvent> _chainEvents() => [
      journalEvent('e0a', 'pointing_started', visitId: 'v0', at: _t(7, 0)),
      journalEvent('e0b', 'geo_cancel_tapped', visitId: 'v0', at: _t(7, 1)),
      journalEvent('e1a', 'pointing_started', visitId: 'v1', at: _t(8, 0)),
      journalEvent('e1b', 'geo_attempt_finished',
          visitId: 'v1',
          at: _t(8, 0, 30),
          data: {'outcome': 'timeout', 'durationMs': 30000}),
      journalEvent('e1c', 'geo_cancel_tapped', visitId: 'v1', at: _t(8, 0, 40)),
      // Same person, other site, in between: not part of the chain.
      journalEvent('ex', 'pointing_started',
          visitId: 'vx', siteId: 's2', at: _t(8, 3)),
      journalEvent('e2a', 'pointing_started', visitId: 'v2', at: _t(8, 5)),
      journalEvent('e2b', 'geo_attempt_finished',
          visitId: 'v2',
          at: _t(8, 5, 45),
          data: {'outcome': 'timeout', 'durationMs': 45000}),
      journalEvent('e2c', 'photo_fallback_offered',
          visitId: 'v2', at: _t(8, 5, 45)),
      journalEvent('e2d', 'photo_fallback_tapped',
          visitId: 'v2', at: _t(8, 5, 50)),
      journalEvent('e2e', 'photo_captured', visitId: 'v2', at: _t(8, 6, 0)),
      journalEvent('e2f', 'pointing_saved', visitId: 'v2', at: _t(8, 6, 5)),
    ];

void main() {
  test('chains earlier unsaved visits: relaunch, GPS wait, breakdown', () {
    final estimates = VisitDurationEstimator.estimate(_chainEvents(),
        targetVisitIds: {'v2'});
    final v2 = estimates['v2']!;
    // 08:00:00 (v1 start) → 08:06:05 (v2 saved).
    expect(v2.totalMs, const Duration(minutes: 6, seconds: 5).inMilliseconds);
    expect(v2.relaunches, 1);
    expect(v2.gpsWaitMs, 75000);
    expect(v2.decisionMs, 5000);
    expect(v2.photoMs, 10000);
    expect(v2.saveMs, 5000);
    expect(v2.firstFixMs, isNull);
    expect(v2.startedAt, _t(8, 0));
  });

  test('a gap of 15 min or more ends the chain', () {
    final events = [
      journalEvent('a1', 'pointing_started', visitId: 'a', at: _t(9, 0)),
      journalEvent('a2', 'geo_attempt_finished',
          visitId: 'a', at: _t(9, 0, 30), data: {'durationMs': 30000}),
      journalEvent('b1', 'pointing_started', visitId: 'b', at: _t(9, 15, 30)),
      journalEvent('b2', 'pointing_saved', visitId: 'b', at: _t(9, 16, 30)),
    ];
    final b = VisitDurationEstimator.estimate(events, targetVisitIds: {'b'})['b']!;
    expect(b.relaunches, 0);
    expect(b.totalMs, 60000);
    expect(b.gpsWaitMs, 0);
    expect(b.saveMs, isNull);
  });

  test('a saved previous visit is never chained', () {
    final events = [
      journalEvent('a1', 'pointing_started', visitId: 'a', at: _t(9, 0)),
      journalEvent('a2', 'pointing_saved', visitId: 'a', at: _t(9, 1)),
      journalEvent('b1', 'pointing_started', visitId: 'b', at: _t(9, 2)),
      journalEvent('b2', 'pointing_saved', visitId: 'b', at: _t(9, 3)),
      // c's pointing_saved event is missing but its pointing document exists.
      journalEvent('c1', 'pointing_started', visitId: 'c', at: _t(9, 4)),
      journalEvent('d1', 'pointing_started', visitId: 'd', at: _t(9, 5)),
      journalEvent('d2', 'pointing_saved', visitId: 'd', at: _t(9, 6)),
    ];
    final estimates = VisitDurationEstimator.estimate(events,
        targetVisitIds: {'b', 'd'}, savedVisitIds: {'a', 'b', 'c', 'd'});
    expect(estimates['b']!.relaunches, 0);
    expect(estimates['b']!.totalMs, 60000);
    expect(estimates['d']!.relaunches, 0);
  });

  test('a visit without pointing_saved (or pointing_started) is ignored', () {
    final events = [
      journalEvent('a1', 'pointing_started', visitId: 'a', at: _t(10, 0)),
      journalEvent('a2', 'geo_attempt_finished',
          visitId: 'a', at: _t(10, 0, 30), data: {'durationMs': 30000}),
      journalEvent('b2', 'pointing_saved', visitId: 'b', at: _t(10, 3)),
    ];
    final estimates = VisitDurationEstimator.estimate(events,
        targetVisitIds: {'a', 'b', 'unknown'});
    expect(estimates, isEmpty);
  });

  test('uses phone time differences even when the phone clock is wrong', () {
    final events = [
      journalEvent('a1', 'pointing_started',
          visitId: 'a',
          at: DateTime(2020, 1, 1, 12, 0),
          serverAt: _t(11, 0)),
      journalEvent('a2', 'gps_first_fix',
          visitId: 'a',
          at: DateTime(2020, 1, 1, 12, 0, 12),
          serverAt: _t(11, 0, 50),
          data: {'ms': 12000, 'accuracyM': 18.4}),
      journalEvent('a3', 'pointing_saved',
          visitId: 'a',
          at: DateTime(2020, 1, 1, 12, 1, 23),
          serverAt: _t(11, 4)),
    ];
    final a =
        VisitDurationEstimator.estimate(events, targetVisitIds: {'a'})['a']!;
    expect(a.totalMs, 83000);
    expect(a.firstFixMs, 12000);
  });

  test('two relaunches add their time and GPS wait', () {
    final events = [
      journalEvent('a1', 'pointing_started', visitId: 'a', at: _t(12, 0)),
      journalEvent('a2', 'geo_attempt_finished',
          visitId: 'a', at: _t(12, 0, 40), data: {'durationMs': 40000}),
      journalEvent('b1', 'pointing_started', visitId: 'b', at: _t(12, 10)),
      journalEvent('b2', 'geo_attempt_finished',
          visitId: 'b', at: _t(12, 10, 20), data: {'durationMs': 20000}),
      journalEvent('c1', 'pointing_started', visitId: 'c', at: _t(12, 12)),
      journalEvent('c2', 'geo_attempt_finished',
          visitId: 'c',
          at: _t(12, 12, 10),
          data: {'durationMs': 10000, 'outcome': 'success'}),
      journalEvent('c3', 'pointing_saved', visitId: 'c', at: _t(12, 12, 12)),
    ];
    final c =
        VisitDurationEstimator.estimate(events, targetVisitIds: {'c'})['c']!;
    expect(c.relaunches, 2);
    expect(c.gpsWaitMs, 70000);
    expect(c.totalMs, const Duration(minutes: 12, seconds: 12).inMilliseconds);
    expect(c.saveMs, 2000);
  });

  test('predecessor candidates: same person and site, before, in window', () {
    final events = _chainEvents();
    final targetEvents = events.where((e) => e.visitId == 'v2');
    final started = [
      ...events.where((e) => e.event == 'pointing_started'),
      journalEvent('other-user', 'pointing_started',
          visitId: 'vu', userId: 'u2', at: _t(8, 1)),
      journalEvent('too-old', 'pointing_started',
          visitId: 'vold', at: DateTime(2026, 11, 25, 6)),
      journalEvent('after', 'pointing_started', visitId: 'vafter', at: _t(9, 0)),
    ];
    expect(
        VisitDurationEstimator.predecessorCandidates(targetEvents, started),
        {'v0', 'v1'});
  });
}
