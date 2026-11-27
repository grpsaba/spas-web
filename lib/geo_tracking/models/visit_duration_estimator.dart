import 'mobile_event.dart';
import 'pointing_duration.dart';

/// Names of the `mobile_events` used to rebuild a duration.
class DurationEvents {
  static const String pointingStarted = 'pointing_started';
  static const String pointingSaved = 'pointing_saved';
  static const String geoAttemptFinished = 'geo_attempt_finished';
  static const String photoOffered = 'photo_fallback_offered';
  static const String photoTapped = 'photo_fallback_tapped';
  static const String photoCaptured = 'photo_captured';
  static const String gpsFirstFix = 'gps_first_fix';
}

/// Everything the journal says about one visit (one `visitId`).
class VisitEvents {
  VisitEvents._(this.visitId, List<MobileEvent> events)
      : events = List.unmodifiable(
            events..sort((a, b) => _compareTimes(a.time, b.time)));

  final String visitId;

  /// Sorted by phone time.
  final List<MobileEvent> events;

  static int _compareTimes(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  String? get userId => _first((e) => e.userId);
  String? get siteId => _first((e) => e.siteId ?? e.siteCode);

  String? _first(String? Function(MobileEvent) read) {
    for (final event in events) {
      final value = read(event);
      if (value != null) return value;
    }
    return null;
  }

  MobileEvent? _firstOf(String name) {
    for (final event in events) {
      if (event.event == name && event.time != null) return event;
    }
    return null;
  }

  MobileEvent? _lastOf(String name) {
    for (final event in events.reversed) {
      if (event.event == name && event.time != null) return event;
    }
    return null;
  }

  /// First `pointing_started` (first tap on the site).
  DateTime? get startedAt => _firstOf(DurationEvents.pointingStarted)?.time;

  MobileEvent? get savedEvent => _lastOf(DurationEvents.pointingSaved);
  DateTime? get savedAt => savedEvent?.time;
  bool get isSaved => savedEvent != null;

  /// Start used to order visits: `pointing_started`, else first action.
  DateTime? get orderTime => startedAt ?? _firstTime;

  DateTime? get _firstTime {
    for (final event in events) {
      if (event.time != null) return event.time;
    }
    return null;
  }

  DateTime? get lastActionAt {
    for (final event in events.reversed) {
      if (event.time != null) return event.time;
    }
    return null;
  }

  /// Sum of `geo_attempt_finished.data.durationMs`.
  int get gpsWaitMs => events
      .where((e) => e.event == DurationEvents.geoAttemptFinished)
      .map((e) => e.data['durationMs'])
      .whereType<num>()
      .where((v) => !v.isNaN && v >= 0)
      .fold(0, (sum, v) => sum + v.round());

  static Map<String, VisitEvents> group(Iterable<MobileEvent> events) {
    final byVisit = <String, List<MobileEvent>>{};
    final seen = <String>{};
    for (final event in events) {
      final visitId = event.visitId;
      if (visitId == null || !seen.add(event.id)) continue;
      byVisit.putIfAbsent(visitId, () => []).add(event);
    }
    return byVisit
        .map((id, list) => MapEntry(id, VisitEvents._(id, list)));
  }
}

int? _between(DateTime? from, DateTime? to) {
  if (from == null || to == null) return null;
  final ms = to.difference(from).inMilliseconds;
  return ms < 0 ? null : ms;
}

/// Rebuilds `pointingDuration` from `mobile_events` for pointings recorded
/// by the app build that logged the journal but not the duration.
///
/// Durations are differences of `clientTimestamp` (same phone clock, so a
/// wrong phone time cancels out). Earlier visits of the same person and site
/// that were not saved are chained when each one started less than
/// [chainGap] after the previous one's last action: their time counts and
/// each adds one relaunch.
class VisitDurationEstimator {
  static const Duration chainGap = Duration(minutes: 15);

  /// Returns the estimate of each visit of [targetVisitIds] that has both a
  /// `pointing_started` and a `pointing_saved` event. [savedVisitIds] are
  /// visits known as saved from the pointing documents (they stop a chain
  /// even if their `pointing_saved` event is missing).
  static Map<String, PointingDurationBreakdown> estimate(
    Iterable<MobileEvent> events, {
    required Set<String> targetVisitIds,
    Set<String> savedVisitIds = const {},
  }) {
    final visits = VisitEvents.group(events);

    // Visits of each person + site, oldest first.
    final byPersonSite = <String, List<VisitEvents>>{};
    for (final visit in visits.values) {
      final user = visit.userId;
      final site = visit.siteId;
      if (user == null || site == null || visit.orderTime == null) continue;
      byPersonSite.putIfAbsent('$user|$site', () => []).add(visit);
    }
    for (final list in byPersonSite.values) {
      list.sort((a, b) => a.orderTime!.compareTo(b.orderTime!));
    }

    final result = <String, PointingDurationBreakdown>{};
    for (final visitId in targetVisitIds) {
      final target = visits[visitId];
      if (target == null) continue;
      final started = target.startedAt;
      final saved = target.savedAt;
      if (started == null || saved == null) continue;

      var chainStart = started;
      var relaunches = 0;
      var gpsWait = target.gpsWaitMs;
      final siblings =
          byPersonSite['${target.userId}|${target.siteId}'] ?? const [];
      var current = target;
      for (final previous in siblings.reversed) {
        if (identical(previous, target)) continue;
        if (!previous.orderTime!.isBefore(current.orderTime!)) continue;
        if (previous.isSaved || savedVisitIds.contains(previous.visitId)) {
          break;
        }
        final last = previous.lastActionAt!;
        final gap = current.orderTime!.difference(last);
        if (gap >= chainGap) break;
        relaunches++;
        gpsWait += previous.gpsWaitMs;
        chainStart = previous.orderTime!;
        current = previous;
      }

      final total = _between(chainStart, saved);
      // 0 ms is not a duration (same clock tick): left « non mesuré ».
      if (total == null || total <= 0) continue;

      final offered = target._lastOf(DurationEvents.photoOffered)?.time;
      final tapped = target._lastOf(DurationEvents.photoTapped)?.time;
      final captured = target._lastOf(DurationEvents.photoCaptured)?.time;
      final lastAttempt =
          target._lastOf(DurationEvents.geoAttemptFinished)?.time;
      final firstFix = target._firstOf(DurationEvents.gpsFirstFix)?.data['ms'];
      final beforeSave = captured ?? lastAttempt;

      result[visitId] = PointingDurationBreakdown(
        totalMs: total,
        gpsWaitMs: gpsWait,
        firstFixMs: firstFix is num && firstFix >= 0 ? firstFix.round() : null,
        decisionMs: _between(offered, tapped),
        photoMs: _between(tapped, captured),
        saveMs: beforeSave == null ? null : _between(beforeSave, saved),
        relaunches: relaunches,
        startedAt: chainStart,
      );
    }
    return result;
  }

  /// Visits that may be chained before the targets: same person and site,
  /// started before the target's start and at most [lookback] earlier.
  /// [started] are `pointing_started` events of the targets' persons; the
  /// returned visitIds still need their full events (last action, GPS wait).
  static Set<String> predecessorCandidates(
    Iterable<MobileEvent> targetEvents,
    Iterable<MobileEvent> started, {
    Duration lookback = const Duration(hours: 12),
  }) {
    final targets = VisitEvents.group(targetEvents);
    final windows = <String, List<DateTime>>{};
    for (final visit in targets.values) {
      final user = visit.userId;
      final site = visit.siteId;
      final start = visit.orderTime;
      if (user == null || site == null || start == null) continue;
      windows.putIfAbsent('$user|$site', () => []).add(start);
    }
    final candidates = <String>{};
    for (final event in started) {
      final visitId = event.visitId;
      final time = event.time;
      final site = event.siteId ?? event.siteCode;
      if (visitId == null || time == null || event.userId == null) continue;
      if (site == null || targets.containsKey(visitId)) continue;
      final starts = windows['${event.userId}|$site'];
      if (starts == null) continue;
      if (starts.any((s) => time.isBefore(s) && s.difference(time) <= lookback)) {
        candidates.add(visitId);
      }
    }
    return candidates;
  }
}
