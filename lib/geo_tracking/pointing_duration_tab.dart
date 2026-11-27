import 'package:flutter/material.dart';
import 'package:spas_web/models/pointing_method.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';

import 'models/geo_stats.dart';
import 'models/pointing_duration.dart';
import 'services/geo_tracking_service.dart';
import 'widgets/geo_common.dart';

typedef PointingDurationLoader = Future<PointingDurationLoadResult> Function(
    DateTime start, DateTime end);

const Color _medianColor = Color(0xFF1D4ED8);
const Color _slowColor = Color(0xFFC2410C);
const Color _estimatedColor = Color(0xFFB45309);

/// « Durée des pointages »: how long a pointing takes, from the first tap on
/// the site until the pointing is saved (relaunches included). Read only.
class PointingDurationTab extends StatefulWidget {
  const PointingDurationTab({super.key, this.loader, this.initialRange});

  /// Injected in tests; defaults to [GeoTrackingService.loadDurations].
  final PointingDurationLoader? loader;
  final DateTimeRange? initialRange;

  @override
  State<PointingDurationTab> createState() => _PointingDurationTabState();
}

class _PointingDurationTabState extends State<PointingDurationTab>
    with AutomaticKeepAliveClientMixin {
  late DateTimeRange _range = widget.initialRange ?? defaultGeoRange();
  PointingMethod? _method;
  String? _role;
  late Future<PointingDurationLoadResult> _future = _load();

  @override
  bool get wantKeepAlive => true;

  Future<PointingDurationLoadResult> _load() {
    final start = _range.start;
    final end = _range.end.add(const Duration(days: 1));
    return widget.loader?.call(start, end) ??
        GeoTrackingService().loadDurations(start, end);
  }

  void _reload() => setState(() => _future = _load());

  DurationFilter get _filter => DurationFilter(method: _method, role: _role);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<PointingDurationLoadResult>(
      future: _future,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.all(PointageSpacing.lg),
          children: [
            _buildFilters(),
            const SizedBox(height: PointageSpacing.sm),
            const Text(
              'Durée d\'un pointage = du premier appui sur le site jusqu\'au '
              'pointage enregistré, relances comprises (visites non '
              'enregistrées du même site reprises moins de 15 min après). '
              'La médiane est la valeur de référence : la moitié des pointages '
              'prennent moins de temps. La moyenne monte vite quand un écran '
              'reste ouvert.',
              style: PointageTextStyles.caption,
            ),
            const SizedBox(height: PointageSpacing.md),
            if (snapshot.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.all(PointageSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              Text('Erreur de chargement : ${snapshot.error}',
                  style: PointageTextStyles.body2
                      .copyWith(color: PointageColors.error))
            else
              ..._buildReport(snapshot.data!),
          ],
        );
      },
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: PointageSpacing.sm,
      runSpacing: PointageSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        GeoRangeButton(
          range: _range,
          onChanged: (range) {
            _range = range;
            _reload();
          },
        ),
        SizedBox(
          width: 250,
          child: DropdownButtonFormField<PointingMethod?>(
            key: const ValueKey('duration-method'),
            initialValue: _method,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Méthode',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<PointingMethod?>(
                  value: null, child: Text('Toutes')),
              for (final method in const [
                PointingMethod.geo,
                PointingMethod.photo,
                PointingMethod.photoFallback,
              ])
                DropdownMenuItem<PointingMethod?>(
                  value: method,
                  child: Text(DurationMethodLabels.label(method)),
                ),
            ],
            onChanged: (value) => setState(() => _method = value),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String?>(
            key: const ValueKey('duration-role'),
            initialValue: _role,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Rôle',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem<String?>(value: null, child: Text('Tous')),
              DropdownMenuItem<String?>(
                  value: GeoRole.supervisor, child: Text('Superviseurs')),
              DropdownMenuItem<String?>(
                  value: GeoRole.zoneChief, child: Text('Chefs de zone')),
            ],
            onChanged: (value) => setState(() => _role = value),
          ),
        ),
        IconButton(
          tooltip: 'Actualiser',
          onPressed: _reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  List<Widget> _buildReport(PointingDurationLoadResult result) {
    final report =
        PointingDurationReport.aggregate(result.records, filter: _filter);
    final unmeasured = report.unmeasured;
    final withoutVisit = unmeasured.where((r) => r.visitId == null).length;
    final incomplete = unmeasured.length - withoutVisit;
    final summary = report.summary;
    final share = summary.overTwoMinutesShare;
    // Extra column only when the period has « non mesuré » pointings.
    final unmeasuredColumns = [if (unmeasured.isNotEmpty) _unmeasuredColumn];
    return [
      for (final collection in result.truncatedCollections)
        GeoNotice(
          'Période trop chargée : seuls les premiers documents de '
          '$collection sont comptés. Réduisez la période.',
        ),
      for (final warning in result.warnings) GeoNotice('Non chargé — $warning'),
      Wrap(
        spacing: PointageSpacing.sm,
        runSpacing: PointageSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          GeoKpi(
            'Durée médiane',
            formatDuration(summary.medianMs),
            _medianColor,
            large: true,
            tooltip: 'La moitié des pointages prennent moins de temps. '
                'Peu sensible aux écrans laissés ouverts.',
          ),
          GeoKpi('Pointages mesurés', '${summary.count}',
              PointageColors.primary,
              tooltip: report.estimatedCount == 0
                  ? null
                  : 'Dont ${report.estimatedCount} estimé(s) depuis le journal '
                      'des actions mobiles.'),
          GeoKpi('Moyenne', formatDuration(summary.meanMs),
              PointageColors.textSecondary),
          GeoKpi('90 % des pointages en moins de', formatDuration(summary.p90Ms),
              const Color(0xFF7C3AED),
              tooltip: 'P90 : seuls 10 % des pointages durent plus longtemps.'),
          GeoKpi('Attente GPS moyenne', formatDuration(report.averageGpsWaitMs),
              const Color(0xFF15803D),
              tooltip: 'Pointages en mode géolocalisation (GPS ou photo après '
                  'échec GPS). Les pointages en mode Photo n\'attendent pas '
                  'le GPS.'),
          GeoKpi('Pointages de plus de 2 min', formatShare(share),
              (share ?? 0) >= 0.2 ? PointageColors.error : _slowColor),
          if (unmeasured.isNotEmpty)
            GeoKpi(
              'Non mesurés',
              '${unmeasured.length}',
              PointageColors.textSecondary,
              tooltip: 'Pointages sans durée : ni mesurée par le téléphone, '
                  'ni reconstituable depuis le journal. Ils ne comptent pas '
                  'dans la médiane ni la moyenne.',
            ),
        ],
      ),
      const SizedBox(height: PointageSpacing.sm),
      Text(
        [
          if (report.estimatedCount > 0)
            '${report.estimatedCount} pointage(s) « ${PointingDurationRecord.estimatedLabel} » : '
                'durée reconstituée depuis le journal des actions mobiles '
                '(version précédente de l\'app).',
          if (unmeasured.isNotEmpty)
            '${unmeasured.length} pointage(s) « ${PointingDurationRecord.unmeasuredLabel} »'
                ' (${[
              if (withoutVisit > 0)
                '$withoutVisit d\'une ancienne version de l\'app, sans journal',
              if (incomplete > 0) '$incomplete au journal incomplet',
            ].join(', ')}) : non comptés dans les durées.',
        ].join(' '),
        style: PointageTextStyles.caption,
      ),
      const SizedBox(height: PointageSpacing.lg),
      DurationGroupTable(
        key: const ValueKey('duration-by-person'),
        title: 'Par superviseur / chef de zone',
        firstColumn: 'Personne',
        groups: report.byPerson,
        columns: [
          DurationColumn('Rôle',
              numeric: false,
              sortValue: (g) => GeoRole.label(g.role),
              cell: (g) => Text(GeoRole.label(g.role))),
          ..._countMedianMeanP90,
          DurationColumn('Secours photo',
              tooltip: 'Photo après échec GPS ÷ (GPS + Photo après échec GPS)',
              sortValue: (g) => g.photoFallbackRate,
              cell: (g) => Text(formatShare(g.photoFallbackRate))),
          DurationColumn('Attente GPS moy.',
              sortValue: (g) => g.averageGpsWaitMs,
              cell: (g) => Text(formatDuration(g.averageGpsWaitMs))),
          DurationColumn('Relances',
              tooltip: 'Visites non enregistrées reprises (même site, '
                  'moins de 15 min après)',
              sortValue: (g) => g.relaunches,
              cell: (g) => Text('${g.relaunches}')),
          ...unmeasuredColumns,
        ],
        initialSortColumn: 3,
        detailsShowPerson: false,
      ),
      const SizedBox(height: PointageSpacing.lg),
      DurationGroupTable(
        key: const ValueKey('duration-by-site'),
        title: 'Par site',
        firstColumn: 'Site',
        groups: report.bySite,
        columns: [
          _countColumn,
          _medianColumn,
          _meanColumn,
          DurationColumn('Le plus lent',
              sortValue: (g) => g.summary.maxMs,
              cell: (g) => Text(formatDuration(g.summary.maxMs))),
          ...unmeasuredColumns,
        ],
        initialSortColumn: 2,
        detailsShowSite: false,
      ),
      const SizedBox(height: PointageSpacing.lg),
      _byDayTable(report, unmeasuredColumns),
      const SizedBox(height: PointageSpacing.lg),
      DurationGroupTable(
        key: const ValueKey('duration-by-method'),
        title: 'Par méthode',
        firstColumn: 'Méthode',
        groups: report.byMethod,
        columns: [
          ..._countMedianMeanP90,
          DurationColumn('Attente GPS moy.',
              sortValue: (g) => g.averageGpsWaitMs,
              cell: (g) => Text(formatDuration(g.averageGpsWaitMs))),
          _slowShareColumn,
          ...unmeasuredColumns,
        ],
      ),
    ];
  }

  Widget _byDayTable(PointingDurationReport report,
      List<DurationColumn> unmeasuredColumns) {
    final maxMedian = report.byDay.fold<double>(
        0, (max, g) => (g.summary.medianMs ?? 0) > max ? g.summary.medianMs! : max);
    return DurationGroupTable(
      key: const ValueKey('duration-by-day'),
      title: 'Par jour',
      firstColumn: 'Jour',
      groups: report.byDay,
      firstColumnSortValue: (g) => g.day,
      columns: [
        _countColumn,
        DurationColumn('Médiane',
            sortValue: (g) => g.summary.medianMs,
            cell: (g) => _MedianBar(
                  medianMs: g.summary.medianMs,
                  maxMs: maxMedian,
                )),
        _meanColumn,
        _p90Column,
        _slowShareColumn,
        ...unmeasuredColumns,
      ],
      initialSortColumn: 0,
      initialAscending: true,
      maxRows: 62,
    );
  }
}

/// « non mesuré » in place of a duration (never « 0 s »).
class _UnmeasuredText extends StatelessWidget {
  const _UnmeasuredText();

  @override
  Widget build(BuildContext context) => const Text(
        PointingDurationRecord.unmeasuredLabel,
        style: TextStyle(
          color: PointageColors.textSecondary,
          fontStyle: FontStyle.italic,
          fontSize: 12.5,
        ),
      );
}

DurationColumn get _countColumn => DurationColumn('Pointages',
    tooltip: 'Pointages dont la durée est connue (mesurée ou estimée)',
    sortValue: (g) => g.count,
    cell: (g) => Text('${g.count}'));

DurationColumn get _unmeasuredColumn => DurationColumn('Non mesurés',
    tooltip: 'Pointages sans durée (ni mesurée, ni estimable) : non comptés '
        'dans la médiane ni la moyenne',
    sortValue: (g) => g.unmeasuredCount,
    cell: (g) => Text('${g.unmeasuredCount}',
        style: g.unmeasuredCount == 0
            ? const TextStyle(color: PointageColors.textSecondary)
            : null));

DurationColumn get _medianColumn => DurationColumn('Médiane',
    sortValue: (g) => g.summary.medianMs,
    cell: (g) => g.count == 0
        ? const _UnmeasuredText()
        : Text(formatDuration(g.summary.medianMs),
            style: const TextStyle(fontWeight: FontWeight.w700)));

DurationColumn get _meanColumn => DurationColumn('Moyenne',
    sortValue: (g) => g.summary.meanMs,
    cell: (g) => Text(formatDuration(g.summary.meanMs)));

DurationColumn get _p90Column => DurationColumn('P90',
    tooltip: '90 % des pointages durent moins que cette valeur',
    sortValue: (g) => g.summary.p90Ms,
    cell: (g) => Text(formatDuration(g.summary.p90Ms)));

DurationColumn get _slowShareColumn => DurationColumn('> 2 min',
    sortValue: (g) => g.summary.overTwoMinutesShare,
    cell: (g) => Text(formatShare(g.summary.overTwoMinutesShare)));

List<DurationColumn> get _countMedianMeanP90 =>
    [_countColumn, _medianColumn, _meanColumn, _p90Column];

class _MedianBar extends StatelessWidget {
  const _MedianBar({required this.medianMs, required this.maxMs});

  final double? medianMs;
  final double maxMs;

  @override
  Widget build(BuildContext context) {
    final ratio =
        medianMs == null || maxMs <= 0 ? 0.0 : (medianMs! / maxMs).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 120,
          height: 10,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: _medianColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(5),
          ),
          child: FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              decoration: BoxDecoration(
                color: _medianColor.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: medianMs == null
              ? const Align(
                  alignment: Alignment.centerRight, child: _UnmeasuredText())
              : Text(formatDuration(medianMs),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// A column of [DurationGroupTable]; [sortValue] returns a Comparable (or
/// null, sorted last).
class DurationColumn {
  const DurationColumn(
    this.label, {
    required this.cell,
    this.sortValue,
    this.numeric = true,
    this.tooltip,
  });

  final String label;
  final Widget Function(DurationGroup group) cell;
  final Comparable<Object?>? Function(DurationGroup group)? sortValue;
  final bool numeric;
  final String? tooltip;
}

int _compareNullable(Comparable<Object?>? a, Comparable<Object?>? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

/// Sortable table of groups; a click on a row opens its pointings.
class DurationGroupTable extends StatefulWidget {
  const DurationGroupTable({
    super.key,
    required this.title,
    required this.firstColumn,
    required this.groups,
    required this.columns,
    this.firstColumnSortValue,
    this.initialSortColumn,
    this.initialAscending = false,
    this.maxRows = 25,
    this.detailsShowPerson = true,
    this.detailsShowSite = true,
  });

  final String title;
  final String firstColumn;
  final List<DurationGroup> groups;
  final List<DurationColumn> columns;
  final Comparable<Object?>? Function(DurationGroup group)? firstColumnSortValue;

  /// Index in the visible columns (0 = first column); null keeps the order.
  final int? initialSortColumn;
  final bool initialAscending;
  final int maxRows;
  final bool detailsShowPerson;
  final bool detailsShowSite;

  @override
  State<DurationGroupTable> createState() => _DurationGroupTableState();
}

class _DurationGroupTableState extends State<DurationGroupTable> {
  late int? _sortColumn = widget.initialSortColumn;
  late bool _ascending = widget.initialAscending;
  bool _showAll = false;

  Comparable<Object?>? Function(DurationGroup)? _sortValueOf(int column) {
    if (column == 0) {
      return widget.firstColumnSortValue ?? (g) => g.label.toLowerCase();
    }
    return widget.columns[column - 1].sortValue;
  }

  List<DurationGroup> get _sorted {
    final groups = List<DurationGroup>.of(widget.groups);
    final column = _sortColumn;
    if (column == null) return groups;
    final value = _sortValueOf(column);
    if (value == null) return groups;
    groups.sort((a, b) {
      final va = value(a);
      final vb = value(b);
      // Empty values stay last whatever the direction.
      if (va == null || vb == null) return _compareNullable(va, vb);
      final result = va.compareTo(vb);
      return _ascending ? result : -result;
    });
    return groups;
  }

  void _onSort(int column, bool ascending) => setState(() {
        _sortColumn = column;
        _ascending = ascending;
      });

  @override
  Widget build(BuildContext context) {
    final sorted = _sorted;
    final visible = _showAll || sorted.length <= widget.maxRows
        ? sorted
        : sorted.take(widget.maxRows).toList();
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(widget.title, style: PointageTextStyles.headline4),
              const SizedBox(width: PointageSpacing.sm),
              if (widget.groups.isNotEmpty)
                const Text('Cliquez une ligne pour voir ses pointages',
                    style: PointageTextStyles.caption),
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          if (widget.groups.isEmpty)
            const Text('Aucun pointage mesuré sur la période.',
                style: PointageTextStyles.caption)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 52,
                columnSpacing: 22,
                showCheckboxColumn: false,
                sortColumnIndex: _sortColumn,
                sortAscending: _ascending,
                columns: [
                  DataColumn(
                    label: Text(widget.firstColumn),
                    onSort: _onSort,
                  ),
                  for (final column in widget.columns)
                    DataColumn(
                      label: column.tooltip == null
                          ? Text(column.label)
                          : Tooltip(
                              message: column.tooltip!,
                              child: Text(column.label),
                            ),
                      numeric: column.numeric,
                      onSort: column.sortValue == null ? null : _onSort,
                    ),
                ],
                rows: [
                  for (final group in visible)
                    DataRow(
                      onSelectChanged: (_) => showPointingDurationDetails(
                        context,
                        title: '${widget.title} · ${group.label}',
                        records: group.records,
                        showPerson: widget.detailsShowPerson,
                        showSite: widget.detailsShowSite,
                      ),
                      cells: [
                        DataCell(ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(group.label,
                              overflow: TextOverflow.ellipsis),
                        )),
                        for (final column in widget.columns)
                          DataCell(column.cell(group)),
                      ],
                    ),
                ],
              ),
            ),
          if (sorted.length > widget.maxRows)
            TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(_showAll
                  ? 'Afficher moins'
                  : 'Afficher les ${sorted.length} lignes'),
            ),
        ],
      ),
    );
  }
}

/// Dialog listing [records] with their breakdown.
Future<void> showPointingDurationDetails(
  BuildContext context, {
  required String title,
  required List<PointingDurationRecord> records,
  bool showPerson = true,
  bool showSite = true,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final size = MediaQuery.of(context).size;
      final summary =
          DurationSummary.of(records.map((r) => r.totalMs).whereType<int>());
      final unmeasured = records.where((r) => !r.hasDuration).length;
      return Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 1400,
            maxHeight: size.height * 0.85,
          ),
          child: Padding(
            padding: const EdgeInsets.all(PointageSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: PointageTextStyles.headline4),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  '${summary.count} pointage(s)'
                  '${unmeasured == 0 ? '' : ' + $unmeasured '
                      '${PointingDurationRecord.unmeasuredLabel}'}'
                  ' · médiane ${formatDuration(summary.medianMs)}'
                  ' · moyenne ${formatDuration(summary.meanMs)}'
                  ' · P90 ${formatDuration(summary.p90Ms)}',
                  style: PointageTextStyles.body2,
                ),
                const SizedBox(height: PointageSpacing.sm),
                Flexible(
                  child: PointingDurationRecordsTable(
                    records: records,
                    showPerson: showPerson,
                    showSite: showSite,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _RecordColumn {
  const _RecordColumn(this.label, this.value, this.cell,
      {this.numeric = true, this.tooltip});

  final String label;
  final Comparable<Object?>? Function(PointingDurationRecord r) value;
  final Widget Function(PointingDurationRecord r) cell;
  final bool numeric;
  final String? tooltip;
}

/// « mesuré » / « estimé (journal) » / « non mesuré ».
class _SourceBadge extends StatelessWidget {
  const _SourceBadge(this.record);

  final PointingDurationRecord record;

  @override
  Widget build(BuildContext context) {
    if (record.hasDuration && !record.estimated) {
      return const Text(PointingDurationRecord.measuredLabel,
          style: PointageTextStyles.caption);
    }
    final color =
        record.estimated ? _estimatedColor : PointageColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(record.sourceLabel,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

String _dateTime(DateTime? d) {
  if (d == null) return '—';
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
}

/// Sortable list of pointings with the breakdown of their duration.
class PointingDurationRecordsTable extends StatefulWidget {
  const PointingDurationRecordsTable({
    super.key,
    required this.records,
    this.showPerson = true,
    this.showSite = true,
  });

  final List<PointingDurationRecord> records;
  final bool showPerson;
  final bool showSite;

  @override
  State<PointingDurationRecordsTable> createState() =>
      _PointingDurationRecordsTableState();
}

class _PointingDurationRecordsTableState
    extends State<PointingDurationRecordsTable> {
  int _sortColumn = 0;
  bool _ascending = false;

  /// Breakdown column: « — » when the part is unknown or the pointing is
  /// « non mesuré ».
  static _RecordColumn _part(String label, int? Function(PointingDurationBreakdown d) read,
          {String? tooltip}) =>
      _RecordColumn(
          label,
          (r) => r.duration == null ? null : read(r.duration!),
          (r) => Text(
              formatDuration(r.duration == null ? null : read(r.duration!))),
          tooltip: tooltip);

  // Identification, total and source first: they stay visible on narrow
  // screens; the breakdown follows (horizontal scroll if needed).
  List<_RecordColumn> get _columns => [
        _RecordColumn('Date', (r) => r.date, (r) => Text(_dateTime(r.date)),
            numeric: false),
        if (widget.showPerson)
          _RecordColumn(
              'Personne',
              (r) => r.personName.toLowerCase(),
              (r) => Text('${r.personName}\n${GeoRole.label(r.role)}',
                  style: PointageTextStyles.body2),
              numeric: false),
        if (widget.showSite)
          _RecordColumn(
              'Site',
              (r) => r.siteLabel.toLowerCase(),
              (r) => ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Text(r.siteLabel, overflow: TextOverflow.ellipsis),
                  ),
              numeric: false),
        _RecordColumn(
            'Méthode',
            (r) => DurationMethodLabels.label(r.method),
            (r) => Text(DurationMethodLabels.label(r.method)),
            numeric: false),
        _RecordColumn(
            'Durée totale',
            (r) => r.totalMs,
            (r) => r.totalMs == null
                ? const _UnmeasuredText()
                : Text(formatDuration(r.totalMs),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: r.totalMs! > DurationSummary.slowThresholdMs
                          ? _slowColor
                          : null,
                    ))),
        _RecordColumn(
            'Source',
            (r) => r.sourceLabel,
            (r) => _SourceBadge(r),
            numeric: false,
            tooltip: 'mesuré : durée écrite par le téléphone · estimé '
                '(journal) : reconstituée depuis le journal des actions · '
                'non mesuré : aucune des deux'),
        _part('Attente GPS', (d) => d.gpsWaitMs),
        _part('1re position', (d) => d.firstFixMs,
            tooltip: 'Temps avant la première position GPS'),
        _part('Décision', (d) => d.decisionMs,
            tooltip: 'Bouton photo affiché → appuyé'),
        _part('Photo', (d) => d.photoMs,
            tooltip: 'Appareil photo ouvert → photo prise'),
        _part('Enreg.', (d) => d.saveMs,
            tooltip: 'Enregistrement du pointage'),
        _RecordColumn(
            'Relances',
            (r) => r.duration?.relaunches,
            (r) => Text(
                r.duration == null ? '—' : '${r.duration!.relaunches}')),
      ];

  @override
  Widget build(BuildContext context) {
    final columns = _columns;
    final sortColumn = _sortColumn.clamp(0, columns.length - 1);
    final value = columns[sortColumn].value;
    final records = List<PointingDurationRecord>.of(widget.records)
      ..sort((a, b) {
        final va = value(a);
        final vb = value(b);
        if (va == null || vb == null) return _compareNullable(va, vb);
        final result = va.compareTo(vb);
        return _ascending ? result : -result;
      });
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 52,
          horizontalMargin: 12,
          columnSpacing: 16,
          sortColumnIndex: sortColumn,
          sortAscending: _ascending,
          columns: [
            for (final column in columns)
              DataColumn(
                label: column.tooltip == null
                    ? Text(column.label)
                    : Tooltip(
                        message: column.tooltip!, child: Text(column.label)),
                numeric: column.numeric,
                onSort: (index, ascending) => setState(() {
                  _sortColumn = index;
                  _ascending = ascending;
                }),
              ),
          ],
          rows: [
            for (final record in records)
              DataRow(cells: [
                for (final column in columns) DataCell(column.cell(record)),
              ]),
          ],
        ),
      ),
    );
  }
}
