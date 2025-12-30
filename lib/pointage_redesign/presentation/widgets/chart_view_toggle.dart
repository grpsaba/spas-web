import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../design_system.dart';
import 'tooltip_helper.dart';

/// Chart view toggle widget with preference persistence
/// 
/// Allows switching between table and chart views with smooth animations
/// Requirements: 7.4
class ChartViewToggle extends StatefulWidget {
  final ViewMode initialMode;
  final Function(ViewMode) onModeChanged;
  final String preferenceKey;

  const ChartViewToggle({
    Key? key,
    this.initialMode = ViewMode.table,
    required this.onModeChanged,
    required this.preferenceKey,
  }) : super(key: key);

  @override
  State<ChartViewToggle> createState() => _ChartViewToggleState();
}

class _ChartViewToggleState extends State<ChartViewToggle> {
  late ViewMode _currentMode;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final savedMode = _prefs?.getString(widget.preferenceKey);
      if (savedMode != null) {
        final mode = ViewMode.values.firstWhere(
          (m) => m.toString() == savedMode,
          orElse: () => widget.initialMode,
        );
        if (mounted && mode != _currentMode) {
          setState(() {
            _currentMode = mode;
          });
          widget.onModeChanged(mode);
        }
      }
    } catch (e) {
      debugPrint('Error loading view mode preference: $e');
    }
  }

  Future<void> _savePreference(ViewMode mode) async {
    try {
      await _prefs?.setString(widget.preferenceKey, mode.toString());
    } catch (e) {
      debugPrint('Error saving view mode preference: $e');
    }
  }

  void _toggleMode(ViewMode mode) {
    if (_currentMode != mode) {
      setState(() {
        _currentMode = mode;
      });
      widget.onModeChanged(mode);
      _savePreference(mode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PointageColors.background,
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(
          color: PointageColors.divider,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            icon: Icons.table_chart,
            label: 'Tableau',
            mode: ViewMode.table,
            isSelected: _currentMode == ViewMode.table,
          ),
          Container(
            width: 1,
            height: 32,
            color: PointageColors.divider,
          ),
          _buildToggleButton(
            icon: Icons.bar_chart,
            label: 'Graphique',
            mode: ViewMode.chart,
            isSelected: _currentMode == ViewMode.chart,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required ViewMode mode,
    required bool isSelected,
  }) {
    final tooltipMessage = mode == ViewMode.table
        ? 'Afficher en mode tableau'
        : 'Afficher en mode graphique';
    
    return Tooltip(
      message: tooltipMessage,
      child: InkWell(
        onTap: () => _toggleMode(mode),
        borderRadius: PointageBorderRadius.medium,
        child: AnimatedContainer(
          duration: PointageAnimations.fast,
          curve: PointageAnimations.defaultCurve,
          padding: const EdgeInsets.symmetric(
            horizontal: PointageSpacing.md,
            vertical: PointageSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isSelected ? PointageColors.primary : Colors.transparent,
            borderRadius: PointageBorderRadius.medium,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: PointageIconSizes.sm,
                color: isSelected ? Colors.white : PointageColors.textSecondary,
              ),
              const SizedBox(width: PointageSpacing.xs),
              Text(
                label,
                style: PointageTextStyles.label.copyWith(
                  color: isSelected ? Colors.white : PointageColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// View mode enum
enum ViewMode {
  table,
  chart,
}

/// Animated view switcher widget
/// 
/// Provides smooth transition between table and chart views
class AnimatedViewSwitcher extends StatelessWidget {
  final ViewMode currentMode;
  final Widget tableView;
  final Widget chartView;

  const AnimatedViewSwitcher({
    Key? key,
    required this.currentMode,
    required this.tableView,
    required this.chartView,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: PointageAnimations.normal,
      switchInCurve: PointageAnimations.emphasizedCurve,
      switchOutCurve: PointageAnimations.emphasizedCurve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: currentMode == ViewMode.table
          ? Container(
              key: const ValueKey('table'),
              child: tableView,
            )
          : Container(
              key: const ValueKey('chart'),
              child: chartView,
            ),
    );
  }
}
