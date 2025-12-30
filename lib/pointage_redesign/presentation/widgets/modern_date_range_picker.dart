import 'package:flutter/material.dart';
import '../design_system.dart';
import 'tooltip_helper.dart';

/// Quick selection option for date ranges
enum QuickDateRange {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last7Days,
  last30Days,
}

extension QuickDateRangeExtension on QuickDateRange {
  String get label {
    switch (this) {
      case QuickDateRange.today:
        return 'Aujourd\'hui';
      case QuickDateRange.yesterday:
        return 'Hier';
      case QuickDateRange.thisWeek:
        return 'Cette semaine';
      case QuickDateRange.lastWeek:
        return 'Semaine dernière';
      case QuickDateRange.thisMonth:
        return 'Ce mois';
      case QuickDateRange.lastMonth:
        return 'Mois dernier';
      case QuickDateRange.last7Days:
        return '7 derniers jours';
      case QuickDateRange.last30Days:
        return '30 derniers jours';
    }
  }

  DateTimeRange get dateRange {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (this) {
      case QuickDateRange.today:
        return DateTimeRange(start: today, end: today);
      
      case QuickDateRange.yesterday:
        final yesterday = today.subtract(const Duration(days: 1));
        return DateTimeRange(start: yesterday, end: yesterday);
      
      case QuickDateRange.thisWeek:
        final weekday = now.weekday;
        final startOfWeek = today.subtract(Duration(days: weekday - 1));
        return DateTimeRange(start: startOfWeek, end: today);
      
      case QuickDateRange.lastWeek:
        final weekday = now.weekday;
        final startOfLastWeek = today.subtract(Duration(days: weekday + 6));
        final endOfLastWeek = today.subtract(Duration(days: weekday));
        return DateTimeRange(start: startOfLastWeek, end: endOfLastWeek);
      
      case QuickDateRange.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        return DateTimeRange(start: startOfMonth, end: today);
      
      case QuickDateRange.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final endOfLastMonth = DateTime(now.year, now.month, 0);
        return DateTimeRange(start: lastMonth, end: endOfLastMonth);
      
      case QuickDateRange.last7Days:
        final start = today.subtract(const Duration(days: 6));
        return DateTimeRange(start: start, end: today);
      
      case QuickDateRange.last30Days:
        final start = today.subtract(const Duration(days: 29));
        return DateTimeRange(start: start, end: today);
    }
  }
}

/// Modern date range picker with visual calendar and quick selection buttons
class ModernDateRangePicker extends StatefulWidget {
  final DateTimeRange? initialRange;
  final Function(DateTimeRange) onRangeSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;

  const ModernDateRangePicker({
    Key? key,
    this.initialRange,
    required this.onRangeSelected,
    this.firstDate,
    this.lastDate,
    this.errorText,
  }) : super(key: key);

  @override
  State<ModernDateRangePicker> createState() => _ModernDateRangePickerState();
}

class _ModernDateRangePickerState extends State<ModernDateRangePicker> {
  DateTimeRange? _selectedRange;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialRange;
  }

  void _selectQuickRange(QuickDateRange quickRange) {
    final range = quickRange.dateRange;
    setState(() {
      _selectedRange = range;
      _validationError = _validateRange(range);
    });
    
    if (_validationError == null) {
      widget.onRangeSelected(range);
    }
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: widget.lastDate ?? DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedRange,
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

    if (picked != null) {
      setState(() {
        _selectedRange = picked;
        _validationError = _validateRange(picked);
      });
      
      if (_validationError == null) {
        widget.onRangeSelected(picked);
      }
    }
  }

  String? _validateRange(DateTimeRange range) {
    if (range.start.isAfter(range.end)) {
      return 'La date de début doit être avant la date de fin';
    }
    
    final daysDifference = range.end.difference(range.start).inDays;
    if (daysDifference > 365) {
      return 'La période ne peut pas dépasser 365 jours';
    }
    
    return null;
  }

  int _getDayCount() {
    if (_selectedRange == null) return 0;
    return _selectedRange!.end.difference(_selectedRange!.start).inDays + 1;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: PointageCardDecorations.outlined,
      padding: const EdgeInsets.all(PointageSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Quick selection buttons
          Text(
            'Sélection rapide',
            style: PointageTextStyles.label,
          ),
          const SizedBox(height: PointageSpacing.sm),
          Wrap(
            spacing: PointageSpacing.sm,
            runSpacing: PointageSpacing.sm,
            children: QuickDateRange.values.map((quickRange) {
              return _QuickSelectChip(
                label: quickRange.label,
                onTap: () => _selectQuickRange(quickRange),
              );
            }).toList(),
          ),
          
          const SizedBox(height: PointageSpacing.lg),
          const Divider(height: 1, color: PointageColors.divider),
          const SizedBox(height: PointageSpacing.lg),
          
          // Custom range selection
          Text(
            'Sélection personnalisée',
            style: PointageTextStyles.label,
          ),
          const SizedBox(height: PointageSpacing.sm),
          
          Tooltip(
            message: TooltipHelper.selectDateRange,
            child: InkWell(
              onTap: _selectCustomRange,
              borderRadius: PointageBorderRadius.medium,
              child: Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _validationError != null || widget.errorText != null
                      ? PointageColors.error
                      : PointageColors.divider,
                ),
                borderRadius: PointageBorderRadius.medium,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: PointageIconSizes.sm,
                    color: PointageColors.primary,
                  ),
                  const SizedBox(width: PointageSpacing.md),
                  Expanded(
                    child: _selectedRange != null
                        ? Text(
                            '${_formatDate(_selectedRange!.start)} - ${_formatDate(_selectedRange!.end)}',
                            style: PointageTextStyles.body2,
                          )
                        : Text(
                            'Sélectionner une période',
                            style: PointageTextStyles.body2.copyWith(
                              color: PointageColors.textSecondary,
                            ),
                          ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: PointageColors.textSecondary,
                  ),
                ],
              ),
            ),
            ),
          ),
          
          // Day count display
          if (_selectedRange != null) ...[
            const SizedBox(height: PointageSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: PointageIconSizes.xs,
                  color: PointageColors.primary,
                ),
                const SizedBox(width: PointageSpacing.xs),
                Text(
                  '${_getDayCount()} jour${_getDayCount() > 1 ? 's' : ''} sélectionné${_getDayCount() > 1 ? 's' : ''}',
                  style: PointageTextStyles.caption.copyWith(
                    color: PointageColors.primary,
                  ),
                ),
              ],
            ),
          ],
          
          // Validation error
          if (_validationError != null || widget.errorText != null) ...[
            const SizedBox(height: PointageSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  size: PointageIconSizes.xs,
                  color: PointageColors.error,
                ),
                const SizedBox(width: PointageSpacing.xs),
                Expanded(
                  child: Text(
                    _validationError ?? widget.errorText!,
                    style: PointageTextStyles.caption.copyWith(
                      color: PointageColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Quick selection chip button
class _QuickSelectChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickSelectChip({
    Key? key,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_QuickSelectChip> createState() => _QuickSelectChipState();
}

class _QuickSelectChipState extends State<_QuickSelectChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Sélectionner: ${widget.label}',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: PointageBorderRadius.medium,
          child: AnimatedContainer(
            duration: PointageAnimations.fast,
            padding: const EdgeInsets.symmetric(
              horizontal: PointageSpacing.md,
              vertical: PointageSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: _isHovered
                  ? PointageColors.primary.withOpacity(0.1)
                  : PointageColors.background,
              borderRadius: PointageBorderRadius.medium,
              border: Border.all(
                color: _isHovered
                    ? PointageColors.primary
                    : PointageColors.divider,
              ),
            ),
            child: Text(
              widget.label,
              style: PointageTextStyles.body2.copyWith(
                color: _isHovered
                    ? PointageColors.primary
                    : PointageColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
