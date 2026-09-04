import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../administration/home.dart';
import '../../model.dart';
import '../../services/site.dart';
import '../../services/supervisor.dart';
import '../models/monthly_pointing_sheet.dart';
import '../services/monthly_pointing_calculator.dart';
import '../services/monthly_pointing_sheet_service.dart';
import 'pointing_control_ui.dart';

class MonthlyPointingControlPage extends StatefulWidget {
  const MonthlyPointingControlPage({super.key});

  @override
  State<MonthlyPointingControlPage> createState() =>
      _MonthlyPointingControlPageState();
}

class _MonthlyPointingControlPageState
    extends State<MonthlyPointingControlPage> {
  final MonthlyPointingSheetService _service = MonthlyPointingSheetService();
  final MonthlyPointingCalculator _calculator =
      const MonthlyPointingCalculator();
  final TextEditingController _searchController = TextEditingController();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _search = '';
  String? _selectedZone;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 21,
      title: 'Contrôle mensuel des pointages',
      child: ColoredBox(
        color: PointingControlColors.background,
        child: StreamBuilder<List<MonthlyPointingSheet>>(
          stream: _service.watchMonth(_selectedMonth),
          builder: (context, sheetSnapshot) {
            if (sheetSnapshot.hasError) {
              return ControlError(
                message:
                    'Impossible de charger les fiches mensuelles. ${sheetSnapshot.error}',
                onRetry: () => setState(() {}),
              );
            }
            if (!sheetSnapshot.hasData) return const ControlLoading();

            return StreamBuilder<List<PointingSite>>(
              stream: _service.watchPointingsForMonth(_selectedMonth),
              builder: (context, pointingSnapshot) {
                if (pointingSnapshot.hasError) {
                  return ControlError(
                    message:
                        'Les fiches sont disponibles, mais les pointages du mois n’ont pas pu être chargés. ${pointingSnapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }
                if (!pointingSnapshot.hasData) {
                  return const ControlLoading(
                    label: 'Calcul des pointages du mois…',
                  );
                }

                return _buildContent(
                  sheets: sheetSnapshot.data!,
                  pointings: pointingSnapshot.data!,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent({
    required List<MonthlyPointingSheet> sheets,
    required List<PointingSite> pointings,
  }) {
    final summaries = <String, MonthlyPointingSummary>{
      for (final sheet in sheets)
        sheet.id: _calculator.calculate(sheet: sheet, pointings: pointings),
    };
    final zones = sheets
        .map((sheet) => sheet.zoneName?.trim() ?? '')
        .where((zone) => zone.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final filteredSheets = sheets.where((sheet) {
      final query = _search.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          sheet.supervisorName.toLowerCase().contains(query) ||
          sheet.supervisorPhone.toLowerCase().contains(query) ||
          (sheet.zoneName ?? '').toLowerCase().contains(query);
      final matchesZone =
          _selectedZone == null || sheet.zoneName == _selectedZone;
      return matchesSearch && matchesZone;
    }).toList(growable: false);

    final allSummaries = summaries.values.toList(growable: false);
    final evaluatedDays = allSummaries.fold<int>(
      0,
      (total, summary) => total + summary.evaluatedDays,
    );
    final compliantDays = allSummaries.fold<int>(
      0,
      (total, summary) => total + summary.compliantDays,
    );
    final daysToExplain = allSummaries.fold<int>(
      0,
      (total, summary) => total + summary.daysToExplain,
    );
    final missingReasons = allSummaries.fold<int>(
      0,
      (total, summary) => total + summary.missingReasons,
    );
    final complianceRate =
        evaluatedDays == 0 ? 0.0 : compliantDays * 100 / evaluatedDays;

    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPageHeader(),
                const SizedBox(height: 18),
                _buildTrustNotice(),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth >= 1100
                        ? (constraints.maxWidth - 36) / 4
                        : constraints.maxWidth >= 620
                            ? (constraints.maxWidth - 12) / 2
                            : constraints.maxWidth;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: itemWidth,
                          child: ControlMetricTile(
                            label: 'Fiches créées',
                            value: sheets.length.toString(),
                            detail: '${filteredSheets.length} affichée(s)',
                            icon: HugeIcons.strokeRoundedFile02,
                            color: PointingControlColors.primary,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: ControlMetricTile(
                            label: 'Journées conformes',
                            value: compliantDays.toString(),
                            detail: '$evaluatedDays journée(s) contrôlée(s)',
                            icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                            color: PointingControlColors.success,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: ControlMetricTile(
                            label: 'Journées avec écart',
                            value: daysToExplain.toString(),
                            detail: '$missingReasons motif(s) manquant(s)',
                            icon: HugeIcons.strokeRoundedAlertCircle,
                            color: missingReasons == 0
                                ? PointingControlColors.warning
                                : PointingControlColors.danger,
                          ),
                        ),
                        SizedBox(
                          width: itemWidth,
                          child: ControlMetricTile(
                            label: 'Taux de conformité',
                            value: '${complianceRate.round()}%',
                            detail: evaluatedDays == 0
                                ? 'Aucune journée terminée'
                                : 'Calculé sur les jours terminés',
                            icon: HugeIcons.strokeRoundedChartEvaluation,
                            color: complianceRate >= 80
                                ? PointingControlColors.success
                                : PointingControlColors.info,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                _buildFilters(zones, filteredSheets.length),
                const SizedBox(height: 12),
                if (sheets.isEmpty)
                  _buildEmptyState()
                else if (filteredSheets.isEmpty)
                  _buildNoResultState()
                else
                  _buildSheets(filteredSheets, summaries),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suivi des fiches superviseurs',
              style: TextStyle(
                color: PointingControlColors.ink,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Les résultats sont recalculés automatiquement depuis les pointages enregistrés.',
              style: TextStyle(
                color: PointingControlColors.muted,
                fontSize: constraints.maxWidth < 600 ? 12 : 13,
              ),
            ),
          ],
        );
        final actions = Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MonthSelector(
              month: _selectedMonth,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onPick: _pickMonth,
            ),
            ElevatedButton.icon(
              onPressed: _openCreateDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: PointingControlColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(156, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(
                HugeIcons.strokeRoundedCalendarAdd01,
                size: 19,
              ),
              label: const Text(
                'Nouvelle fiche',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );

        if (constraints.maxWidth < 820) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              const SizedBox(height: 14),
              actions,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 20),
            actions,
          ],
        );
      },
    );
  }

  Widget _buildTrustNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: PointingControlColors.infoSoft,
        border: Border.all(color: const Color(0xFFC8E1F1)),
        borderRadius: BorderRadius.circular(8),
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
              'Un site compte une seule fois par période : jour de 00h00 à 17h59, nuit de 18h00 à 23h59. Les objectifs et motifs restent modifiables et chaque changement est tracé.',
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

  Widget _buildFilters(List<String> zones, int resultCount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final search = SizedBox(
            width: constraints.maxWidth < 700 ? constraints.maxWidth : 340,
            height: 42,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: 'Rechercher un superviseur…',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(
                  HugeIcons.strokeRoundedSearch01,
                  size: 18,
                ),
                suffixIcon: _search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer la recherche',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _search = '');
                        },
                        icon: const Icon(
                          HugeIcons.strokeRoundedCancel01,
                          size: 17,
                        ),
                      ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: PointingControlColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: PointingControlColors.border,
                  ),
                ),
              ),
            ),
          );
          final zone = SizedBox(
            width: constraints.maxWidth < 700 ? constraints.maxWidth : 230,
            height: 42,
            child: DropdownButtonFormField<String?>(
              key: ValueKey(_selectedZone),
              initialValue: _selectedZone,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  HugeIcons.strokeRoundedMapsCircle01,
                  size: 18,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: PointingControlColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: PointingControlColors.border,
                  ),
                ),
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Toutes les zones'),
                ),
                ...zones.map(
                  (zone) => DropdownMenuItem<String?>(
                    value: zone,
                    child: Text(zone, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _selectedZone = value),
            ),
          );

          return Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              search,
              zone,
              Text(
                '$resultCount résultat(s)',
                style: const TextStyle(
                  color: PointingControlColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSheets(
    List<MonthlyPointingSheet> sheets,
    Map<String, MonthlyPointingSummary> summaries,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            children: sheets
                .map(
                  (sheet) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MobileSheetTile(
                      sheet: sheet,
                      summary: summaries[sheet.id]!,
                      onTap: () => _openSheet(sheet.id),
                    ),
                  ),
                )
                .toList(growable: false),
          );
        }
        return _DesktopSheetTable(
          sheets: sheets,
          summaries: summaries,
          onOpen: _openSheet,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 54),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: PointingControlColors.primarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              HugeIcons.strokeRoundedFileAdd,
              color: PointingControlColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune fiche pour ${PointingControlFormat.month(_selectedMonth)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PointingControlColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Créez la première fiche, renseignez les objectifs quotidiens et le système chargera automatiquement les pointages.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: PointingControlColors.muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _openCreateDialog,
            icon: const Icon(HugeIcons.strokeRoundedAdd01, size: 18),
            label: const Text('Créer une fiche'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultState() {
    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: PointingControlColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: [
          Icon(
            HugeIcons.strokeRoundedSearch01,
            color: PointingControlColors.muted,
            size: 28,
          ),
          SizedBox(height: 10),
          Text(
            'Aucune fiche ne correspond aux filtres.',
            style: TextStyle(
              color: PointingControlColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + delta);
      _selectedZone = null;
    });
  }

  Future<void> _pickMonth() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Choisir le mois',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedMonth = DateTime(selected.year, selected.month);
      _selectedZone = null;
    });
  }

  Future<void> _openCreateDialog() async {
    final sheetId = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CreateSheetDialog(
        month: _selectedMonth,
        service: _service,
      ),
    );
    if (sheetId != null && mounted) _openSheet(sheetId);
  }

  void _openSheet(String sheetId) {
    context.go('/pointages/controle/$sheetId');
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onPick,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Mois précédent',
            onPressed: onPrevious,
            icon: const Icon(HugeIcons.strokeRoundedArrowLeft01, size: 18),
          ),
          InkWell(
            onTap: onPick,
            child: SizedBox(
              width: 142,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    HugeIcons.strokeRoundedCalendar03,
                    size: 17,
                    color: PointingControlColors.primary,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      PointingControlFormat.month(month),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PointingControlColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Mois suivant',
            onPressed: onNext,
            icon: const Icon(HugeIcons.strokeRoundedArrowRight01, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DesktopSheetTable extends StatelessWidget {
  const _DesktopSheetTable({
    required this.sheets,
    required this.summaries,
    required this.onOpen,
  });

  final List<MonthlyPointingSheet> sheets;
  final Map<String, MonthlyPointingSummary> summaries;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _SheetTableRow(header: true),
          ...sheets.asMap().entries.map((entry) {
            final sheet = entry.value;
            return _SheetTableRow(
              sheet: sheet,
              summary: summaries[sheet.id],
              shaded: entry.key.isOdd,
              onTap: () => onOpen(sheet.id),
            );
          }),
        ],
      ),
    );
  }
}

class _SheetTableRow extends StatefulWidget {
  const _SheetTableRow({
    this.header = false,
    this.sheet,
    this.summary,
    this.shaded = false,
    this.onTap,
  });

  final bool header;
  final MonthlyPointingSheet? sheet;
  final MonthlyPointingSummary? summary;
  final bool shaded;
  final VoidCallback? onTap;

  @override
  State<_SheetTableRow> createState() => _SheetTableRowState();
}

class _SheetTableRowState extends State<_SheetTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sheet = widget.sheet;
    final summary = widget.summary;
    final background = widget.header
        ? const Color(0xFFF1F3F7)
        : _hovered
            ? const Color(0xFFF4F6FC)
            : widget.shaded
                ? const Color(0xFFFBFCFD)
                : Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: background,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            constraints: BoxConstraints(minHeight: widget.header ? 46 : 66),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: PointingControlColors.border),
              ),
            ),
            child: Row(
              children: [
                _tableCell(
                  flex: 28,
                  child: widget.header
                      ? _headerText('Superviseur')
                      : Row(
                          children: [
                            ControlAvatar(initials: sheet!.initials, size: 38),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    sheet.supervisorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: PointingControlColors.ink,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (sheet.supervisorPhone.isNotEmpty)
                                    Text(
                                      sheet.supervisorPhone,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: PointingControlColors.muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
                _tableCell(
                  flex: 16,
                  child: widget.header
                      ? _headerText('Zone')
                      : Text(
                          sheet!.zoneName ?? 'Non renseignée',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: PointingControlColors.muted,
                            fontSize: 12,
                          ),
                        ),
                ),
                _tableCell(
                  flex: 10,
                  child: widget.header
                      ? _headerText('Objectif J')
                      : _targetValue(
                          sheet!.expectedDay,
                          PointingControlColors.day,
                        ),
                ),
                _tableCell(
                  flex: 10,
                  child: widget.header
                      ? _headerText('Objectif N')
                      : _targetValue(
                          sheet!.expectedNight,
                          PointingControlColors.night,
                        ),
                ),
                _tableCell(
                  flex: 11,
                  child: widget.header
                      ? _headerText('Réalisé J')
                      : _strongValue(summary!.actualDayTotal.toString()),
                ),
                _tableCell(
                  flex: 11,
                  child: widget.header
                      ? _headerText('Réalisé N')
                      : _strongValue(summary!.actualNightTotal.toString()),
                ),
                _tableCell(
                  flex: 13,
                  child: widget.header
                      ? _headerText('Conformes')
                      : Text(
                          '${summary!.compliantDays}/${summary.evaluatedDays}',
                          style: const TextStyle(
                            color: PointingControlColors.success,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                _tableCell(
                  flex: 14,
                  child: widget.header
                      ? _headerText('À justifier')
                      : _attentionValue(summary!.missingReasons),
                ),
                _tableCell(
                  flex: 20,
                  child: widget.header
                      ? _headerText('Dernière modification')
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              sheet!.updatedBy.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PointingControlColors.ink,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              PointingControlFormat.dateTime(sheet.updatedAt),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: PointingControlColors.muted,
                                fontSize: 10.5,
                              ),
                            ),
                          ],
                        ),
                ),
                SizedBox(
                  width: 30,
                  child: widget.header
                      ? const SizedBox.shrink()
                      : const Icon(
                          HugeIcons.strokeRoundedArrowRight01,
                          size: 18,
                          color: PointingControlColors.muted,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tableCell({required int flex, required Widget child}) {
    return Expanded(flex: flex, child: child);
  }

  Widget _headerText(String value) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: PointingControlColors.muted,
        fontSize: 11,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _targetValue(int value, Color color) {
    return Text(
      value.toString(),
      style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800),
    );
  }

  Widget _strongValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        color: PointingControlColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _attentionValue(int value) {
    return Container(
      width: 34,
      padding: const EdgeInsets.symmetric(vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value == 0
            ? PointingControlColors.successSoft
            : PointingControlColors.dangerSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value.toString(),
        style: TextStyle(
          color: value == 0
              ? PointingControlColors.success
              : PointingControlColors.danger,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MobileSheetTile extends StatelessWidget {
  const _MobileSheetTile({
    required this.sheet,
    required this.summary,
    required this.onTap,
  });

  final MonthlyPointingSheet sheet;
  final MonthlyPointingSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PointingControlColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  ControlAvatar(initials: sheet.initials),
                  const SizedBox(width: 10),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          sheet.zoneName ?? 'Zone non renseignée',
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
                  const Icon(
                    HugeIcons.strokeRoundedArrowRight01,
                    size: 18,
                    color: PointingControlColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _mobileValue(
                      'Jour',
                      '${summary.actualDayTotal}',
                      'objectif ${sheet.expectedDay}/j',
                      PointingControlColors.day,
                    ),
                  ),
                  Expanded(
                    child: _mobileValue(
                      'Nuit',
                      '${summary.actualNightTotal}',
                      'objectif ${sheet.expectedNight}/j',
                      PointingControlColors.night,
                    ),
                  ),
                  Expanded(
                    child: _mobileValue(
                      'À justifier',
                      '${summary.missingReasons}',
                      '${summary.compliantDays}/${summary.evaluatedDays} conformes',
                      summary.missingReasons == 0
                          ? PointingControlColors.success
                          : PointingControlColors.danger,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileValue(String label, String value, String detail, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: PointingControlColors.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: PointingControlColors.muted, fontSize: 9.5),
        ),
      ],
    );
  }
}

class _CreateSheetDialog extends StatefulWidget {
  const _CreateSheetDialog({
    required this.month,
    required this.service,
  });

  final DateTime month;
  final MonthlyPointingSheetService service;

  @override
  State<_CreateSheetDialog> createState() => _CreateSheetDialogState();
}

class _CreateSheetDialogState extends State<_CreateSheetDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dayController = TextEditingController(text: '0');
  final TextEditingController _nightController =
      TextEditingController(text: '0');
  late final Future<List<Supervisor>> _supervisorsFuture;

  Supervisor? _supervisor;
  bool _loadingSuggestion = false;
  bool _saving = false;
  int? _suggestedDay;
  int? _suggestedNight;
  String? _error;

  @override
  void initState() {
    super.initState();
    _supervisorsFuture = SupervisorService().allFuture();
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
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: PointingControlColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        HugeIcons.strokeRoundedCalendarAdd01,
                        color: PointingControlColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Créer une fiche mensuelle',
                            style: TextStyle(
                              color: PointingControlColors.ink,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            PointingControlFormat.month(widget.month),
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
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      icon: const Icon(HugeIcons.strokeRoundedCancel01),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FutureBuilder<List<Supervisor>>(
                  future: _supervisorsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text(
                        'Impossible de charger les superviseurs : ${snapshot.error}',
                        style: const TextStyle(
                            color: PointingControlColors.danger),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const LinearProgressIndicator(minHeight: 3);
                    }
                    final supervisors = snapshot.data!;
                    return DropdownButtonFormField<Supervisor>(
                      initialValue: _supervisor,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        label: 'Superviseur',
                        icon: HugeIcons.strokeRoundedUserSearch01,
                      ),
                      items: supervisors
                          .map(
                            (supervisor) => DropdownMenuItem<Supervisor>(
                              value: supervisor,
                              child: Text(
                                '${supervisor.firstName} ${supervisor.lastName}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(growable: false),
                      validator: (value) =>
                          value == null ? 'Sélectionnez un superviseur.' : null,
                      onChanged: _saving
                          ? null
                          : (value) {
                              setState(() {
                                _supervisor = value;
                                _suggestedDay = null;
                                _suggestedNight = null;
                                _error = null;
                              });
                              if (value != null) _loadSuggestion(value);
                            },
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final dayField = _targetField(
                      controller: _dayController,
                      label: 'Objectif jour quotidien',
                      icon: HugeIcons.strokeRoundedSun03,
                      color: PointingControlColors.day,
                    );
                    final nightField = _numberField(
                      controller: _nightController,
                      label: 'Objectif nuit quotidien',
                      icon: HugeIcons.strokeRoundedMoon02,
                      color: PointingControlColors.night,
                    );
                    if (constraints.maxWidth < 500) {
                      return Column(
                        children: [
                          dayField,
                          const SizedBox(height: 12),
                          nightField,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: dayField),
                        const SizedBox(width: 12),
                        Expanded(child: nightField),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FB),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: PointingControlColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        HugeIcons.strokeRoundedBuilding03,
                        size: 19,
                        color: PointingControlColors.muted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _loadingSuggestion
                              ? 'Analyse des sites affectés…'
                              : _suggestedDay == null
                                  ? 'Sélectionnez un superviseur pour obtenir une proposition depuis ses sites.'
                                  : 'Selon les sites actuels : $_suggestedDay jour et $_suggestedNight nuit.',
                          style: const TextStyle(
                            color: PointingControlColors.muted,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                      if (_suggestedDay != null)
                        TextButton(
                          onPressed: _saving ? null : _applySuggestion,
                          child: const Text('Utiliser'),
                        ),
                    ],
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
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PointingControlColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size(150, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
                      label: Text(_saving ? 'Création…' : 'Créer la fiche'),
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
      decoration: _inputDecoration(label: label, icon: icon, iconColor: color),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        if (number == null || number < 0) return 'Valeur invalide.';
        return null;
      },
    );
  }

  Widget _targetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return _numberField(
      controller: controller,
      label: label,
      icon: icon,
      color: color,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Color iconColor = PointingControlColors.primary,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19, color: iconColor),
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

  Future<void> _loadSuggestion(Supervisor supervisor) async {
    setState(() => _loadingSuggestion = true);
    try {
      final sites = await SiteService().allBySupervisor(supervisor);
      var day = 0;
      var night = 0;
      for (final site in sites) {
        final type = site.pointageType.trim().toLowerCase();
        if (type == 'jour' || type == 'jour_nuit' || type == 'jour-nuit') day++;
        if (type == 'nuit' || type == 'jour_nuit' || type == 'jour-nuit') {
          night++;
        }
      }
      if (!mounted || _supervisor?.UID != supervisor.UID) return;
      setState(() {
        _suggestedDay = day;
        _suggestedNight = night;
        _loadingSuggestion = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingSuggestion = false;
        _error = 'La proposition depuis les sites n’a pas pu être calculée.';
      });
    }
  }

  void _applySuggestion() {
    _dayController.text = (_suggestedDay ?? 0).toString();
    _nightController.text = (_suggestedNight ?? 0).toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final expectedDay = int.parse(_dayController.text.trim());
    final expectedNight = int.parse(_nightController.text.trim());
    if (expectedDay == 0 && expectedNight == 0) {
      setState(() => _error = 'Renseignez au moins un objectif jour ou nuit.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final sheetId = await widget.service.createSheet(
        supervisor: _supervisor!,
        month: widget.month,
        expectedDay: expectedDay,
        expectedNight: expectedNight,
      );
      if (mounted) Navigator.pop(context, sheetId);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }
}
