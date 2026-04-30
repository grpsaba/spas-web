import 'package:flutter/material.dart';
import '../../../model.dart';
import '../design_system.dart';

/// Configuration for table sorting
class TableSortConfig {
  final String field;
  final bool ascending;

  const TableSortConfig({
    required this.field,
    required this.ascending,
  });

  TableSortConfig copyWith({String? field, bool? ascending}) {
    return TableSortConfig(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Modern table component for displaying pointages with hover effects and sorting
class ModernPointageTable extends StatelessWidget {
  final List<PointingSite> pointages;
  final TableSortConfig? sortConfig;
  final Function(TableSortConfig)? onSort;
  final bool isLoading;
  final int? loadingRowCount;
  final Function(PointingSite)? onRowTap;

  const ModernPointageTable({
    Key? key,
    required this.pointages,
    this.sortConfig,
    this.onSort,
    this.isLoading = false,
    this.loadingRowCount = 10,
    this.onRowTap,
  }) : super(key: key);

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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 48,
          ),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              PointageColors.background,
            ),
            dataRowColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
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
            sortColumnIndex: sortConfig != null ? _getSortColumnIndex(sortConfig!.field) : null,
            sortAscending: sortConfig?.ascending ?? true,
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return [
      // Superviseur (non-sortable)
      DataColumn(
        label: Text(
          'Superviseur',
          style: PointageTextStyles.label,
        ),
      ),
      // Site (non-sortable)
      DataColumn(
        label: Text(
          'Site',
          style: PointageTextStyles.label,
        ),
      ),
      // Zone (non-sortable)
      DataColumn(
        label: Text(
          'Zone',
          style: PointageTextStyles.label,
        ),
      ),
      // Date (sortable)
      _buildSortableColumn('Date', 'datetimestamp'),
      // Heure (sortable - uses same field as Date)
      _buildSortableColumn('Heure', 'datetimestamp'),
      // Distance (sortable)
      _buildSortableColumn('Distance', 'distance'),
    ];
  }

  /// Get the column index for a given sort field
  /// New column order: Superviseur(0), Site(1), Zone(2), Date(3), Heure(4), Distance(5)
  int? _getSortColumnIndex(String field) {
    switch (field) {
      case 'datetimestamp':
        return 3; // Date column (index 3 in new order)
      case 'distance':
        return 5; // Distance column (index 5 in new order)
      default:
        return null;
    }
  }

  DataColumn _buildSortableColumn(String label, String field) {
    final isActive = sortConfig?.field == field;
    final ascending = sortConfig?.ascending ?? true;

    return DataColumn(
      label: Tooltip(
        message: isActive
            ? (ascending
                ? 'Trier par $label (décroissant)'
                : 'Trier par $label (croissant)')
            : 'Trier par $label',
        child: InkWell(
          onTap: onSort != null
              ? () {
                  // Toggle sort direction if same field, otherwise default to ascending
                  final newAscending = isActive ? !ascending : true;
                  onSort!(TableSortConfig(
                    field: field,
                    ascending: newAscending,
                  ));
                }
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: PointageTextStyles.label.copyWith(
                  color: isActive
                      ? PointageColors.primary
                      : PointageColors.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
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
                      : PointageColors.textSecondary.withValues(alpha: 0.5),
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
      final isEven = index % 2 == 0;

      return DataRow(
        color: WidgetStateProperty.resolveWith<Color>(
          (Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return PointageColors.primary.withValues(alpha: 0.05);
            }
            return isEven
                ? Colors.transparent
                : PointageColors.background.withValues(alpha: 0.3);
          },
        ),
        onSelectChanged: onRowTap != null ? (_) => onRowTap!(pointage) : null,
        cells: [
          // Superviseur (column 0)
          DataCell(
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: PointageColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    _getInitials(
                      pointage.supervisor?.firstName ?? '',
                      pointage.supervisor?.lastName ?? '',
                    ),
                    style: PointageTextStyles.caption.copyWith(
                      color: PointageColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: PointageSpacing.sm),
                Expanded(
                  child: Text(
                    '${pointage.supervisor?.firstName ?? ''} ${pointage.supervisor?.lastName ?? ''}',
                    style: PointageTextStyles.body2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Site (column 1)
          DataCell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pointage.site.codeSite,
                  style: PointageTextStyles.body2.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  pointage.site.name,
                  style: PointageTextStyles.caption,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Zone (column 2)
          DataCell(
            Text(
              pointage.site.zone?.name ?? 'N/A',
              style: PointageTextStyles.body2,
            ),
          ),
          // Date (column 3) - with colored chip
          DataCell(
            _buildDateChip(pointage.date),
          ),
          // Heure (column 4) - with colored chip
          DataCell(
            _buildTimeChip(pointage.date),
          ),
          // Distance (column 5)
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PointageSpacing.sm,
                vertical: PointageSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: _getDistanceColor(pointage.distance).withValues(alpha: 0.1),
                borderRadius: PointageBorderRadius.small,
              ),
              child: Text(
                '${pointage.distance.toStringAsFixed(0)}m',
                style: PointageTextStyles.body2.copyWith(
                  color: _getDistanceColor(pointage.distance),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Build a colored chip for displaying the date
  /// Uses blue background as per design requirements
  Widget _buildDateChip(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.sm,
        vertical: PointageSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: PointageBorderRadius.small,
      ),
      child: Text(
        _formatDate(date),
        style: PointageTextStyles.body2.copyWith(
          color: Colors.blue.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Build a colored chip for displaying the time
  /// Uses orange background as per design requirements
  Widget _buildTimeChip(DateTime date) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.sm,
        vertical: PointageSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: PointageBorderRadius.small,
      ),
      child: Text(
        _formatTime(date),
        style: PointageTextStyles.body2.copyWith(
          color: Colors.orange.shade800,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: _AnimatedLoadingSkeleton(rowCount: loadingRowCount ?? 10),
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
            Icon(
              Icons.inbox_outlined,
              size: PointageIconSizes.xl * 2,
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
              'Essayez de modifier vos filtres ou votre période de recherche',
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  Color _getDistanceColor(double distance) {
    if (distance <= 50) {
      return PointageColors.success;
    } else if (distance <= 100) {
      return PointageColors.warning;
    } else {
      return PointageColors.error;
    }
  }
}

/// Animated loading skeleton container with a single shared AnimationController
/// Instead of N controllers (one per row), we use one controller and pass the value down
class _AnimatedLoadingSkeleton extends StatefulWidget {
  final int rowCount;

  const _AnimatedLoadingSkeleton({Key? key, required this.rowCount}) : super(key: key);

  @override
  State<_AnimatedLoadingSkeleton> createState() => _AnimatedLoadingSkeletonState();
}

class _AnimatedLoadingSkeletonState extends State<_AnimatedLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: List.generate(
            widget.rowCount,
            (index) => _LoadingRow(
              isEven: index % 2 == 0,
              animationValue: _animation.value,
            ),
          ),
        );
      },
    );
  }
}

/// Loading skeleton row — stateless, receives animation value from parent
class _LoadingRow extends StatelessWidget {
  final bool isEven;
  final double animationValue;

  const _LoadingRow({
    Key? key,
    required this.isEven,
    required this.animationValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: PointageSpacing.sm),
      padding: const EdgeInsets.all(PointageSpacing.md),
      decoration: BoxDecoration(
        color: isEven
            ? Colors.transparent
            : PointageColors.background.withValues(alpha: 0.3),
        borderRadius: PointageBorderRadius.small,
      ),
      child: Row(
        children: [
          // Date
          Container(
            width: 80,
            height: 16,
            decoration: BoxDecoration(
              color: PointageColors.divider.withValues(alpha: animationValue),
              borderRadius: PointageBorderRadius.small,
            ),
          ),
          const SizedBox(width: PointageSpacing.lg),
          // Time
          Container(
            width: 50,
            height: 16,
            decoration: BoxDecoration(
              color: PointageColors.divider.withValues(alpha: animationValue),
              borderRadius: PointageBorderRadius.small,
            ),
          ),
          const SizedBox(width: PointageSpacing.lg),
          // Supervisor
          Container(
            width: 120,
            height: 16,
            decoration: BoxDecoration(
              color: PointageColors.divider.withValues(alpha: animationValue),
              borderRadius: PointageBorderRadius.small,
            ),
          ),
          const SizedBox(width: PointageSpacing.lg),
          // Site
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: PointageColors.divider.withValues(alpha: animationValue),
              borderRadius: PointageBorderRadius.small,
            ),
          ),
        ],
      ),
    );
  }
}
