import 'package:spas_web/geo_tracking/models/mobile_event.dart';
import 'package:spas_web/model.dart' show dateTimeFromJsonValue;
import 'package:spas_web/models/pointing_method.dart';

import 'error_log_model.dart';

enum VisitTimelineKind { mobileEvent, errorLog, pointing }

/// One step of the "Parcours de la visite" (all documents of one visitId).
class VisitTimelineEntry {
  const VisitTimelineEntry({
    required this.kind,
    required this.time,
    required this.title,
    this.detail,
    this.sourceId,
    this.isCurrent = false,
    this.errorLog,
  });

  final VisitTimelineKind kind;
  final DateTime? time;
  final String title;
  final String? detail;
  final String? sourceId;

  /// The error log the page is showing.
  final bool isCurrent;

  /// Set for error log entries, to open their own detail page.
  final ErrorLog? errorLog;

  static VisitTimelineEntry fromErrorLog(ErrorLog log, {String? currentId}) {
    return VisitTimelineEntry(
      kind: VisitTimelineKind.errorLog,
      time: log.timestamp,
      title: log.attemptLabel ?? ErrorTypeConfig.getLabel(log.errorType),
      detail: [
        ErrorTypeConfig.getLabel(log.errorType),
        if (log.customMessage != null && log.customMessage!.trim().isNotEmpty)
          log.customMessage!.trim(),
      ].join(' — '),
      sourceId: log.id,
      isCurrent: log.id == currentId,
      errorLog: log,
    );
  }

  static VisitTimelineEntry fromMobileEvent(MobileEvent event) {
    final detail = event.dataSummary;
    return VisitTimelineEntry(
      kind: VisitTimelineKind.mobileEvent,
      time: event.time,
      title: event.label,
      detail: detail.isEmpty ? null : detail,
      sourceId: event.id,
    );
  }

  /// [data] is a raw sitePointings / zonePointings document.
  static VisitTimelineEntry fromPointing(String id, Map<String, dynamic> data) {
    final method = PointingMethodInfo.fromDocument(data);
    final distance = data['distance'];
    return VisitTimelineEntry(
      kind: VisitTimelineKind.pointing,
      time: dateTimeFromJsonValue(data['datetimestamp']) ??
          dateTimeFromJsonValue(data['date']),
      title: 'Pointage enregistré'
          '${method == null ? '' : ' (${method.label})'}',
      detail: [
        if (distance is num) '${distance.round()} m du site',
        if (method?.method == PointingMethod.photoFallback)
          GeoFallbackReason.label(method!.fallbackReason),
      ].join(' · '),
      sourceId: id,
    );
  }
}

class VisitTimeline {
  /// Merges and sorts by time; entries without time go last.
  static List<VisitTimelineEntry> build({
    Iterable<ErrorLog> errorLogs = const [],
    Iterable<MobileEvent> events = const [],
    Iterable<MapEntry<String, Map<String, dynamic>>> pointings = const [],
    String? currentErrorLogId,
  }) {
    final entries = <VisitTimelineEntry>[
      ...errorLogs.map((log) =>
          VisitTimelineEntry.fromErrorLog(log, currentId: currentErrorLogId)),
      ...events.map(VisitTimelineEntry.fromMobileEvent),
      ...pointings.map((p) => VisitTimelineEntry.fromPointing(p.key, p.value)),
    ];
    entries.sort((a, b) {
      final ta = a.time;
      final tb = b.time;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      final byTime = ta.compareTo(tb);
      // Same instant: phone actions first, then failures, then the pointing.
      return byTime != 0 ? byTime : a.kind.index.compareTo(b.kind.index);
    });
    return entries;
  }
}
