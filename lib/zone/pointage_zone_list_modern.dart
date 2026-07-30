import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../administration/home.dart';
import '../model.dart';
import '../pointage_redesign/data/cache_manager.dart';
import '../pointage_redesign/data/pointage_zone_repository.dart';
import '../pointage_redesign/providers/pointage_zone_provider.dart';
import '../pointage_redesign/presentation/design_system.dart';
import '../pointage_redesign/presentation/widgets/error_display.dart';
import '../pointage_redesign/presentation/widgets/filter_bar.dart';
import '../pointage_redesign/presentation/widgets/modern_pointage_table.dart';
import '../pointage_redesign/presentation/widgets/statistics_card.dart';
import '../services/site.dart';
import '../services/zone.dart';
import '../services/zoneMember.dart';

/// Modern zone pointage list aligned with the site pointage experience.
class PointageZoneListModern extends StatefulWidget {
  const PointageZoneListModern({super.key});

  @override
  State<PointageZoneListModern> createState() => _PointageZoneListModernState();
}

class _PointageZoneListModernState extends State<PointageZoneListModern> {
  late final PointageZoneProvider _provider;
  DateTime _selectedDate = DateTime.now();
  bool _showStats = false;

  List<ZoneMember>? _availableZoneMembers;
  List<Site>? _availableSites;
  List<Zone>? _availableZones;

  @override
  void initState() {
    super.initState();
    _provider = PointageZoneProvider(
      repository: PointageZoneRepository(),
      cacheManager: CacheManager(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _provider.loadPointages();
      _loadFilterData();
    });
  }

  Future<void> _loadFilterData() async {
    try {
      final results = await Future.wait<Object>([
        ZoneMemberService().allActifAsModel(),
        SiteService().allActifAsModel(),
        ZoneService().allAsModel(),
      ]);

      if (!mounted) return;
      setState(() {
        _availableZoneMembers = results[0] as List<ZoneMember>;
        _availableSites = results[1] as List<Site>;
        _availableZones = results[2] as List<Zone>;
      });
    } catch (error) {
      debugPrint('Error loading zone pointage filter data: $error');
    }
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: PageModel(
        pageIndex: 15,
        title: 'Pointages des chefs de zone',
        child: Consumer<PointageZoneProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(PointageSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatsSection(provider),
                  const SizedBox(height: PointageSpacing.lg),
                  FilterBar(
                    filters: provider.filters,
                    onFiltersChanged: provider.applyFilters,
                    resultCount: provider.pagination.totalItems,
                    isLoading: provider.isLoading,
                    availableZoneMembers: _availableZoneMembers,
                    availableSites: _availableSites,
                    availableZones: _availableZones,
                    showZoneMemberFilter: true,
                    showZoneFilter: true,
                    zoneMemberLabel: 'Chef de zone',
                  ),
                  const SizedBox(height: PointageSpacing.lg),
                  _buildActionButtons(context, provider),
                  const SizedBox(height: PointageSpacing.lg),
                  if (provider.hasError)
                    Padding(
                      padding:
                          const EdgeInsets.only(bottom: PointageSpacing.lg),
                      child: ErrorDisplay(
                        customMessage: provider.error,
                        onRetry: () => provider.refreshData(),
                        compact: provider.pointages.isNotEmpty,
                      ),
                    ),
                  if (provider.isLoading && provider.pointages.isNotEmpty) ...[
                    const LinearProgressIndicator(minHeight: 3),
                    const SizedBox(height: PointageSpacing.md),
                  ],
                  ModernZonePointageTable(
                    pointages: provider.pointages,
                    isLoading: provider.isLoading && provider.pointages.isEmpty,
                    sortConfig: TableSortConfig(
                      field: provider.sortField,
                      ascending: provider.sortAscending,
                    ),
                    onSort: (config) {
                      provider.changeSort(
                        config.field,
                        ascending: config.ascending,
                      );
                    },
                  ),
                  const SizedBox(height: PointageSpacing.lg),
                  _buildPaginationControls(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsSection(PointageZoneProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.analytics_outlined,
              color: PointageColors.primary,
              size: PointageIconSizes.sm,
            ),
            const SizedBox(width: PointageSpacing.sm),
            Text(
              'Statistiques',
              style: PointageTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: PointageSpacing.sm),
            Switch(
              value: _showStats,
              activeTrackColor: PointageColors.primary.withValues(alpha: 0.5),
              activeThumbColor: PointageColors.primary,
              onChanged: (value) {
                setState(() {
                  _showStats = value;
                });
                if (value && provider.stats == null) {
                  provider.loadStats();
                }
              },
            ),
          ],
        ),
        if (_showStats) ...[
          const SizedBox(height: PointageSpacing.sm),
          StatisticsCard(
            totalPointages: provider.stats?.totalPointages,
            uniqueSupervisors: provider.stats?.uniqueZoneMembers,
            uniqueSites: provider.stats?.uniqueZones,
            averagePerDay: provider.stats?.averagePointagesPerDay,
            supervisorLabel: 'Chefs de zone',
            siteLabel: 'Zones',
            isLoading: provider.isLoadingStats,
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    PointageZoneProvider provider,
  ) {
    return Container(
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: PointageCardDecorations.outlined,
      child: Wrap(
        spacing: PointageSpacing.sm,
        runSpacing: PointageSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Wrap(
            spacing: PointageSpacing.sm,
            runSpacing: PointageSpacing.sm,
            children: [
              ElevatedButton.icon(
                onPressed: provider.isLoading ? null : provider.refreshData,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: PointageIconSizes.sm,
                        height: PointageIconSizes.sm,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: PointageIconSizes.sm),
                label: const Text('Actualiser'),
                style: PointageButtonStyles.outlined,
              ),
              ElevatedButton.icon(
                onPressed: () => _showReportDialog(context),
                icon: const Icon(
                  Icons.assessment_outlined,
                  size: PointageIconSizes.sm,
                ),
                label: const Text('Rapports'),
                style: PointageButtonStyles.primary,
              ),
            ],
          ),
          _buildItemsPerPageSelector(provider),
        ],
      ),
    );
  }

  Widget _buildItemsPerPageSelector(PointageZoneProvider provider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Lignes par page:',
          style: PointageTextStyles.body2,
        ),
        const SizedBox(width: PointageSpacing.sm),
        DropdownButton<int>(
          value: provider.pagination.itemsPerPage,
          items: const [10, 20, 50, 100]
              .map(
                (value) => DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              provider.changeItemsPerPage(value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildPaginationControls(PointageZoneProvider provider) {
    final pagination = provider.pagination;
    final pageLabel = pagination.totalItems == 0
        ? 'Aucun résultat'
        : 'Page ${pagination.currentPage} sur ${pagination.totalPages}';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.sm,
      ),
      decoration: PointageCardDecorations.outlined,
      child: Wrap(
        spacing: PointageSpacing.sm,
        runSpacing: PointageSpacing.sm,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            onPressed: pagination.currentPage > 1 && !provider.isLoading
                ? () => provider.goToPage(1)
                : null,
            icon: const Icon(Icons.first_page),
            tooltip: 'Première page',
          ),
          IconButton(
            onPressed: pagination.canGoPrevious && !provider.isLoading
                ? provider.loadPreviousPage
                : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Page précédente',
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PointageSpacing.md,
              vertical: PointageSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: PointageColors.background,
              borderRadius: PointageBorderRadius.medium,
            ),
            child: Text(
              pageLabel,
              style: PointageTextStyles.body2.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: pagination.canGoNext && !provider.isLoading
                ? provider.loadNextPage
                : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Page suivante',
          ),
          IconButton(
            onPressed: pagination.currentPage < pagination.totalPages &&
                    !provider.isLoading
                ? () => provider.goToPage(pagination.totalPages)
                : null,
            icon: const Icon(Icons.last_page),
            tooltip: 'Dernière page',
          ),
          Text(
            '${pagination.totalItems} pointage${pagination.totalItems > 1 ? 's' : ''}',
            style: PointageTextStyles.caption,
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: PointageBorderRadius.large,
        ),
        title: const Text(
          'Sélectionner un rapport',
          style: PointageTextStyles.headline3,
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sélectionner une date',
                style: PointageTextStyles.label.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: PointageSpacing.lg),
              _DatePickerTile(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: PointageSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.go('/pointagezones/npcz', extra: _selectedDate);
                  },
                  icon: const Icon(
                    Icons.assessment,
                    size: PointageIconSizes.sm,
                  ),
                  label: const Text('Rapport de pointage par chef de zone'),
                  style: PointageButtonStyles.primary,
                ),
              ),
              const SizedBox(height: PointageSpacing.md),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.go('/pointagezones/nvcz', extra: _selectedDate);
                  },
                  icon: const Icon(
                    Icons.bar_chart,
                    size: PointageIconSizes.sm,
                  ),
                  label: const Text('Nombre de visites par site'),
                  style: PointageButtonStyles.outlined,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: PointageButtonStyles.text,
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class ModernZonePointageTable extends StatelessWidget {
  const ModernZonePointageTable({
    super.key,
    required this.pointages,
    this.isLoading = false,
    this.sortConfig,
    this.onSort,
  });

  final List<PointingZone> pointages;
  final bool isLoading;
  final TableSortConfig? sortConfig;
  final ValueChanged<TableSortConfig>? onSort;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingSkeleton();
    }

    if (pointages.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PointageSpacing.lg,
              PointageSpacing.lg,
              PointageSpacing.lg,
              PointageSpacing.sm,
            ),
            child: Wrap(
              spacing: PointageSpacing.md,
              runSpacing: PointageSpacing.sm,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Tableau des pointages',
                  style: PointageTextStyles.headline4.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _CountBadge(count: pointages.length),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: PointageSpacing.sm),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 48,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  PointageColors.background,
                ),
                dataRowColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.hovered)) {
                      return PointageColors.primary.withValues(alpha: 0.05);
                    }
                    return Colors.transparent;
                  },
                ),
                columns: _buildColumns(),
                rows: _buildRows(),
                columnSpacing: PointageSpacing.lg,
                horizontalMargin: PointageSpacing.lg,
                showCheckboxColumn: false,
                sortColumnIndex: sortConfig != null ? 3 : null,
                sortAscending: sortConfig?.ascending ?? true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      const DataColumn(
        label: Text('Chef de zone', style: PointageTextStyles.label),
      ),
      const DataColumn(
        label: Text('Site', style: PointageTextStyles.label),
      ),
      const DataColumn(
        label: Text('Zone', style: PointageTextStyles.label),
      ),
      _buildSortableColumn('Date', 'datetimestamp'),
      _buildSortableColumn('Heure', 'datetimestamp'),
      const DataColumn(
        label: Text('Distance', style: PointageTextStyles.label),
      ),
      const DataColumn(
        label: Text('Contact', style: PointageTextStyles.label),
      ),
    ];
  }

  DataColumn _buildSortableColumn(String label, String field) {
    final isActive = sortConfig?.field == field;
    final ascending = sortConfig?.ascending ?? true;

    return DataColumn(
      label: Tooltip(
        message: isActive
            ? (ascending
                ? 'Trier par $label décroissant'
                : 'Trier par $label croissant')
            : 'Trier par $label',
        child: InkWell(
          onTap: onSort == null
              ? null
              : () {
                  onSort!(
                    TableSortConfig(
                      field: field,
                      ascending: isActive ? !ascending : true,
                    ),
                  );
                },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: PointageTextStyles.label.copyWith(
                  color: isActive
                      ? PointageColors.primary
                      : PointageColors.textPrimary,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(width: PointageSpacing.xs),
              AnimatedRotation(
                turns: isActive && !ascending ? 0.5 : 0,
                duration: PointageAnimations.fast,
                child: Icon(
                  Icons.arrow_upward,
                  size: PointageIconSizes.xs,
                  color: isActive
                      ? PointageColors.primary
                      : PointageColors.textSecondary.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DataRow> _buildRows() {
    return pointages.asMap().entries.map((entry) {
      final index = entry.key;
      final pointage = entry.value;

      return DataRow(
        color: WidgetStateProperty.resolveWith<Color>(
          (states) {
            if (states.contains(WidgetState.hovered)) {
              return PointageColors.primary.withValues(alpha: 0.05);
            }
            return index.isEven
                ? Colors.transparent
                : PointageColors.background.withValues(alpha: 0.3);
          },
        ),
        cells: [
          DataCell(_ZoneMemberCell(zoneMember: pointage.zoneMember)),
          DataCell(_SiteCell(site: pointage.site)),
          DataCell(_ZoneCell(zone: pointage.zoneMember?.zone)),
          DataCell(_DateChip(date: pointage.date)),
          DataCell(_TimeChip(date: pointage.date)),
          DataCell(_DistanceChip(distance: pointage.distance)),
          DataCell(Text(pointage.zoneMember?.phone ?? 'N/A')),
        ],
      );
    }).toList();
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Column(
        children: List.generate(
          8,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: PointageSpacing.sm),
            padding: const EdgeInsets.all(PointageSpacing.md),
            decoration: BoxDecoration(
              color: index.isEven
                  ? PointageColors.background
                  : PointageColors.hover,
              borderRadius: PointageBorderRadius.medium,
            ),
            child: const Row(
              children: [
                _SkeletonBox(width: 160),
                SizedBox(width: PointageSpacing.lg),
                _SkeletonBox(width: 180),
                SizedBox(width: PointageSpacing.lg),
                _SkeletonBox(width: 100),
                SizedBox(width: PointageSpacing.lg),
                _SkeletonBox(width: 90),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.xxl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: PointageIconSizes.xl,
              color: PointageColors.textSecondary,
            ),
            const SizedBox(height: PointageSpacing.lg),
            Text(
              'Aucun pointage trouvé',
              style: PointageTextStyles.headline4.copyWith(
                color: PointageColors.textSecondary,
              ),
            ),
            const SizedBox(height: PointageSpacing.sm),
            Text(
              'Modifiez les filtres ou actualisez la liste.',
              style: PointageTextStyles.body2.copyWith(
                color: PointageColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneMemberCell extends StatelessWidget {
  const _ZoneMemberCell({required this.zoneMember});

  final ZoneMember? zoneMember;

  @override
  Widget build(BuildContext context) {
    final firstName = zoneMember?.firstName ?? '';
    final lastName = zoneMember?.lastName ?? '';
    final initials =
        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
            .toUpperCase();
    final fullName = '$firstName $lastName'.trim();

    return SizedBox(
      width: 230,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: PointageColors.primary.withValues(alpha: 0.1),
            child: Text(
              initials.isEmpty ? '?' : initials,
              style: PointageTextStyles.caption.copyWith(
                color: PointageColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: PointageSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  fullName.isEmpty ? 'Non défini' : fullName,
                  style: PointageTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  zoneMember?.code ?? '',
                  style: PointageTextStyles.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SiteCell extends StatelessWidget {
  const _SiteCell({required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            site.codeSite,
            style: PointageTextStyles.body2.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            site.name,
            style: PointageTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ZoneCell extends StatelessWidget {
  const _ZoneCell({required this.zone});

  final Zone? zone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.sm,
        vertical: PointageSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: PointageColors.secondary.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.small,
      ),
      child: Text(
        zone?.name ?? 'N/A',
        style: PointageTextStyles.body2.copyWith(
          color: PointageColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return _ValueChip(
      label:
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
      color: PointageColors.chartBlue,
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return _ValueChip(
      label:
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
      color: PointageColors.warning,
    );
  }
}

class _DistanceChip extends StatelessWidget {
  const _DistanceChip({required this.distance});

  final double distance;

  @override
  Widget build(BuildContext context) {
    final roundedDistance = distance.isFinite ? distance.round() : 0;
    final color = roundedDistance <= 500
        ? PointageColors.success
        : PointageColors.warning;

    return _ValueChip(
      label: '$roundedDistance m',
      color: color,
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.sm,
        vertical: PointageSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.small,
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: PointageTextStyles.body2.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: PointageColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: PointageColors.divider),
      ),
      child: Text(
        '$count ligne${count > 1 ? 's' : ''} affichée${count > 1 ? 's' : ''}',
        style: PointageTextStyles.body2.copyWith(
          color: PointageColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: PointageColors.divider,
        borderRadius: PointageBorderRadius.small,
      ),
    );
  }
}

class _DatePickerTile extends StatefulWidget {
  const _DatePickerTile({
    required this.selectedDate,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<_DatePickerTile> createState() => _DatePickerTileState();
}

class _DatePickerTileState extends State<_DatePickerTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${widget.selectedDate.day.toString().padLeft(2, '0')}/'
        '${widget.selectedDate.month.toString().padLeft(2, '0')}/'
        '${widget.selectedDate.year}';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: widget.selectedDate,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: PointageColors.primary,
                    onPrimary: Colors.white,
                    surface: PointageColors.surface,
                    onSurface: PointageColors.textPrimary,
                  ),
                ),
                child: child!,
              );
            },
          );
          if (date != null) {
            widget.onDateSelected(date);
          }
        },
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          padding: const EdgeInsets.all(PointageSpacing.md),
          decoration: BoxDecoration(
            color: _isHovered
                ? PointageColors.primary.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: PointageBorderRadius.medium,
            border: Border.all(
              color:
                  _isHovered ? PointageColors.primary : PointageColors.divider,
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: _isHovered
                    ? PointageColors.primary
                    : PointageColors.textSecondary,
                size: PointageIconSizes.sm,
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: Text(
                  formattedDate,
                  style: PointageTextStyles.body1.copyWith(
                    color: _isHovered
                        ? PointageColors.primary
                        : PointageColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.edit,
                color: _isHovered
                    ? PointageColors.primary
                    : PointageColors.textSecondary,
                size: PointageIconSizes.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
