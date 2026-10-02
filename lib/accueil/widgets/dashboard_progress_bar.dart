import 'package:flutter/material.dart';

class DashboardProgressBar extends StatelessWidget {
  const DashboardProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.trackColor = const Color(0xFFE9EDF4),
    this.height = 8,
    this.duration = const Duration(milliseconds: 700),
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double height;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final target = (value.clamp(0, 100) / 100).toDouble();

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: height,
            color: trackColor,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              heightFactor: 1,
              child: ColoredBox(color: color),
            ),
          ),
        );
      },
    );
  }
}
