import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../administration/home.dart';
import '../pointage_redesign/providers/pointage_zone_provider.dart';
import '../pointage_redesign/data/pointage_zone_repository.dart';
import '../pointage_redesign/data/cache_manager.dart';
import '../pointage_redesign/presentation/widgets/statistics_card.dart';
import '../pointage_redesign/presentation/widgets/filter_bar.dart';
import '../pointage_redesign/presentation/widgets/error_display.dart';
import '../pointage_redesign/presentation/design_system.dart';
import '../model.dart';

/// Modern zone pointage list with statistics, filtering, and pagination
/// 
/// Requirements: 1.1, 1.2, 1.3, 1.4
class PointageZoneListModern extends StatefulWidget {
  const PointageZoneListModern({super.key});

  @override
  State<PointageZoneListModern> createState() => _PointageZoneListModernState();
}

class _PointageZoneListModernState extends State<PointageZoneListModern> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PointageZoneProvider(
        repository: PointageZoneRepository(),
        cacheManager: CacheManager(),
      )..loadPointages()..loadStats(),
      child: PageModel(
        pageIndex: 15,
        title: "Pointages des chefs de zone",
        child: Consumer<PointageZoneProvider>(
          builder: (context, provider, child) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Statistics Card - Compact mode for reduced height
                  // Pass stats only when available to avoid "Aucune statistique disponible"
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: StatisticsCard(
                      totalPointages: provider.stats?.totalPointages,
                      uniqueSupervisors: provider.stats?.uniqueZoneMembers,
                      uniqueSites: provider.stats?.uniqueZones,
                      averagePerDay: provider.stats?.averagePointagesPerDay,
                      supervisorLabel: 'Chefs de zone',
                      siteLabel: 'Zones',
                      isLoading: provider.isLoadingStats,
                      compact: true,
                    ),
                  ),

                  // Action buttons row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Spacer(),
                        // Report button
                        ElevatedButton.icon(
                          onPressed: () => _showReportDialog(context),
                          icon: const Icon(Icons.calendar_today, size: PointageIconSizes.sm),
                          label: const Text('Rapports'),
                          style: PointageButtonStyles.primary,
                        ),
                        const SizedBox(width: PointageSpacing.md),
                        // Refresh button
                        _RefreshButton(
                          isLoading: provider.isLoading,
                          onPressed: () => provider.refreshData(),
                        ),
                      ],
                    ),
                  ),

                  // Filter Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: FilterBar(
                      filters: provider.filters,
                      onFiltersChanged: (filters) => provider.applyFilters(filters),
                      isLoading: provider.isLoading,
                      showZoneMemberFilter: true,
                      showZoneFilter: true,
                      zoneMemberLabel: 'Chef de zone',
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error Display
                  if (provider.hasError)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ErrorDisplay(
                        customMessage: provider.error!,
                        onRetry: () => provider.loadPointages(refresh: true),
                      ),
                    ),

                  // Pointage Table - No Expanded wrapper for full page scroll
                  _buildPointageTable(provider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the pointage table
  Widget _buildPointageTable(PointageZoneProvider provider) {
    if (provider.isLoading && provider.pointages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(64.0),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.pointages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(64.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun pointage trouvé',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm:ss');

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PaginatedDataTable(
        header: null,
        rowsPerPage: provider.pagination.itemsPerPage,
        availableRowsPerPage: const [10, 20, 50, 100],
        onRowsPerPageChanged: (value) {
          if (value != null) {
            provider.changeItemsPerPage(value);
          }
        },
        onPageChanged: (page) {
          final newPage = (page ~/ provider.pagination.itemsPerPage) + 1;
          if (newPage != provider.pagination.currentPage) {
            provider.goToPage(newPage);
          }
        },
        columns: const [
          DataColumn(
            label: Text('Chef de zone'),
            tooltip: 'Chef de zone ayant effectué le pointage',
          ),
          DataColumn(
            label: Text('Site'),
            tooltip: 'Site visité',
          ),
          DataColumn(
            label: Text('Zone'),
            tooltip: 'Zone du chef de zone',
          ),
          DataColumn(
            label: Text('Date'),
            tooltip: 'Date du pointage',
          ),
          DataColumn(
            label: Text('Heure'),
            tooltip: 'Heure du pointage',
          ),
          DataColumn(
            label: Text('Contact'),
            tooltip: 'Numéro de téléphone',
          ),
        ],
        source: _PointageZoneDataSource(
          pointages: provider.pointages,
          dateFormat: dateFormat,
          timeFormat: timeFormat,
        ),
      ),
    );
  }

  /// Show report selection dialog
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
              // Date picker
              _DatePickerTile(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: PointageSpacing.xl),
              // Report buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.go('/pointagezones/npcz', extra: _selectedDate);
                  },
                  icon: const Icon(Icons.assessment, size: PointageIconSizes.sm),
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
                  icon: const Icon(Icons.bar_chart, size: PointageIconSizes.sm),
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


/// Refresh button with glass smooth hover effect
class _RefreshButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _RefreshButton({
    required this.isLoading,
    required this.onPressed,
  });

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: PointageSpacing.lg,
            vertical: PointageSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _isHovered && !widget.isLoading
                ? PointageColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            border: Border.all(
              color: PointageColors.primary,
              width: _isHovered && !widget.isLoading ? 2.0 : 1.5,
            ),
            borderRadius: PointageBorderRadius.medium,
            boxShadow: _isHovered && !widget.isLoading ? PointageShadows.sm : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.isLoading
                  ? const SizedBox(
                      width: PointageIconSizes.sm,
                      height: PointageIconSizes.sm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(PointageColors.primary),
                      ),
                    )
                  : AnimatedContainer(
                      duration: PointageAnimations.fast,
                      transform: Matrix4.identity()
                        ..scale(_isHovered ? 1.1 : 1.0),
                      child: Icon(
                        Icons.refresh,
                        color: PointageColors.primary,
                        size: _isHovered ? 22 : PointageIconSizes.sm,
                      ),
                    ),
              const SizedBox(width: PointageSpacing.sm),
              Text(
                'Actualiser',
                style: PointageTextStyles.button.copyWith(
                  color: PointageColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date picker tile with glass smooth hover effect
class _DatePickerTile extends StatefulWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const _DatePickerTile({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_DatePickerTile> createState() => _DatePickerTileState();
}

class _DatePickerTileState extends State<_DatePickerTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
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
              color: _isHovered ? PointageColors.primary : PointageColors.divider,
              width: _isHovered ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: _isHovered ? PointageColors.primary : PointageColors.textSecondary,
                size: PointageIconSizes.sm,
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: Text(
                  DateFormat('dd/MM/yyyy').format(widget.selectedDate),
                  style: PointageTextStyles.body1.copyWith(
                    color: _isHovered ? PointageColors.primary : PointageColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.edit,
                color: _isHovered ? PointageColors.primary : PointageColors.textSecondary,
                size: PointageIconSizes.sm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Data source for the zone pointage table
class _PointageZoneDataSource extends DataTableSource {
  final List<PointingZone> pointages;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  _PointageZoneDataSource({
    required this.pointages,
    required this.dateFormat,
    required this.timeFormat,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= pointages.length) return null;

    final pointage = pointages[index];

    return DataRow(
      cells: [
        // Chef de zone
        DataCell(
          Text(
            '${pointage.zoneMember?.firstName ?? ''} ${pointage.zoneMember?.lastName ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        // Site
        DataCell(
          Text(
            pointage.site.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        // Zone
        DataCell(
          Text(pointage.zoneMember?.zone?.name ?? 'N/A'),
        ),
        // Date - with colored chip (blue)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              dateFormat.format(pointage.date),
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Heure - with colored chip (orange)
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              timeFormat.format(pointage.date),
              style: TextStyle(
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Contact
        DataCell(
          Text(pointage.zoneMember?.phone ?? 'N/A'),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => pointages.length;

  @override
  int get selectedRowCount => 0;
}
