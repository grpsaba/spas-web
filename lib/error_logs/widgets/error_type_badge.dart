import 'package:flutter/material.dart';
import 'package:spas_web/error_logs/models/error_log_model.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';

/// Badge widget displaying error type with appropriate color and icon
class ErrorTypeBadge extends StatelessWidget {
  final String errorType;
  final bool large;

  const ErrorTypeBadge({
    super.key,
    required this.errorType,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = ErrorTypeConfig.getColor(errorType);
    final icon = ErrorTypeConfig.getIcon(errorType);
    final label = ErrorTypeConfig.getLabel(errorType);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? PointageSpacing.md : PointageSpacing.sm,
        vertical: large ? PointageSpacing.sm : PointageSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: large ? 18 : 14,
            color: color,
          ),
          SizedBox(width: large ? PointageSpacing.sm : PointageSpacing.xs),
          Text(
            label,
            style: (large ? PointageTextStyles.label : PointageTextStyles.caption)
                .copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact badge for table cells
class ErrorTypeBadgeCompact extends StatelessWidget {
  final String errorType;

  const ErrorTypeBadgeCompact({super.key, required this.errorType});

  @override
  Widget build(BuildContext context) {
    final color = ErrorTypeConfig.getColor(errorType);

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
