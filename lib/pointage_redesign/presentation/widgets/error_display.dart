import 'package:flutter/material.dart';
import '../../models/pointage_exception.dart';
import '../design_system.dart';
import 'tooltip_helper.dart';

/// Display component for user-friendly error messages with retry functionality
class ErrorDisplay extends StatelessWidget {
  final PointageException? exception;
  final String? customMessage;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorDisplay({
    Key? key,
    this.exception,
    this.customMessage,
    this.onRetry,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (exception == null && customMessage == null) {
      return const SizedBox.shrink();
    }

    final errorType = exception?.type ?? PointageErrorType.unknown;
    final message = customMessage ?? exception?.userMessage ?? 'Une erreur est survenue';
    final canRetry = exception?.isRetryable ?? (onRetry != null);

    if (compact) {
      return _buildCompactError(message, errorType, canRetry);
    }

    return _buildFullError(message, errorType, canRetry);
  }

  Widget _buildFullError(String message, PointageErrorType errorType, bool canRetry) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(errorType),
        borderRadius: PointageBorderRadius.large,
        border: Border.all(
          color: _getBorderColor(errorType),
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(PointageSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(PointageSpacing.md),
            decoration: BoxDecoration(
              color: _getIconBackgroundColor(errorType),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(errorType),
              color: _getIconColor(errorType),
              size: PointageIconSizes.xl,
            ),
          ),
          
          const SizedBox(height: PointageSpacing.lg),
          
          // Title
          Text(
            _getTitle(errorType),
            style: PointageTextStyles.headline4.copyWith(
              color: _getTextColor(errorType),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: PointageSpacing.sm),
          
          // Message
          Text(
            message,
            style: PointageTextStyles.body2.copyWith(
              color: PointageColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Suggestions
          if (_getSuggestions(errorType).isNotEmpty) ...[
            const SizedBox(height: PointageSpacing.md),
            Container(
              padding: const EdgeInsets.all(PointageSpacing.md),
              decoration: BoxDecoration(
                color: PointageColors.background,
                borderRadius: PointageBorderRadius.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: PointageIconSizes.sm,
                        color: PointageColors.warning,
                      ),
                      const SizedBox(width: PointageSpacing.xs),
                      Text(
                        'Suggestions:',
                        style: PointageTextStyles.label,
                      ),
                    ],
                  ),
                  const SizedBox(height: PointageSpacing.sm),
                  ..._getSuggestions(errorType).map((suggestion) => Padding(
                        padding: const EdgeInsets.only(bottom: PointageSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: PointageTextStyles.body2),
                            Expanded(
                              child: Text(
                                suggestion,
                                style: PointageTextStyles.body2,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
          
          // Retry button
          if (canRetry && onRetry != null) ...[
            const SizedBox(height: PointageSpacing.lg),
            TooltipHelper.elevatedButton(
              tooltip: TooltipHelper.retry,
              shortcut: TooltipHelper.shortcutRefresh,
              label: 'Réessayer',
              icon: Icons.refresh,
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getIconColor(errorType),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: PointageSpacing.xl,
                  vertical: PointageSpacing.md,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactError(String message, PointageErrorType errorType, bool canRetry) {
    return Container(
      decoration: BoxDecoration(
        color: _getBackgroundColor(errorType),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(
          color: _getBorderColor(errorType),
        ),
      ),
      padding: const EdgeInsets.all(PointageSpacing.md),
      child: Row(
        children: [
          Icon(
            _getIcon(errorType),
            color: _getIconColor(errorType),
            size: PointageIconSizes.md,
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Text(
              message,
              style: PointageTextStyles.body2.copyWith(
                color: _getTextColor(errorType),
              ),
            ),
          ),
          if (canRetry && onRetry != null) ...[
            const SizedBox(width: PointageSpacing.md),
            TooltipHelper.iconButton(
              tooltip: TooltipHelper.retry,
              shortcut: TooltipHelper.shortcutRefresh,
              icon: Icons.refresh,
              onPressed: onRetry,
              color: _getIconColor(errorType),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIcon(PointageErrorType type) {
    switch (type) {
      case PointageErrorType.networkError:
        return Icons.wifi_off;
      case PointageErrorType.permissionDenied:
        return Icons.lock_outline;
      case PointageErrorType.dataNotFound:
        return Icons.search_off;
      case PointageErrorType.invalidInput:
        return Icons.error_outline;
      case PointageErrorType.generationFailed:
        return Icons.description_outlined;
      case PointageErrorType.cacheError:
        return Icons.storage_outlined;
      case PointageErrorType.queryError:
        return Icons.error_outline;
      case PointageErrorType.timeout:
        return Icons.access_time;
      case PointageErrorType.cancelled:
        return Icons.cancel_outlined;
      case PointageErrorType.unknown:
        return Icons.warning_outlined;
    }
  }

  String _getTitle(PointageErrorType type) {
    switch (type) {
      case PointageErrorType.networkError:
        return 'Problème de connexion';
      case PointageErrorType.permissionDenied:
        return 'Accès refusé';
      case PointageErrorType.dataNotFound:
        return 'Données introuvables';
      case PointageErrorType.invalidInput:
        return 'Données invalides';
      case PointageErrorType.generationFailed:
        return 'Échec de génération';
      case PointageErrorType.cacheError:
        return 'Erreur de cache';
      case PointageErrorType.queryError:
        return 'Erreur de requête';
      case PointageErrorType.timeout:
        return 'Délai dépassé';
      case PointageErrorType.cancelled:
        return 'Opération annulée';
      case PointageErrorType.unknown:
        return 'Erreur';
    }
  }

  Color _getIconColor(PointageErrorType type) {
    switch (type) {
      case PointageErrorType.networkError:
        return PointageColors.warning;
      case PointageErrorType.permissionDenied:
        return PointageColors.error;
      case PointageErrorType.dataNotFound:
        return PointageColors.secondary;
      case PointageErrorType.invalidInput:
        return PointageColors.warning;
      case PointageErrorType.generationFailed:
        return PointageColors.error;
      case PointageErrorType.cacheError:
        return PointageColors.warning;
      case PointageErrorType.queryError:
        return PointageColors.error;
      case PointageErrorType.timeout:
        return PointageColors.warning;
      case PointageErrorType.cancelled:
        return PointageColors.secondary;
      case PointageErrorType.unknown:
        return PointageColors.error;
    }
  }

  Color _getIconBackgroundColor(PointageErrorType type) {
    return _getIconColor(type).withOpacity(0.1);
  }

  Color _getBackgroundColor(PointageErrorType type) {
    return _getIconColor(type).withOpacity(0.05);
  }

  Color _getBorderColor(PointageErrorType type) {
    return _getIconColor(type).withOpacity(0.3);
  }

  Color _getTextColor(PointageErrorType type) {
    return _getIconColor(type);
  }

  List<String> _getSuggestions(PointageErrorType type) {
    switch (type) {
      case PointageErrorType.networkError:
        return [
          'Vérifiez votre connexion Internet',
          'Réessayez dans quelques instants',
          'Contactez votre administrateur si le problème persiste',
        ];
      case PointageErrorType.permissionDenied:
        return [
          'Vérifiez que vous êtes connecté',
          'Contactez votre administrateur pour obtenir les permissions nécessaires',
        ];
      case PointageErrorType.dataNotFound:
        return [
          'Vérifiez vos critères de recherche',
          'Essayez d\'élargir la période de recherche',
          'Assurez-vous que les données existent',
        ];
      case PointageErrorType.invalidInput:
        return [
          'Vérifiez les données saisies',
          'Assurez-vous que tous les champs requis sont remplis',
          'Vérifiez le format des dates',
        ];
      case PointageErrorType.generationFailed:
        return [
          'Réduisez la période de génération',
          'Essayez de générer le rapport plus tard',
          'Contactez le support si le problème persiste',
        ];
      case PointageErrorType.cacheError:
        return [
          'Essayez de rafraîchir la page',
          'Videz le cache de votre navigateur',
        ];
      case PointageErrorType.queryError:
        return [
          'Simplifiez vos filtres de recherche',
          'Réessayez dans quelques instants',
          'Contactez le support si le problème persiste',
        ];
      case PointageErrorType.timeout:
        return [
          'Réduisez la période de recherche',
          'Simplifiez vos filtres',
          'Réessayez dans quelques instants',
        ];
      case PointageErrorType.cancelled:
        return [];
      case PointageErrorType.unknown:
        return [
          'Réessayez l\'opération',
          'Rafraîchissez la page',
          'Contactez le support si le problème persiste',
        ];
    }
  }
}
