import 'package:spas_web/model.dart' show dateTimeFromJsonValue;
import 'package:spas_web/models/pointing_method.dart';

import 'geo_stats.dart' show GeoRole;

/// « 45 s », « 1 min 05 s », « 1 h 02 min »; under 10 s one decimal
/// (« 4,2 s »). Null gives « — ».
String formatDuration(num? ms) {
  if (ms == null || ms.isNaN) return '—';
  if (ms < 0) return '—';
  if (ms < 9950) {
    final tenths = (ms / 100).round();
    if (tenths % 10 == 0) return '${tenths ~/ 10} s';
    return '${tenths ~/ 10},${tenths % 10} s';
  }
  final totalSeconds = (ms / 1000).round();
  if (totalSeconds < 60) return '$totalSeconds s';
  String two(int v) => v.toString().padLeft(2, '0');
  if (totalSeconds < 3600) {
    return '${totalSeconds ~/ 60} min ${two(totalSeconds % 60)} s';
  }
  final minutes = (totalSeconds / 60).round();
  return '${minutes ~/ 60} h ${two(minutes % 60)} min';
}

int? _ms(Object? value) {
  if (value is num && !value.isNaN && value >= 0) return value.round();
  if (value is String) {
    final parsed = num.tryParse(value.trim());
    if (parsed != null && !parsed.isNaN && parsed >= 0) return parsed.round();
  }
  return null;
}

int? _positiveMs(Object? value) {
  final ms = _ms(value);
  return ms == null || ms <= 0 ? null : ms;
}

String? _text(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

/// The `pointingDuration` map written by the phone on every pointing (or the
/// same keys in the `pointing_saved` event data), or an estimate rebuilt from
/// `mobile_events`.
class PointingDurationBreakdown {
  const PointingDurationBreakdown({
    required this.totalMs,
    this.gpsWaitMs,
    this.firstFixMs,
    this.decisionMs,
    this.photoMs,
    this.saveMs,
    this.relaunches = 0,
    this.startedAt,
  });

  static const String field = 'pointingDuration';

  /// First tap on the site in the current chain → pointing saved.
  final int totalMs;
  final int? gpsWaitMs;
  final int? firstFixMs;

  /// Photo button shown → tapped.
  final int? decisionMs;

  /// Camera opened → photo returned.
  final int? photoMs;
  final int? saveMs;

  /// Earlier unsaved visits of the same site chained into this one.
  final int relaunches;

  /// Phone time (informational, may be wrong).
  final DateTime? startedAt;

  /// Reads `pointingDuration` (`totalMs`) or `pointing_saved` data
  /// (`durationMs`). Null when there is no usable total: a total of 0 is not
  /// a measure (a pointing always takes time), so it is « non mesuré », never
  /// « 0 s ».
  static PointingDurationBreakdown? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final total = _positiveMs(raw['totalMs']) ?? _positiveMs(raw['durationMs']);
    if (total == null) return null;
    return PointingDurationBreakdown(
      totalMs: total,
      gpsWaitMs: _ms(raw['gpsWaitMs']),
      firstFixMs: _ms(raw['firstFixMs']),
      decisionMs: _ms(raw['decisionMs']),
      photoMs: _ms(raw['photoMs']),
      saveMs: _ms(raw['saveMs']),
      relaunches: _ms(raw['relaunches']) ?? 0,
      startedAt: dateTimeFromJsonValue(raw['startedAt']),
    );
  }

  /// « Attente GPS 40 s · 1re position 12 s · … » (known parts only).
  String get summary => [
        if (gpsWaitMs != null) 'Attente GPS ${formatDuration(gpsWaitMs)}',
        if (firstFixMs != null) '1re position ${formatDuration(firstFixMs)}',
        if (decisionMs != null) 'Décision ${formatDuration(decisionMs)}',
        if (photoMs != null) 'Photo ${formatDuration(photoMs)}',
        if (saveMs != null) 'Enregistrement ${formatDuration(saveMs)}',
        if (relaunches > 0)
          relaunches == 1 ? '1 relance' : '$relaunches relances',
      ].join(' · ');
}

/// Labels used by the « Durée des pointages » view (`pointingMethod`).
class DurationMethodLabels {
  static String label(PointingMethod? method) {
    switch (method) {
      case PointingMethod.geo:
        return 'GPS';
      case PointingMethod.photo:
        return 'Photo';
      case PointingMethod.photoFallback:
        return 'Photo après échec GPS';
      case null:
        return 'Méthode inconnue';
    }
  }
}

/// One pointing of the period (sitePointings / zonePointings document) with
/// its duration: measured by the phone, estimated from the journal, or
/// « non mesuré » ([duration] null — never counted as 0).
class PointingDurationRecord {
  const PointingDurationRecord({
    required this.id,
    required this.role,
    required this.personKey,
    required this.personName,
    required this.siteKey,
    required this.siteLabel,
    this.duration,
    this.date,
    this.method,
    this.estimated = false,
    this.visitId,
  });

  static const String measuredLabel = 'mesuré';
  static const String estimatedLabel = 'estimé (journal)';
  static const String unmeasuredLabel = 'non mesuré';

  final String id;
  final String role;
  final String personKey;
  final String personName;
  final String siteKey;
  final String siteLabel;

  /// Pointing time (`datetimestamp`).
  final DateTime? date;
  final PointingMethod? method;

  /// Null when the pointing has neither `pointingDuration` nor a usable
  /// journal estimate: shown « non mesuré », left out of every statistic.
  final PointingDurationBreakdown? duration;

  /// True when rebuilt from `mobile_events` (pointings without
  /// `pointingDuration`).
  final bool estimated;
  final String? visitId;

  /// False for « non mesuré » pointings.
  bool get hasDuration => duration != null;

  int? get totalMs => duration?.totalMs;

  /// True for visits in geolocation mode (GPS or photo after GPS failure).
  bool get isGeoMode => method != PointingMethod.photo;

  String get sourceLabel => duration == null
      ? unmeasuredLabel
      : estimated
          ? estimatedLabel
          : measuredLabel;

  static String personKeyOf(Map<String, dynamic> data, String role) =>
      _text(_actor(data, role)?['UID']) ?? 'inconnu';

  static Map? _actor(Map<String, dynamic> data, String role) {
    final actor =
        role == GeoRole.zoneChief ? data['zoneMember'] : data['supervisor'];
    return actor is Map ? actor : null;
  }

  static String _personName(Map? actor) {
    if (actor == null) return 'Inconnu';
    final name =
        '${actor['firstName'] ?? ''} ${actor['lastName'] ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    return _text(actor['code']) ?? 'Inconnu';
  }

  /// [data] is a raw pointing document. Uses its `pointingDuration`, or
  /// [estimate] when the document has none; without either the record is
  /// « non mesuré » ([duration] null).
  static PointingDurationRecord fromDocument(
    String id,
    Map<String, dynamic> data, {
    required String role,
    PointingDurationBreakdown? estimate,
  }) {
    final measured =
        PointingDurationBreakdown.fromMap(data[PointingDurationBreakdown.field]);
    final duration = measured ?? estimate;
    final actor = _actor(data, role);
    final site = data['site'] is Map ? data['site'] as Map : null;
    final siteCode = _text(site?['codeSite']) ?? _text(site?['code']);
    final siteName = _text(site?['name']);
    return PointingDurationRecord(
      id: id,
      role: role,
      personKey: _text(actor?['UID']) ?? 'inconnu',
      personName: _personName(actor),
      siteKey: _text(site?['UID']) ?? siteCode ?? siteName ?? 'inconnu',
      siteLabel: [siteCode, siteName].whereType<String>().join(' · ').isEmpty
          ? 'Site inconnu'
          : [siteCode, siteName].whereType<String>().join(' · '),
      date: dateTimeFromJsonValue(data['datetimestamp']) ??
          dateTimeFromJsonValue(data['date']),
      method: PointingMethodInfo.fromDocument(data)?.method,
      duration: duration,
      estimated: measured == null && duration != null,
      visitId: _text(data['visitId']),
    );
  }

  /// True when the document carries a usable `pointingDuration`.
  static bool hasMeasuredDuration(Map<String, dynamic> data) =>
      PointingDurationBreakdown.fromMap(data[PointingDurationBreakdown.field]) !=
      null;
}

/// Linear interpolation between closest ranks (same as a spreadsheet's
/// PERCENTILE.INC). [sorted] must be sorted ascending and not empty.
double percentile(List<int> sorted, double q) {
  assert(sorted.isNotEmpty);
  if (sorted.length == 1) return sorted.first.toDouble();
  final position = (sorted.length - 1) * q;
  final lower = position.floor();
  final upper = position.ceil();
  if (lower == upper) return sorted[lower].toDouble();
  final weight = position - lower;
  return sorted[lower] + (sorted[upper] - sorted[lower]) * weight;
}

/// Median, average, p90, max and share above 2 min of a set of durations.
class DurationSummary {
  const DurationSummary({
    required this.count,
    this.medianMs,
    this.meanMs,
    this.p90Ms,
    this.maxMs,
    this.overTwoMinutesShare,
  });

  static const int slowThresholdMs = 120000;

  final int count;
  final double? medianMs;
  final double? meanMs;
  final double? p90Ms;
  final int? maxMs;

  /// Share of durations strictly above 2 min (0..1), null when empty.
  final double? overTwoMinutesShare;

  static const DurationSummary empty = DurationSummary(count: 0);

  factory DurationSummary.of(Iterable<int> durations) {
    final sorted = durations.toList()..sort();
    if (sorted.isEmpty) return empty;
    final sum = sorted.fold<int>(0, (a, b) => a + b);
    return DurationSummary(
      count: sorted.length,
      medianMs: percentile(sorted, 0.5),
      meanMs: sum / sorted.length,
      p90Ms: percentile(sorted, 0.9),
      maxMs: sorted.last,
      overTwoMinutesShare:
          sorted.where((d) => d > slowThresholdMs).length / sorted.length,
    );
  }
}

double? _average(Iterable<int> values) {
  final list = values.toList();
  if (list.isEmpty) return null;
  return list.fold<int>(0, (a, b) => a + b) / list.length;
}

/// Durations of the records that have one (« non mesuré » ones are left out).
DurationSummary _summaryOf(Iterable<PointingDurationRecord> records) =>
    DurationSummary.of(records.map((r) => r.totalMs).whereType<int>());

/// Durations of one group (a person, a site, a day or a method).
class DurationGroup {
  DurationGroup({
    required this.key,
    required this.label,
    required this.records,
    this.role,
    this.day,
    this.method,
  }) : summary = _summaryOf(records);

  final String key;
  final String label;
  final String? role;
  final DateTime? day;
  final PointingMethod? method;

  /// Every pointing of the group, « non mesuré » ones included.
  final List<PointingDurationRecord> records;

  /// Statistics of the pointings with a duration only.
  final DurationSummary summary;

  /// Pointings with a duration (measured or estimated).
  int get count => summary.count;

  /// Pointings without any duration (« non mesuré »).
  int get unmeasuredCount => records.where((r) => !r.hasDuration).length;

  Iterable<PointingDurationRecord> get _timed =>
      records.where((r) => r.hasDuration);

  /// Average GPS wait of the geolocation-mode pointings (photo-mode
  /// pointings never wait for the GPS).
  double? get averageGpsWaitMs => _average(_timed
      .where((r) => r.isGeoMode)
      .map((r) => r.duration!.gpsWaitMs)
      .whereType<int>());

  int get relaunches =>
      _timed.fold(0, (sum, r) => sum + r.duration!.relaunches);

  int get estimatedCount => records.where((r) => r.estimated).length;

  /// photo_fallback ÷ (geo + photo_fallback), like the « Statistiques » tab
  /// (every pointing counts: the method is known even without a duration).
  double? get photoFallbackRate {
    final fallback =
        records.where((r) => r.method == PointingMethod.photoFallback).length;
    final geoMode = fallback +
        records.where((r) => r.method == PointingMethod.geo).length;
    return geoMode == 0 ? null : fallback / geoMode;
  }

  PointingDurationRecord? get slowest {
    final timed = _timed.toList();
    return timed.isEmpty
        ? null
        : timed.reduce((a, b) => b.totalMs! > a.totalMs! ? b : a);
  }
}

/// Filters of the view, applied in memory on the loaded period.
class DurationFilter {
  const DurationFilter({this.method, this.role});

  /// Null = every method.
  final PointingMethod? method;

  /// [GeoRole.supervisor], [GeoRole.zoneChief] or null for both.
  final String? role;

  bool matches(PointingDurationRecord record) =>
      (method == null || record.method == method) &&
      (role == null || record.role == role);
}

class PointingDurationReport {
  PointingDurationReport({
    required this.records,
    required this.byPerson,
    required this.bySite,
    required this.byDay,
    required this.byMethod,
  })  : summary = _summaryOf(records),
        all = DurationGroup(key: 'total', label: 'Total', records: records);

  /// Every pointing matching the filter, « non mesuré » ones included.
  final List<PointingDurationRecord> records;

  /// Statistics of the pointings with a duration only.
  final DurationSummary summary;
  final DurationGroup all;
  final List<DurationGroup> byPerson;
  final List<DurationGroup> bySite;

  /// Oldest day first.
  final List<DurationGroup> byDay;
  final List<DurationGroup> byMethod;

  double? get averageGpsWaitMs => all.averageGpsWaitMs;
  int get estimatedCount => all.estimatedCount;

  /// « non mesuré » pointings of the filtered period.
  List<PointingDurationRecord> get unmeasured =>
      records.where((r) => !r.hasDuration).toList();

  static DateTime dayOf(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  factory PointingDurationReport.aggregate(
    Iterable<PointingDurationRecord> source, {
    DurationFilter filter = const DurationFilter(),
  }) {
    final records = source.where(filter.matches).toList()
      ..sort((a, b) => (b.date ?? DateTime(0)).compareTo(a.date ?? DateTime(0)));

    Map<K, List<PointingDurationRecord>> groupBy<K>(
        K Function(PointingDurationRecord) key) {
      final map = <K, List<PointingDurationRecord>>{};
      for (final record in records) {
        map.putIfAbsent(key(record), () => []).add(record);
      }
      return map;
    }

    int bySlowestMedian(DurationGroup a, DurationGroup b) {
      final median = (b.summary.medianMs ?? 0).compareTo(a.summary.medianMs ?? 0);
      return median != 0 ? median : a.label.compareTo(b.label);
    }

    final persons = groupBy((r) => '${r.role}:${r.personKey}')
        .entries
        .map((e) => DurationGroup(
              key: e.key,
              label: e.value.first.personName,
              role: e.value.first.role,
              records: e.value,
            ))
        .toList()
      ..sort(bySlowestMedian);
    final sites = groupBy((r) => r.siteKey)
        .entries
        .map((e) => DurationGroup(
              key: e.key,
              label: e.value.first.siteLabel,
              records: e.value,
            ))
        .toList()
      ..sort(bySlowestMedian);
    final days = groupBy((r) => r.date == null ? null : dayOf(r.date!))
        .entries
        .where((e) => e.key != null)
        .map((e) => DurationGroup(
              key: e.key!.toIso8601String(),
              label: formatDurationDay(e.key!),
              day: e.key,
              records: e.value,
            ))
        .toList()
      ..sort((a, b) => a.day!.compareTo(b.day!));
    const methodOrder = [
      PointingMethod.geo,
      PointingMethod.photoFallback,
      PointingMethod.photo,
      null,
    ];
    final methodGroups = groupBy((r) => r.method);
    final methods = [
      for (final method in methodOrder)
        if (methodGroups[method] != null)
          DurationGroup(
            key: method == null
                ? 'unknown'
                : PointingMethodInfo.valueOf(method),
            label: DurationMethodLabels.label(method),
            method: method,
            records: methodGroups[method]!,
          ),
    ];

    return PointingDurationReport(
      records: records,
      byPerson: persons,
      bySite: sites,
      byDay: days,
      byMethod: methods,
    );
  }
}

const List<String> _weekDays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];

/// « mer. 26/11 ».
String formatDurationDay(DateTime day) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${_weekDays[day.weekday - 1]} ${two(day.day)}/${two(day.month)}';
}

/// « 26 % » / « 4,5 % » / « — ».
String formatShare(double? share) {
  if (share == null) return '—';
  if (share == 0) return '0 %';
  final percent = share * 100;
  return percent < 10
      ? '${percent.toStringAsFixed(1).replaceAll('.', ',')} %'
      : '${percent.round()} %';
}
