import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';
import 'package:spas_web/services/access_control.dart';
import 'package:spas_web/services/supervisor.dart';
import 'package:spas_web/services/zoneMember.dart';

import 'models/geo_stats.dart';
import 'models/mobile_event.dart';
import 'services/geo_tracking_service.dart';

/// "Suivi géolocalisation": per person / phone / app version stats of the
/// pointing methods, and the journal of mobile actions. Read only.
class GeoTrackingPage extends StatelessWidget {
  const GeoTrackingPage({super.key});

  static const int pageIndex = 23;

  @override
  Widget build(BuildContext context) {
    if (!AccessControl.canView(ModuleName.ERROR_LOG)) {
      return const PageModel(
        pageIndex: pageIndex,
        title: 'Suivi géolocalisation',
        child: Center(child: Text('Acces non autorise.')),
      );
    }
    return const PageModel(
      pageIndex: pageIndex,
      title: 'Suivi géolocalisation',
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Material(
              color: Colors.white,
              child: TabBar(
                labelColor: PointageColors.primary,
                unselectedLabelColor: PointageColors.textSecondary,
                indicatorColor: PointageColors.primary,
                tabs: [
                  Tab(icon: Icon(Icons.insights), text: 'Statistiques'),
                  Tab(
                      icon: Icon(Icons.list_alt),
                      text: 'Journal des actions mobiles'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [GeoStatsTab(), MobileEventsJournalTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DateTimeRange defaultGeoRange([DateTime? now]) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  return DateTimeRange(
    start: today.subtract(const Duration(days: 6)),
    end: today,
  );
}

String _formatDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

Future<DateTimeRange?> _pickRange(
    BuildContext context, DateTimeRange current) async {
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2024),
    lastDate: DateUtils.dateOnly(DateTime.now()),
    initialDateRange: current,
    helpText: 'Période (${GeoTrackingService.maxRangeDays} jours max)',
  );
  if (picked == null) return null;
  final days = picked.end.difference(picked.start).inDays + 1;
  if (days > GeoTrackingService.maxRangeDays) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Période trop longue : ${GeoTrackingService.maxRangeDays} jours maximum.'),
      ));
    }
    return null;
  }
  return picked;
}

class _RangeButton extends StatelessWidget {
  const _RangeButton({required this.range, required this.onChanged});

  final DateTimeRange range;
  final ValueChanged<DateTimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await _pickRange(context, range);
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.date_range, size: 18),
      label: Text('Du ${_formatDay(range.start)} au ${_formatDay(range.end)}'),
    );
  }
}

// ---------------------------------------------------------------------------
// Statistics tab
// ---------------------------------------------------------------------------

class GeoStatsTab extends StatefulWidget {
  const GeoStatsTab({super.key, this.loader});

  /// Injected in tests; defaults to [GeoTrackingService.loadStats].
  final Future<GeoStatsLoadResult> Function(DateTime start, DateTime end)?
      loader;

  @override
  State<GeoStatsTab> createState() => _GeoStatsTabState();
}

class _GeoStatsTabState extends State<GeoStatsTab>
    with AutomaticKeepAliveClientMixin {
  DateTimeRange _range = defaultGeoRange();
  late Future<GeoStatsLoadResult> _future = _load();

  @override
  bool get wantKeepAlive => true;

  Future<GeoStatsLoadResult> _load() {
    final start = _range.start;
    final end = _range.end.add(const Duration(days: 1));
    return widget.loader?.call(start, end) ??
        GeoTrackingService().loadStats(start, end);
  }

  void _reload() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<GeoStatsLoadResult>(
      future: _future,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.all(PointageSpacing.lg),
          children: [
            Wrap(
              spacing: PointageSpacing.sm,
              runSpacing: PointageSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _RangeButton(
                  range: _range,
                  onChanged: (range) {
                    _range = range;
                    _reload();
                  },
                ),
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: PointageSpacing.sm),
            const Text(
              'Taux de secours photo = pointages « Photo (GPS indisponible) » ÷ '
              '(pointages Géo + « Photo (GPS indisponible) »). Les pointages faits '
              'en mode Photo ne comptent pas. Les essais GPS échoués viennent des '
              'erreurs de pointage envoyées par les nouvelles versions de l\'app.',
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

  List<Widget> _buildReport(GeoStatsLoadResult result) {
    final report = result.report;
    final totals = report.totals;
    return [
      for (final collection in result.truncatedCollections)
        _Notice(
          'Période trop chargée : seuls les ${GeoTrackingService.maxDocsPerCollection} '
          'premiers documents de $collection sont comptés. Réduisez la période.',
        ),
      for (final warning in result.warnings) _Notice('Non chargé — $warning'),
      Wrap(
        spacing: PointageSpacing.sm,
        runSpacing: PointageSpacing.sm,
        children: [
          _Kpi('Pointages', '${totals.totalPointings}', PointageColors.primary),
          _Kpi('Géo', '${totals.geo}', const Color(0xFF15803D)),
          _Kpi('Photo', '${totals.photo}', const Color(0xFF475569)),
          _Kpi('Photo (GPS indisponible)', '${totals.photoFallback}',
              const Color(0xFFC2410C)),
          _Kpi('Taux de secours photo', formatRate(totals.fallbackRate),
              const Color(0xFFC2410C)),
          _Kpi('Essais GPS échoués', '${totals.failedAttempts}',
              PointageColors.error),
          if (totals.unknown > 0)
            _Kpi('Méthode inconnue', '${totals.unknown}',
                PointageColors.textSecondary),
        ],
      ),
      if (totals.failedAttempts > 0) ...[
        const SizedBox(height: PointageSpacing.sm),
        Text('Échecs : ${totals.failedSummary}',
            style: PointageTextStyles.body2),
      ],
      const SizedBox(height: PointageSpacing.lg),
      GeoStatsTable(
        title: 'Par personne',
        firstColumn: 'Personne',
        rows: report.byPerson,
        showRole: true,
      ),
      const SizedBox(height: PointageSpacing.lg),
      GeoStatsTable(
        title: 'Par modèle de téléphone',
        firstColumn: 'Modèle',
        rows: report.byDeviceModel,
      ),
      const SizedBox(height: PointageSpacing.lg),
      GeoStatsTable(
        title: 'Par version de l\'app',
        firstColumn: 'Version',
        rows: report.byAppVersion,
      ),
    ];
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PointageSpacing.sm),
      child: Text(text,
          style:
              PointageTextStyles.body2.copyWith(color: PointageColors.warning)),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: PointageTextStyles.headline4
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
          Text(label, style: PointageTextStyles.caption),
        ],
      ),
    );
  }
}

class GeoStatsTable extends StatelessWidget {
  const GeoStatsTable({
    super.key,
    required this.title,
    required this.firstColumn,
    required this.rows,
    this.showRole = false,
  });

  final String title;
  final String firstColumn;
  final List<GeoStatsRow> rows;
  final bool showRole;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PointageTextStyles.headline4),
          const SizedBox(height: PointageSpacing.sm),
          if (rows.isEmpty)
            const Text('Aucune donnée sur la période.',
                style: PointageTextStyles.caption)
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 56,
                columnSpacing: 22,
                columns: [
                  DataColumn(label: Text(firstColumn)),
                  if (showRole) const DataColumn(label: Text('Rôle')),
                  const DataColumn(label: Text('Géo'), numeric: true),
                  const DataColumn(label: Text('Photo'), numeric: true),
                  const DataColumn(
                      label: Text('Photo (GPS indisp.)'), numeric: true),
                  const DataColumn(
                      label: Tooltip(
                        message:
                            'Photo (GPS indisponible) ÷ (Géo + Photo (GPS indisponible))',
                        child: Text('Taux secours'),
                      ),
                      numeric: true),
                  const DataColumn(
                      label: Text('Essais échoués'), numeric: true),
                  const DataColumn(label: Text('Détail des échecs')),
                ],
                rows: [
                  for (final row in rows)
                    DataRow(cells: [
                      DataCell(Text(row.label)),
                      if (showRole) DataCell(Text(GeoRole.label(row.role))),
                      DataCell(Text('${row.geo}')),
                      DataCell(Text('${row.photo}')),
                      DataCell(Text('${row.photoFallback}')),
                      DataCell(Text(
                        formatRate(row.fallbackRate),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: (row.fallbackRate ?? 0) >= 0.3
                              ? PointageColors.error
                              : null,
                        ),
                      )),
                      DataCell(Text('${row.failedAttempts}')),
                      DataCell(ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text(
                          row.failedSummary.isEmpty ? '—' : row.failedSummary,
                          style: PointageTextStyles.caption,
                        ),
                      )),
                    ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile events journal tab
// ---------------------------------------------------------------------------

class _PersonOption {
  const _PersonOption(this.uid, this.label);

  final String uid;
  final String label;
}

class MobileEventsJournalTab extends StatefulWidget {
  const MobileEventsJournalTab({super.key});

  @override
  State<MobileEventsJournalTab> createState() => _MobileEventsJournalTabState();
}

class _MobileEventsJournalTabState extends State<MobileEventsJournalTab>
    with AutomaticKeepAliveClientMixin {
  final GeoTrackingService _service = GeoTrackingService();
  DateTimeRange _range = defaultGeoRange();
  String? _userId;
  String? _event;
  List<_PersonOption> _persons = const [];

  final List<MobileEvent> _events = [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDocument;
  bool _hasMore = false;
  bool _loading = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadPersons();
    _reload();
  }

  Future<void> _loadPersons() async {
    try {
      final results = await Future.wait([
        SupervisorService().allFuture(),
        ZoneMemberService().allActifAsModel(),
      ]);
      final supervisors = results[0] as List<Supervisor>;
      final chiefs = results[1] as List<ZoneMember>;
      final persons = <_PersonOption>[
        for (final s in supervisors)
          _PersonOption(s.UID, '${s.firstName} ${s.lastName} · Superviseur'),
        for (final z in chiefs)
          _PersonOption(z.UID, '${z.firstName} ${z.lastName} · Chef de zone'),
      ]..sort((a, b) => a.label.compareTo(b.label));
      if (mounted) setState(() => _persons = persons);
    } catch (_) {
      // The person filter stays empty; the journal itself still works.
    }
  }

  Future<void> _reload() async {
    setState(() {
      _events.clear();
      _lastDocument = null;
      _hasMore = false;
      _error = null;
    });
    await _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final page = await _service.loadEvents(
        start: _range.start,
        end: _range.end.add(const Duration(days: 1)),
        userId: _userId,
        event: _event,
        startAfter: _lastDocument,
      );
      if (!mounted) return;
      setState(() {
        _events.addAll(page.events);
        _lastDocument = page.lastDocument ?? _lastDocument;
        _hasMore = page.hasMore;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final eventOptions = <String>{
      ...MobileEventLabels.known.keys,
      if (_event != null) _event!,
    }.toList();
    return ListView(
      padding: const EdgeInsets.all(PointageSpacing.lg),
      children: [
        Wrap(
          spacing: PointageSpacing.sm,
          runSpacing: PointageSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _RangeButton(
              range: _range,
              onChanged: (range) {
                _range = range;
                _reload();
              },
            ),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<String?>(
                initialValue: _userId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Personne',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Toutes')),
                  for (final p in _persons)
                    DropdownMenuItem<String?>(
                      value: p.uid,
                      child: Text(p.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  _userId = value;
                  _reload();
                },
              ),
            ),
            SizedBox(
              width: 300,
              child: DropdownButtonFormField<String?>(
                initialValue: _event,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Action',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                      value: null, child: Text('Toutes')),
                  for (final e in eventOptions)
                    DropdownMenuItem<String?>(
                      value: e,
                      child: Text(MobileEventLabels.label(e),
                          overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  _event = value;
                  _reload();
                },
              ),
            ),
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _loading ? null : _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: PointageSpacing.md),
        if (_error != null)
          Text('Erreur de chargement : $_error',
              style: PointageTextStyles.body2
                  .copyWith(color: PointageColors.error)),
        if (_events.isEmpty && !_loading && _error == null)
          const Padding(
            padding: EdgeInsets.all(PointageSpacing.lg),
            child: Text('Aucune action enregistrée sur la période.',
                style: PointageTextStyles.caption),
          ),
        if (_events.isNotEmpty) MobileEventsTable(events: _events),
        const SizedBox(height: PointageSpacing.md),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_hasMore)
          Center(
            child: OutlinedButton.icon(
              onPressed: _loadMore,
              icon: const Icon(Icons.expand_more),
              label: const Text('Charger plus'),
            ),
          ),
      ],
    );
  }
}

class MobileEventsTable extends StatelessWidget {
  const MobileEventsTable({super.key, required this.events});

  final List<MobileEvent> events;

  static String _time(DateTime? d) {
    if (d == null) return '—';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${_formatDay(d)} ${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PointageCardDecorations.standard,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 60,
          columns: const [
            DataColumn(label: Text('Heure (téléphone)')),
            DataColumn(label: Text('Personne')),
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Site')),
            DataColumn(label: Text('Détails')),
            DataColumn(label: Text('Téléphone / app')),
          ],
          rows: [
            for (final e in events)
              DataRow(cells: [
                DataCell(Tooltip(
                  message: 'Reçu par le serveur : ${_time(e.timestamp)}',
                  child: Text(_time(e.time)),
                )),
                DataCell(Text(
                    '${e.userName ?? e.userCode ?? e.userId ?? '—'}\n${e.roleLabel}')),
                DataCell(Tooltip(
                  message: e.event,
                  child: Text(e.label),
                )),
                DataCell(Text(e.siteCode ?? e.siteId ?? '—')),
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Text(
                    [
                      if (e.isOnline == false) 'Hors ligne',
                      if (e.dataSummary.isNotEmpty) e.dataSummary,
                    ].join(' · '),
                    style: PointageTextStyles.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
                DataCell(Text(
                  [
                    if (e.device != null) e.device!.modelLabel,
                    if (e.appVersion != null) 'v${e.appVersion}',
                  ].join(' · '),
                  style: PointageTextStyles.caption,
                )),
              ]),
          ],
        ),
      ),
    );
  }
}
