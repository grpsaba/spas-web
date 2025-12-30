import 'package:flutter/material.dart';
import '../design_system.dart';
import '../dialogs/modern_dialog.dart';
import 'tooltip_helper.dart';

/// Card displaying report generation progress with animated progress bar
class GenerationProgressCard extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final String currentStep;
  final bool canCancel;
  final VoidCallback? onCancel;
  final Duration? estimatedTimeRemaining;
  final int? currentItem;
  final int? totalItems;

  const GenerationProgressCard({
    Key? key,
    required this.progress,
    required this.currentStep,
    this.canCancel = true,
    this.onCancel,
    this.estimatedTimeRemaining,
    this.currentItem,
    this.totalItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toInt();
    
    return Container(
      decoration: PointageCardDecorations.standard,
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(PointageSpacing.sm),
                decoration: BoxDecoration(
                  color: PointageColors.primary.withOpacity(0.1),
                  borderRadius: PointageBorderRadius.medium,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  color: PointageColors.primary,
                  size: PointageIconSizes.md,
                ),
              ),
              const SizedBox(width: PointageSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Génération en cours',
                      style: PointageTextStyles.headline4,
                    ),
                    const SizedBox(height: PointageSpacing.xs),
                    Text(
                      currentStep,
                      style: PointageTextStyles.body2.copyWith(
                        color: PointageColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (canCancel && onCancel != null)
                TooltipHelper.iconButton(
                  tooltip: 'Annuler la génération',
                  shortcut: TooltipHelper.shortcutClose,
                  icon: Icons.close,
                  onPressed: () => _showCancelConfirmation(context),
                  color: PointageColors.textSecondary,
                ),
            ],
          ),
          
          const SizedBox(height: PointageSpacing.lg),
          
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$percentage%',
                    style: PointageTextStyles.headline3.copyWith(
                      color: PointageColors.primary,
                    ),
                  ),
                  if (currentItem != null && totalItems != null)
                    Text(
                      '$currentItem / $totalItems',
                      style: PointageTextStyles.body2.copyWith(
                        color: PointageColors.textSecondary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PointageSpacing.sm),
              ClipRRect(
                borderRadius: PointageBorderRadius.medium,
                child: SizedBox(
                  height: 8,
                  child: Stack(
                    children: [
                      // Background
                      Container(
                        color: PointageColors.divider,
                      ),
                      // Progress
                      AnimatedFractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        duration: PointageAnimations.normal,
                        curve: PointageAnimations.emphasizedCurve,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                PointageColors.primary,
                                PointageColors.secondary,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Estimated time remaining
          if (estimatedTimeRemaining != null) ...[
            const SizedBox(height: PointageSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  size: PointageIconSizes.xs,
                  color: PointageColors.textSecondary,
                ),
                const SizedBox(width: PointageSpacing.xs),
                Text(
                  'Temps restant estimé: ${_formatDuration(estimatedTimeRemaining!)}',
                  style: PointageTextStyles.caption,
                ),
              ],
            ),
          ],
          
          // Loading indicator
          const SizedBox(height: PointageSpacing.md),
          const LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(PointageColors.primary),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}min';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}min ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  void _showCancelConfirmation(BuildContext context) {
    ModernDialog.show(
      context: context,
      title: 'Annuler la génération',
      content: const Text(
        'Êtes-vous sûr de vouloir annuler la génération du rapport ? '
        'Toute progression sera perdue.',
      ),
      actions: [
        DialogAction(
          label: 'Non, continuer',
          onPressed: () => Navigator.of(context).pop(),
        ),
        DialogAction(
          label: 'Oui, annuler',
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          isDestructive: true,
        ),
      ],
    );
  }
}
