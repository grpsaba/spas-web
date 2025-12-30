import 'package:flutter/material.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';

/// Status filter badges for filtering resolved/unresolved errors
class StatusFilterBadges extends StatelessWidget {
  final bool? currentFilter;
  final ValueChanged<bool?> onFilterChanged;

  const StatusFilterBadges({
    super.key,
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildBadge(
          label: 'Tous',
          isSelected: currentFilter == null,
          color: PointageColors.primary,
          icon: Icons.all_inclusive,
          onTap: () => onFilterChanged(null),
        ),
        const SizedBox(width: PointageSpacing.sm),
        _buildBadge(
          label: 'Non résolus',
          isSelected: currentFilter == false,
          color: PointageColors.error,
          icon: Icons.error_outline,
          onTap: () => onFilterChanged(false),
        ),
        const SizedBox(width: PointageSpacing.sm),
        _buildBadge(
          label: 'Résolus',
          isSelected: currentFilter == true,
          color: PointageColors.success,
          icon: Icons.check_circle_outline,
          onTap: () => onFilterChanged(true),
        ),
      ],
    );
  }

  Widget _buildBadge({
    required String label,
    required bool isSelected,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: PointageBorderRadius.medium,
      child: AnimatedContainer(
        duration: PointageAnimations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: PointageSpacing.md,
          vertical: PointageSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: PointageBorderRadius.medium,
          border: Border.all(
            color: isSelected ? color : PointageColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? color : PointageColors.textSecondary,
            ),
            const SizedBox(width: PointageSpacing.xs),
            Text(
              label,
              style: PointageTextStyles.label.copyWith(
                color: isSelected ? color : PointageColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
