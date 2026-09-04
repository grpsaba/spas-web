import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../administration/home.dart';
import '../../model.dart';
import '../models/monthly_pointing_sheet.dart';
import '../services/monthly_pointing_calculator.dart';
import '../services/monthly_pointing_sheet_exporter.dart';
import '../services/monthly_pointing_sheet_service.dart';
import 'pointing_control_ui.dart';

enum _DayListFilter { all, attention, compliant }

enum _ExportType { pdf, excel }

class MonthlyPointingSheetPage extends StatefulWidget {
  const MonthlyPointingSheetPage({
    super.key,
    required this.sheetId,
  });

  final String sheetId;

  @override
  State<MonthlyPointingSheetPage> createState() =>
      _MonthlyPointingSheetPageState();
}

class _MonthlyPointingSheetPageState extends State<MonthlyPointingSheetPage> {
  final MonthlyPointingSheetService _service = MonthlyPointingSheetService();
  final MonthlyPointingCalculator _calculator =
      const MonthlyPointingCalculator();
  final MonthlyPointingSheetExporter _exporter =
      const MonthlyPointingSheetExporter();

  _DayListFilter _filter = _DayListFilter.all;
  bool _exporting = false;

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 21,
      title: 'Fiche mensuelle de pointage',
      child: ColoredBox(
        color: PointingControlColors.background,
        child: StreamBuilder<MonthlyPointingSheet?>(
          stream: _service.watchSheet(widget.sheetId),
          builder: (context, sheetSnapshot) {
            if (sheetSnapshot.hasError) {
              return ControlError(
                message:
                    'Impossible de charger cette fiche. ${sheetSnapshot.error}',
                onRetry: () => setState(() {}),
              );
            }
            if (!sheetSnapshot.hasData) return const ControlLoading();

            final sheet = sheetSnapshot.data;
            if (sheet == null) {
              return ControlError(
                message:
                    'Cette fiche est introuvable ou n’est pas accessible dans votre périmètre.',
                onRetry: () => context.go('/pointages/controle'),
              );
            }

            return StreamBuilder<List<PointingSite>>(
              stream: _service.watchPointingsForSheet(sheet),
              builder: (context, pointingSnapshot) {
                if (pointingSnapshot.hasError) {
                  return ControlError(
                    message:
                        'La fiche est disponible, mais ses pointages n’ont pas pu être chargés. ${pointingSnapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }
                if (!pointingSnapshot.hasData) {
                  return const ControlLoading(
                    label: 'Vérification des pointages du mois…',
                  );
                }

                final summary = _calculator.calculate(
                  sheet: sheet,
                  pointings: pointingSnapshot.data!,
                );
                return _buildContent(sheet, summary);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    MonthlyPointingSheet sheet,
    MonthlyPointingSummary summary,
  ) {
    final filteredDays = summary.days.where((day) {
      switch (_filter) {
        case _DayListFilter.all:
          return true;
        case _DayListFilter.attention:
          return day.needsReason;
        case _DayListFilter.compliant:
          return day.state == DailyPointingState.compliant;
      }
    }).toList(growable: false);

    final completedDays = summary.days.where(_isCompletedDay).toList();
    final completedDayActual = completedDays.fold<int>(
      0,
      (total, day) => total + day.actualDay,
    );
    final completedNightActual = completedDays.fold<int>(
      0,
      (total, day) => total + day.actualNight,
    );

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(sheet, summary),
                const SizedBox(height: 16),
                _buildTrustNotice(),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 1120
                        ? (constraints.maxWidth - 36) / 4
                        : constraints.maxWidth >= 650
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: width,
                          child: _PeriodProgressTile(
                            label: 'Pointages de jour',
                            actual: completedDayActual,
                            expected: summary.expectedDayToDate,
                            dailyTarget: sheet.expectedDay,
                            icon: HugeIcons.strokeRoundedSun03,
                            color: PointingControlColors.day,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: _PeriodProgressTile(
                            label: 'Pointages de nuit',
                            actual: completedNightActual,
                            expected: summary.expectedNightToDate,
                            dailyTarget: sheet.expectedNight,
                            icon: HugeIcons.strokeRoundedMoon02,
                            color: PointingControlColors.night,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: ControlMetricTile(
                            label: 'Journées conformes',
                            value:
                                '${summary.compliantDays}/${summary.evaluatedDays}',
                            detail:
                                '${summary.complianceRate.round()}% sur les jours terminés',
                            icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                            color: PointingControlColors.success,
                          ),
                        ),
                        SizedBox(
                          width: width,
                          child: ControlMetricTile(
                            label: 'Motifs manquants',
                            value: summary.missingReasons.toString(),
                            detail:
                                '${summary.daysToExplain} journée(s) avec écart',
                            icon: HugeIcons.strokeRoundedAlertCircle,
                            color: summary.missingReasons == 0
                                ? PointingControlColors.success
                                : PointingControlColors.danger,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _buildListToolbar(summary, filteredDays.length),
                const SizedBox(height: 12),
                if (filteredDays.isEmpty)
                  _buildEmptyFilterState()
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 900) {
                        return _buildMobileDays(sheet, filteredDays);
                      }
                      return _buildDesktopDays(sheet, filteredDays);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    MonthlyPointingSheet sheet,
    MonthlyPointingSummary summary,
  ) {
    final identity = Row(
      children: [
        ControlAvatar(initials: sheet.initials, size: 48),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sheet.supervisorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PointingControlColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _HeaderInfo(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    label: PointingControlFormat.month(sheet.month),
                  ),
                  _HeaderInfo(
                    icon: HugeIcons.strokeRoundedMapsLocation01,
                    label: sheet.zoneName ?? 'Zone non renseignée',
                  ),
                  if (sheet.supervisorPhone.trim().isNotEmpty)
                    _HeaderInfo(
                      icon: HugeIcons.strokeRoundedUser,
                      label: sheet.supervisorPhone,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => context.go('/pointages/controle'),
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01, size: 18),
          label: const Text('Fiches'),
        ),
        OutlinedButton.icon(
          onPressed: () => _showHistory(sheet),
          icon: const Icon(HugeIcons.strokeRoundedClock03, size: 18),
          label: const Text('Historique'),
        ),
        OutlinedButton.icon(
          onPressed: () => _showTargetDialog(sheet),
          icon: const Icon(HugeIcons.strokeRoundedEdit02, size: 18),
          label: const Text('Objectifs'),
        ),
        PopupMenuButton<_ExportType>(
          enabled: !_exporting,
          tooltip: 'Exporter la fiche',
          onSelected: (type) => _export(type, sheet, summary),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: _ExportType.pdf,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(HugeIcons.strokeRoundedFile02, size: 19),
                title: Text('Exporter en PDF'),
              ),
            ),
            PopupMenuItem(
              value: _ExportType.excel,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(HugeIcons.strokeRoundedTable01, size: 19),
                title: Text('Exporter en Excel'),
              ),
            ),
          ],
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: PointingControlColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_exporting)
                  const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    HugeIcons.strokeRoundedFileExport,
                    size: 18,
                    color: Colors.white,
                  ),
                const SizedBox(width: 8),
                Text(
                  _exporting ? 'Export…' : 'Exporter',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 940) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 14),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 20),
              actions,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrustNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: PointingControlColors.infoSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC8E1F1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            HugeIcons.strokeRoundedInformationCircle,
            size: 19,
            color: PointingControlColors.info,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les valeurs réalisées proviennent directement des pointages et ne sont pas modifiables ici. Un même site compte une fois le jour et une fois la nuit au maximum. Les objectifs et motifs restent entièrement tracés.',
              style: TextStyle(
                color: Color(0xFF265D83),
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListToolbar(
    MonthlyPointingSummary summary,
    int visibleCount,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final filter = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_DayListFilter>(
              segments: [
                ButtonSegment(
                  value: _DayListFilter.all,
                  icon: const Icon(HugeIcons.strokeRoundedCalendar03, size: 17),
                  label: Text('Tous (${summary.days.length})'),
                ),
                ButtonSegment(
                  value: _DayListFilter.attention,
                  icon: const Icon(
                    HugeIcons.strokeRoundedAlertCircle,
                    size: 17,
                  ),
                  label: Text('Avec écart (${summary.daysToExplain})'),
                ),
                ButtonSegment(
                  value: _DayListFilter.compliant,
                  icon: const Icon(
                    HugeIcons.strokeRoundedCheckmarkCircle01,
                    size: 17,
                  ),
                  label: Text('Conformes (${summary.compliantDays})'),
                ),
              ],
              selected: <_DayListFilter>{_filter},
              showSelectedIcon: false,
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          );
          final count = Text(
            '$visibleCount journée(s) affichée(s)',
            style: const TextStyle(
              color: PointingControlColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
          if (constraints.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [filter, const SizedBox(height: 10), count],
            );
          }
          return Row(
            children: [
              Expanded(child: filter),
              const SizedBox(width: 12),
              count,
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopDays(
    MonthlyPointingSheet sheet,
    List<DailyPointingResult> days,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth =
              constraints.maxWidth < 1120 ? 1120.0 : constraints.maxWidth;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  const _DailyTableHeader(),
                  for (var index = 0; index < days.length; index++)
                    _DailyTableRow(
                      result: days[index],
                      showDivider: index != days.length - 1,
                      onEvidence: () => _showEvidence(days[index]),
                      onNote: days[index].state == DailyPointingState.future
                          ? null
                          : () => _showNoteDialog(sheet, days[index]),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileDays(
    MonthlyPointingSheet sheet,
    List<DailyPointingResult> days,
  ) {
    return Column(
      children: [
        for (var index = 0; index < days.length; index++) ...[
          _MobileDailyTile(
            result: days[index],
            onEvidence: () => _showEvidence(days[index]),
            onNote: days[index].state == DailyPointingState.future
                ? null
                : () => _showNoteDialog(sheet, days[index]),
          ),
          if (index != days.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }

  Widget _buildEmptyFilterState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            HugeIcons.strokeRoundedCheckmarkCircle01,
            size: 34,
            color: PointingControlColors.success,
          ),
          SizedBox(height: 10),
          Text(
            'Aucune journée dans cette vue',
            style: TextStyle(
              color: PointingControlColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Changez de filtre pour consulter les autres journées du mois.',
            textAlign: TextAlign.center,
            style: TextStyle(color: PointingControlColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  bool _isCompletedDay(DailyPointingResult day) {
    return day.state == DailyPointingState.compliant ||
        day.state == DailyPointingState.partial ||
        day.state == DailyPointingState.missing;
  }

  Future<void> _showTargetDialog(MonthlyPointingSheet sheet) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _EditTargetsDialog(
        sheet: sheet,
        service: _service,
      ),
    );
  }

  Future<void> _showNoteDialog(
    MonthlyPointingSheet sheet,
    DailyPointingResult result,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _EditNoteDialog(
        sheet: sheet,
        result: result,
        service: _service,
      ),
    );
  }

  Future<void> _showEvidence(DailyPointingResult result) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _EvidenceDialog(result: result),
    );
  }

  Future<void> _showHistory(MonthlyPointingSheet sheet) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _HistoryDialog(
        sheet: sheet,
        service: _service,
      ),
    );
  }

  Future<void> _export(
    _ExportType type,
    MonthlyPointingSheet sheet,
    MonthlyPointingSummary summary,
  ) async {
    setState(() => _exporting = true);
    try {
      switch (type) {
        case _ExportType.pdf:
          await _exporter.exportPdf(sheet: sheet, summary: summary);
          break;
        case _ExportType.excel:
          await _exporter.exportExcel(sheet: sheet, summary: summary);
          break;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            type == _ExportType.pdf
                ? 'Le rapport PDF a été généré.'
                : 'Le fichier Excel a été téléchargé.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PointingControlColors.danger,
          content: Text('L’export a échoué : $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}

class _HeaderInfo extends StatelessWidget {
  const _HeaderInfo({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: PointingControlColors.muted),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: PointingControlColors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PeriodProgressTile extends StatelessWidget {
  const _PeriodProgressTile({
    required this.label,
    required this.actual,
    required this.expected,
    required this.dailyTarget,
    required this.icon,
    required this.color,
  });

  final String label;
  final int actual;
  final int expected;
  final int dailyTarget;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final progress = expected == 0 ? 0.0 : (actual / expected).clamp(0.0, 1.0);
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$actual / $expected',
                      style: const TextStyle(
                        color: PointingControlColors.ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PointingControlColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              minHeight: 5,
              value: progress,
              color: color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Objectif quotidien : $dailyTarget · jours terminés uniquement',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PointingControlColors.muted,
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyTableHeader extends StatelessWidget {
  const _DailyTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFFF7F8FA),
      child: const Row(
        children: [
          SizedBox(width: 4),
          _HeaderCell(flex: 16, label: 'Date'),
          _HeaderCell(flex: 14, label: 'Jour'),
          _HeaderCell(flex: 14, label: 'Nuit'),
          _HeaderCell(flex: 9, label: 'Écart'),
          _HeaderCell(flex: 16, label: 'État'),
          _HeaderCell(flex: 27, label: 'Motif'),
          SizedBox(width: 88),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.flex, required this.label});

  final int flex;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: PointingControlColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _DailyTableRow extends StatelessWidget {
  const _DailyTableRow({
    required this.result,
    required this.showDivider,
    required this.onEvidence,
    required this.onNote,
  });

  final DailyPointingResult result;
  final bool showDivider;
  final VoidCallback onEvidence;
  final VoidCallback? onNote;

  @override
  Widget build(BuildContext context) {
    final visual = DailyStateVisual.fromResult(result);
    final hasEvidence =
        result.dayPointings.isNotEmpty || result.nightPointings.isNotEmpty;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: hasEvidence ? onEvidence : null,
        hoverColor: PointingControlColors.primarySoft.withValues(alpha: 0.7),
        child: Container(
          constraints: const BoxConstraints(minHeight: 70),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(color: PointingControlColors.border),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: visual.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                flex: 16,
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        PointingControlFormat.fullDate(result.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: result.state == DailyPointingState.future
                              ? PointingControlColors.muted
                              : PointingControlColors.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        PointingControlFormat.shortDate(result.date),
                        style: const TextStyle(
                          color: PointingControlColors.muted,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 14,
                child: _DailyTargetValue(
                  actual: result.actualDay,
                  expected: result.expectedDay,
                  color: PointingControlColors.day,
                  icon: HugeIcons.strokeRoundedSun03,
                ),
              ),
              Expanded(
                flex: 14,
                child: _DailyTargetValue(
                  actual: result.actualNight,
                  expected: result.expectedNight,
                  color: PointingControlColors.night,
                  icon: HugeIcons.strokeRoundedMoon02,
                ),
              ),
              Expanded(
                flex: 9,
                child: Text(
                  result.needsReason ? '-${result.totalDeficit}' : '—',
                  style: TextStyle(
                    color: result.needsReason
                        ? PointingControlColors.danger
                        : PointingControlColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                flex: 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ControlStatusBadge(visual: visual),
                ),
              ),
              Expanded(
                flex: 27,
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Text(
                    result.note?.displayText ??
                        (result.needsReason ? 'À renseigner' : '—'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: result.note != null
                          ? PointingControlColors.ink
                          : result.needsReason
                              ? PointingControlColors.danger
                              : PointingControlColors.muted,
                      fontSize: 11.5,
                      fontWeight: result.needsReason && result.note == null
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 88,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: hasEvidence
                          ? 'Voir les preuves'
                          : 'Aucun pointage enregistré',
                      onPressed: hasEvidence ? onEvidence : null,
                      icon: const Icon(HugeIcons.strokeRoundedView, size: 18),
                    ),
                    IconButton(
                      tooltip: result.note == null
                          ? 'Ajouter un motif'
                          : 'Modifier le motif',
                      onPressed: onNote,
                      icon: Icon(
                        HugeIcons.strokeRoundedNoteEdit,
                        size: 18,
                        color: result.needsReason && result.note == null
                            ? PointingControlColors.danger
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTargetValue extends StatelessWidget {
  const _DailyTargetValue({
    required this.actual,
    required this.expected,
    required this.color,
    required this.icon,
  });

  final int actual;
  final int expected;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final reached = actual >= expected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              '$actual / $expected',
              style: TextStyle(
                color: reached
                    ? PointingControlColors.success
                    : PointingControlColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 74,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: expected == 0 ? 0 : (actual / expected).clamp(0.0, 1.0),
              color: reached ? PointingControlColors.success : color,
              backgroundColor: color.withValues(alpha: 0.12),
            ),
          ),
        ),
      ],
    );
  }
}

class _MobileDailyTile extends StatelessWidget {
  const _MobileDailyTile({
    required this.result,
    required this.onEvidence,
    required this.onNote,
  });

  final DailyPointingResult result;
  final VoidCallback onEvidence;
  final VoidCallback? onNote;

  @override
  Widget build(BuildContext context) {
    final visual = DailyStateVisual.fromResult(result);
    final hasEvidence =
        result.dayPointings.isNotEmpty || result.nightPointings.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 38,
                decoration: BoxDecoration(
                  color: visual.color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      PointingControlFormat.fullDate(result.date),
                      style: const TextStyle(
                        color: PointingControlColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      PointingControlFormat.shortDate(result.date),
                      style: const TextStyle(
                        color: PointingControlColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              ControlStatusBadge(visual: visual),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MobilePeriodValue(
                  label: 'Jour',
                  actual: result.actualDay,
                  expected: result.expectedDay,
                  icon: HugeIcons.strokeRoundedSun03,
                  color: PointingControlColors.day,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MobilePeriodValue(
                  label: 'Nuit',
                  actual: result.actualNight,
                  expected: result.expectedNight,
                  icon: HugeIcons.strokeRoundedMoon02,
                  color: PointingControlColors.night,
                ),
              ),
            ],
          ),
          if (result.note != null || result.needsReason) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: result.note == null
                    ? PointingControlColors.dangerSoft
                    : PointingControlColors.warningSoft,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    HugeIcons.strokeRoundedNoteEdit,
                    size: 17,
                    color: result.note == null
                        ? PointingControlColors.danger
                        : PointingControlColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.note?.displayText ?? 'Motif à renseigner',
                      style: const TextStyle(
                        color: PointingControlColors.ink,
                        fontSize: 11.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: hasEvidence ? onEvidence : null,
                icon: const Icon(HugeIcons.strokeRoundedView, size: 17),
                label: Text(hasEvidence ? 'Preuves' : 'Aucune preuve'),
              ),
              const SizedBox(width: 6),
              TextButton.icon(
                onPressed: onNote,
                icon: const Icon(HugeIcons.strokeRoundedNoteEdit, size: 17),
                label: Text(result.note == null ? 'Motif' : 'Modifier'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MobilePeriodValue extends StatelessWidget {
  const _MobilePeriodValue({
    required this.label,
    required this.actual,
    required this.expected,
    required this.icon,
    required this.color,
  });

  final String label;
  final int actual;
  final int expected;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: PointingControlColors.muted,
                  fontSize: 10.5,
                ),
              ),
              Text(
                '$actual / $expected',
                style: const TextStyle(
                  color: PointingControlColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditTargetsDialog extends StatefulWidget {
  const _EditTargetsDialog({
    required this.sheet,
    required this.service,
  });

  final MonthlyPointingSheet sheet;
  final MonthlyPointingSheetService service;

  @override
  State<_EditTargetsDialog> createState() => _EditTargetsDialogState();
}

class _EditTargetsDialogState extends State<_EditTargetsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _dayController;
  late final TextEditingController _nightController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _dayController = TextEditingController(
      text: widget.sheet.expectedDay.toString(),
    );
    _nightController = TextEditingController(
      text: widget.sheet.expectedNight.toString(),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _nightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogTitle(
                  icon: HugeIcons.strokeRoundedEdit02,
                  title: 'Objectifs quotidiens',
                  subtitle:
                      '${widget.sheet.supervisorName} · ${PointingControlFormat.month(widget.sheet.month)}',
                  onClose: _saving ? null : () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ces valeurs s’appliquent à chaque journée du mois. La modification sera ajoutée à l’historique.',
                  style: TextStyle(
                    color: PointingControlColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final day = _numberField(
                      controller: _dayController,
                      label: 'Objectif jour',
                      icon: HugeIcons.strokeRoundedSun03,
                      color: PointingControlColors.day,
                    );
                    final night = _numberField(
                      controller: _nightController,
                      label: 'Objectif nuit',
                      icon: HugeIcons.strokeRoundedMoon02,
                      color: PointingControlColors.night,
                    );
                    if (constraints.maxWidth < 430) {
                      return Column(
                        children: [day, const SizedBox(height: 12), night],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: day),
                        const SizedBox(width: 12),
                        Expanded(child: night),
                      ],
                    );
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: PointingControlColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              HugeIcons.strokeRoundedCheckmarkCircle01,
                              size: 18,
                            ),
                      label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      keyboardType: TextInputType.number,
      decoration: _fieldDecoration(label, icon, color),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        if (number == null || number < 0) return 'Valeur invalide';
        return null;
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.updateTargets(
        sheet: widget.sheet,
        expectedDay: int.parse(_dayController.text.trim()),
        expectedNight: int.parse(_nightController.text.trim()),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'La modification n’a pas pu être enregistrée : $error';
      });
    }
  }
}

class _EditNoteDialog extends StatefulWidget {
  const _EditNoteDialog({
    required this.sheet,
    required this.result,
    required this.service,
  });

  final MonthlyPointingSheet sheet;
  final DailyPointingResult result;
  final MonthlyPointingSheetService service;

  @override
  State<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends State<_EditNoteDialog> {
  static const _defaultCategories = <String>[
    'Congé ou absence',
    'Maladie',
    'Mission ou affectation',
    'Incident opérationnel',
    'Problème technique',
    'Site inaccessible',
    'Autre',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _detailsController;
  late final List<String> _categories;
  String? _category;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final existing = widget.result.note;
    _category = existing?.category.trim();
    _categories = <String>[
      ..._defaultCategories,
      if (_category != null &&
          _category!.isNotEmpty &&
          !_defaultCategories.contains(_category))
        _category!,
    ];
    _detailsController = TextEditingController(text: existing?.details ?? '');
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DialogTitle(
                  icon: HugeIcons.strokeRoundedNoteEdit,
                  title: result.note == null
                      ? 'Renseigner le motif'
                      : 'Modifier le motif',
                  subtitle: PointingControlFormat.fullDate(result.date),
                  onClose: _saving ? null : () => Navigator.pop(context),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: PointingControlColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _CompactCount(
                          label: 'Jour',
                          value: '${result.actualDay}/${result.expectedDay}',
                          color: PointingControlColors.day,
                          icon: HugeIcons.strokeRoundedSun03,
                        ),
                      ),
                      Expanded(
                        child: _CompactCount(
                          label: 'Nuit',
                          value:
                              '${result.actualNight}/${result.expectedNight}',
                          color: PointingControlColors.night,
                          icon: HugeIcons.strokeRoundedMoon02,
                        ),
                      ),
                      Expanded(
                        child: _CompactCount(
                          label: 'Écart',
                          value: result.totalDeficit.toString(),
                          color: result.totalDeficit == 0
                              ? PointingControlColors.success
                              : PointingControlColors.danger,
                          icon: HugeIcons.strokeRoundedAlertCircle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _category?.isEmpty == true ? null : _category,
                  isExpanded: true,
                  decoration: _fieldDecoration(
                    'Catégorie du motif',
                    HugeIcons.strokeRoundedNoteEdit,
                    PointingControlColors.primary,
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _category = value),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Sélectionnez une catégorie.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _detailsController,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 5,
                  decoration: _fieldDecoration(
                    'Précisions',
                    HugeIcons.strokeRoundedEdit02,
                    PointingControlColors.primary,
                  ).copyWith(
                    hintText: 'Ajoutez les informations utiles au contrôle…',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (_category == 'Autre' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Précisez ce motif.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Le nom de l’utilisateur et la date de modification seront enregistrés automatiquement.',
                  style: TextStyle(
                    color: PointingControlColors.muted,
                    fontSize: 11,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: PointingControlColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (result.note != null)
                      TextButton.icon(
                        onPressed: _saving ? null : _remove,
                        style: TextButton.styleFrom(
                          foregroundColor: PointingControlColors.danger,
                        ),
                        icon: const Icon(
                          HugeIcons.strokeRoundedDelete02,
                          size: 17,
                        ),
                        label: const Text('Supprimer'),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              HugeIcons.strokeRoundedCheckmarkCircle01,
                              size: 18,
                            ),
                      label: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.saveNote(
        sheet: widget.sheet,
        date: widget.result.date,
        category: _category!,
        details: _detailsController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Le motif n’a pas pu être enregistré : $error';
      });
    }
  }

  Future<void> _remove() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.service.removeNote(
        sheet: widget.sheet,
        date: widget.result.date,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Le motif n’a pas pu être supprimé : $error';
      });
    }
  }
}

class _CompactCount extends StatelessWidget {
  const _CompactCount({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: PointingControlColors.ink,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: PointingControlColors.muted,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PointingControlColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: PointingControlColors.primary, size: 21),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: PointingControlColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PointingControlColors.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Fermer',
          onPressed: onClose,
          icon: const Icon(HugeIcons.strokeRoundedCancel01),
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(
  String label,
  IconData icon,
  Color color,
) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 19, color: color),
    filled: true,
    fillColor: const Color(0xFFF9FAFB),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: PointingControlColors.border),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
  );
}

class _EvidenceDialog extends StatelessWidget {
  const _EvidenceDialog({required this.result});

  final DailyPointingResult result;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 760),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
              child: _DialogTitle(
                icon: HugeIcons.strokeRoundedView,
                title: 'Preuves de pointage',
                subtitle: PointingControlFormat.fullDate(result.date),
                onClose: () => Navigator.pop(context),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EvidencePeriod(
                      label: 'Jour · 00h00 à 17h59',
                      icon: HugeIcons.strokeRoundedSun03,
                      color: PointingControlColors.day,
                      pointings: result.dayPointings,
                    ),
                    const SizedBox(height: 18),
                    _EvidencePeriod(
                      label: 'Nuit · 18h00 à 23h59',
                      icon: HugeIcons.strokeRoundedMoon02,
                      color: PointingControlColors.night,
                      pointings: result.nightPointings,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidencePeriod extends StatelessWidget {
  const _EvidencePeriod({
    required this.label,
    required this.icon,
    required this.color,
    required this.pointings,
  });

  final String label;
  final IconData icon;
  final Color color;
  final List<PointingSite> pointings;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<PointingSite>>{};
    for (final pointing in pointings) {
      final uid = pointing.site.UID.trim();
      final code = pointing.site.codeSite.trim().toLowerCase();
      final name = pointing.site.name.trim().toLowerCase();
      final key = uid.isNotEmpty
          ? 'uid:$uid'
          : code.isNotEmpty
              ? 'code:$code'
              : 'name:$name';
      groups.putIfAbsent(key, () => <PointingSite>[]).add(pointing);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: PointingControlColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Flexible(
              child: Text(
                '${groups.length} site(s) distinct(s) · ${pointings.length} passage(s)',
                maxLines: 2,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: PointingControlColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (groups.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: PointingControlColors.border),
            ),
            child: const Text(
              'Aucun pointage enregistré sur cette période.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PointingControlColors.muted,
                fontSize: 12,
              ),
            ),
          )
        else
          for (final group in groups.values) ...[
            _EvidenceSiteTile(pointings: group, color: color),
            if (group != groups.values.last) const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _EvidenceSiteTile extends StatelessWidget {
  const _EvidenceSiteTile({
    required this.pointings,
    required this.color,
  });

  final List<PointingSite> pointings;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sorted = pointings.toList()..sort((a, b) => a.date.compareTo(b.date));
    final site = sorted.first.site;
    String? photoUrl;
    for (final pointing in sorted) {
      final candidate = pointing.agentPhotoUrl?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        photoUrl = candidate;
        break;
      }
    }
    final imageUrl = photoUrl;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              HugeIcons.strokeRoundedBuilding03,
              size: 19,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.name.isEmpty ? 'Site sans nom' : site.name,
                  style: const TextStyle(
                    color: PointingControlColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (site.codeSite.trim().isNotEmpty)
                  Text(
                    site.codeSite,
                    style: const TextStyle(
                      color: PointingControlColors.muted,
                      fontSize: 10.5,
                    ),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final pointing in sorted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6F8),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${PointingControlFormat.time(pointing.date)} · ${pointing.distance.isFinite ? pointing.distance.round() : 0} m',
                          style: const TextStyle(
                            color: PointingControlColors.ink,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (imageUrl != null) ...[
            const SizedBox(width: 10),
            Tooltip(
              message: 'Agrandir la photo',
              child: InkWell(
                onTap: () => _showPhoto(context, imageUrl),
                borderRadius: BorderRadius.circular(7),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: Image.network(
                    imageUrl,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      color: const Color(0xFFF1F3F6),
                      child: const Icon(
                        HugeIcons.strokeRoundedImage02,
                        size: 20,
                        color: PointingControlColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPhoto(BuildContext context, String url) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                maxHeight: MediaQuery.sizeOf(context).height * 0.85,
              ),
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filled(
                tooltip: 'Fermer',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(HugeIcons.strokeRoundedCancel01),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryDialog extends StatelessWidget {
  const _HistoryDialog({
    required this.sheet,
    required this.service,
  });

  final MonthlyPointingSheet sheet;
  final MonthlyPointingSheetService service;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
              child: _DialogTitle(
                icon: HugeIcons.strokeRoundedClock03,
                title: 'Historique de la fiche',
                subtitle:
                    '${sheet.supervisorName} · ${PointingControlFormat.month(sheet.month)}',
                onClose: () => Navigator.pop(context),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<PointingSheetAuditEntry>>(
                stream: service.watchAudit(sheet.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return ControlError(
                      message:
                          'Impossible de charger l’historique. ${snapshot.error}',
                    );
                  }
                  if (!snapshot.hasData) return const ControlLoading();
                  final entries = snapshot.data!;
                  if (entries.isEmpty) {
                    return const Center(
                      child: Text(
                        'Aucune modification enregistrée.',
                        style: TextStyle(
                          color: PointingControlColors.muted,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _HistoryEntryTile(entry: entries[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({required this.entry});

  final PointingSheetAuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final visual = _auditVisual(entry.action);
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: visual.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(visual.icon, color: visual.color, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visual.label,
                  style: const TextStyle(
                    color: PointingControlColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _auditChange(entry),
                  style: const TextStyle(
                    color: PointingControlColors.muted,
                    fontSize: 11.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${entry.actor.name} · ${PointingControlFormat.dateTime(entry.createdAt)}',
                  style: TextStyle(
                    color: visual.color,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _AuditVisual _auditVisual(String action) {
    switch (action) {
      case 'created':
        return const _AuditVisual(
          label: 'Fiche créée',
          icon: HugeIcons.strokeRoundedFile02,
          color: PointingControlColors.primary,
        );
      case 'targets_updated':
        return const _AuditVisual(
          label: 'Objectifs modifiés',
          icon: HugeIcons.strokeRoundedEdit02,
          color: PointingControlColors.info,
        );
      case 'note_removed':
        return const _AuditVisual(
          label: 'Motif supprimé',
          icon: HugeIcons.strokeRoundedDelete02,
          color: PointingControlColors.danger,
        );
      case 'note_updated':
        return const _AuditVisual(
          label: 'Motif enregistré',
          icon: HugeIcons.strokeRoundedNoteEdit,
          color: PointingControlColors.warning,
        );
      default:
        return const _AuditVisual(
          label: 'Fiche modifiée',
          icon: HugeIcons.strokeRoundedEdit02,
          color: PointingControlColors.muted,
        );
    }
  }

  String _auditChange(PointingSheetAuditEntry entry) {
    if (entry.action == 'created') {
      final day = _changeAfter(entry.changes['expectedDay']);
      final night = _changeAfter(entry.changes['expectedNight']);
      return 'Objectifs initiaux : $day le jour et $night la nuit.';
    }
    if (entry.action == 'targets_updated') {
      final day = _changePair(entry.changes['expectedDay']);
      final night = _changePair(entry.changes['expectedNight']);
      return 'Jour : $day · Nuit : $night.';
    }
    if (entry.action == 'note_updated' || entry.action == 'note_removed') {
      final date = _dayKeyLabel(entry.dayKey);
      final note = _changePair(entry.changes['note']);
      return '$date · $note';
    }
    return 'Les informations de la fiche ont été mises à jour.';
  }

  String _changeAfter(Object? raw) {
    if (raw is Map) return raw['after']?.toString() ?? '0';
    return raw?.toString() ?? '0';
  }

  String _changePair(Object? raw) {
    if (raw is! Map) return raw?.toString() ?? '—';
    final before = raw['before']?.toString() ?? 'vide';
    final after = raw['after']?.toString() ?? 'supprimé';
    return '$before → $after';
  }

  String _dayKeyLabel(String? value) {
    if (value == null) return 'Journée non précisée';
    final parts = value.split('-');
    if (parts.length != 3) return value;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

class _AuditVisual {
  const _AuditVisual({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}
