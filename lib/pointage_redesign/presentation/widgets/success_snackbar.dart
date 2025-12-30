import 'package:flutter/material.dart';
import '../design_system.dart';

/// Success notification snackbar with auto-dismiss and slide-in animation
class SuccessSnackbar {
  /// Show a success snackbar
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
    IconData icon = Icons.check_circle,
  }) {
    final snackBar = SnackBar(
      content: _SuccessSnackbarContent(
        message: message,
        icon: icon,
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(PointageSpacing.md),
      padding: EdgeInsets.zero,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Show a success snackbar for file download
  static void showDownloadSuccess(
    BuildContext context, {
    required String fileName,
    VoidCallback? onOpen,
  }) {
    show(
      context,
      message: 'Fichier téléchargé: $fileName',
      icon: Icons.download_done,
      actionLabel: onOpen != null ? 'Ouvrir' : null,
      onAction: onOpen,
    );
  }

  /// Show a success snackbar for data save
  static void showSaveSuccess(
    BuildContext context, {
    String message = 'Données enregistrées avec succès',
  }) {
    show(
      context,
      message: message,
      icon: Icons.save,
    );
  }

  /// Show a success snackbar for data deletion
  static void showDeleteSuccess(
    BuildContext context, {
    String message = 'Données supprimées avec succès',
    VoidCallback? onUndo,
  }) {
    show(
      context,
      message: message,
      icon: Icons.delete,
      actionLabel: onUndo != null ? 'Annuler' : null,
      onAction: onUndo,
    );
  }

  /// Show a success snackbar for data refresh
  static void showRefreshSuccess(
    BuildContext context, {
    String message = 'Données actualisées',
  }) {
    show(
      context,
      message: message,
      icon: Icons.refresh,
      duration: const Duration(seconds: 2),
    );
  }

  /// Show a success snackbar for report generation
  static void showReportSuccess(
    BuildContext context, {
    required String reportType,
    VoidCallback? onDownload,
  }) {
    show(
      context,
      message: 'Rapport $reportType généré avec succès',
      icon: Icons.description,
      actionLabel: onDownload != null ? 'Télécharger' : null,
      onAction: onDownload,
    );
  }
}

/// Internal widget for snackbar content
class _SuccessSnackbarContent extends StatefulWidget {
  final String message;
  final IconData icon;

  const _SuccessSnackbarContent({
    Key? key,
    required this.message,
    required this.icon,
  }) : super(key: key);

  @override
  State<_SuccessSnackbarContent> createState() => _SuccessSnackbarContentState();
}

class _SuccessSnackbarContentState extends State<_SuccessSnackbarContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PointageAnimations.normal,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: PointageAnimations.emphasizedCurve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                PointageColors.success,
                PointageColors.success.withOpacity(0.8),
              ],
            ),
            borderRadius: PointageBorderRadius.large,
            boxShadow: PointageShadows.lg,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: PointageSpacing.md,
            vertical: PointageSpacing.md,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(PointageSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: PointageIconSizes.md,
                ),
              ),
              
              const SizedBox(width: PointageSpacing.md),
              
              // Message
              Expanded(
                child: Text(
                  widget.message,
                  style: PointageTextStyles.body2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Info snackbar variant (blue color)
class InfoSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final snackBar = SnackBar(
      content: _InfoSnackbarContent(message: message),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(PointageSpacing.md),
      padding: EdgeInsets.zero,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class _InfoSnackbarContent extends StatelessWidget {
  final String message;

  const _InfoSnackbarContent({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PointageColors.primary,
        borderRadius: PointageBorderRadius.large,
        boxShadow: PointageShadows.lg,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PointageSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info,
              color: Colors.white,
              size: PointageIconSizes.md,
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Text(
              message,
              style: PointageTextStyles.body2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Warning snackbar variant (orange color)
class WarningSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final snackBar = SnackBar(
      content: _WarningSnackbarContent(message: message),
      backgroundColor: Colors.transparent,
      elevation: 0,
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(PointageSpacing.md),
      padding: EdgeInsets.zero,
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class _WarningSnackbarContent extends StatelessWidget {
  final String message;

  const _WarningSnackbarContent({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PointageColors.warning,
        borderRadius: PointageBorderRadius.large,
        boxShadow: PointageShadows.lg,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: PointageSpacing.md,
        vertical: PointageSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(PointageSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning,
              color: Colors.white,
              size: PointageIconSizes.md,
            ),
          ),
          const SizedBox(width: PointageSpacing.md),
          Expanded(
            child: Text(
              message,
              style: PointageTextStyles.body2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
