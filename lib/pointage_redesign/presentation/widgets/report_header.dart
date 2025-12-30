import 'package:flutter/material.dart';
import '../design_system.dart';

/// A reusable header component for report pages
/// 
/// Displays a modern card with an icon, title, and description
/// following the design system specifications.
/// 
/// Requirements: 2.1, 2.2
class ReportHeader extends StatelessWidget {
  const ReportHeader({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.analytics_outlined,
    this.iconColor,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: PointageColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PointageSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                color: (iconColor ?? PointageColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: iconColor ?? PointageColors.primary,
              ),
            ),
            const SizedBox(width: PointageSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PointageTextStyles.headline2,
                  ),
                  const SizedBox(height: PointageSpacing.xs),
                  Text(
                    description,
                    style: PointageTextStyles.body2.copyWith(
                      color: PointageColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
