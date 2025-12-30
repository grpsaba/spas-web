import 'dart:ui';
import 'package:flutter/material.dart';
import '../design_system.dart';
import '../widgets/tooltip_helper.dart';

/// Action button for ModernDialog
class DialogAction {
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const DialogAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}

/// Modern dialog component with rounded corners, smooth animations, and backdrop blur
class ModernDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<DialogAction> actions;
  final double maxWidth;

  const ModernDialog({
    Key? key,
    required this.title,
    required this.content,
    required this.actions,
    this.maxWidth = 500,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: PointageCardDecorations.elevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Padding(
                padding: const EdgeInsets.all(PointageSpacing.lg),
                child: Text(
                  title,
                  style: PointageTextStyles.headline3,
                ),
              ),
              
              // Divider
              const Divider(height: 1, color: PointageColors.divider),
              
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(PointageSpacing.lg),
                  child: content,
                ),
              ),
              
              // Actions
              if (actions.isNotEmpty) ...[
                const Divider(height: 1, color: PointageColors.divider),
                Padding(
                  padding: const EdgeInsets.all(PointageSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: _buildActionButtons(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final buttons = <Widget>[];
    
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      
      if (i > 0) {
        buttons.add(const SizedBox(width: PointageSpacing.sm));
      }
      
      buttons.add(_DialogActionButton(action: action));
    }
    
    return buttons;
  }

  /// Show the dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<DialogAction> actions,
    double maxWidth = 500,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => ModernDialog(
        title: title,
        content: content,
        actions: actions,
        maxWidth: maxWidth,
      ),
    );
  }
}

/// Internal widget for dialog action buttons
class _DialogActionButton extends StatefulWidget {
  final DialogAction action;

  const _DialogActionButton({
    Key? key,
    required this.action,
  }) : super(key: key);

  @override
  State<_DialogActionButton> createState() => _DialogActionButtonState();
}

class _DialogActionButtonState extends State<_DialogActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final action = widget.action;
    
    ButtonStyle style;
    String tooltipMessage = action.label;
    
    if (action.isPrimary) {
      style = PointageButtonStyles.primary;
      tooltipMessage = 'Confirmer: ${action.label}';
    } else if (action.isDestructive) {
      style = ElevatedButton.styleFrom(
        backgroundColor: PointageColors.error,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: PointageSpacing.lg,
          vertical: PointageSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: PointageBorderRadius.medium,
        ),
      );
      tooltipMessage = 'Action destructive: ${action.label}';
    } else {
      style = PointageButtonStyles.outlined;
    }

    return Tooltip(
      message: tooltipMessage,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isHovered ? 1.02 : 1.0,
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          child: ElevatedButton(
            onPressed: action.onPressed,
            style: action.isPrimary || action.isDestructive
                ? style
                : PointageButtonStyles.outlined,
            child: Text(action.label),
          ),
        ),
      ),
    );
  }
}
