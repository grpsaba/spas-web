import 'package:flutter/material.dart';

import '../models/pointing_method.dart';

/// "Géo" / "Photo" / "Photo (GPS indisponible)" with details in a tooltip.
/// Shows a discreet dash when an old pointing does not allow to tell.
class PointingMethodChip extends StatelessWidget {
  const PointingMethodChip({super.key, required this.info, this.dense = false});

  final PointingMethodInfo? info;
  final bool dense;

  static Color colorOf(PointingMethod method) {
    switch (method) {
      case PointingMethod.geo:
        return const Color(0xFF15803D);
      case PointingMethod.photo:
        return const Color(0xFF475569);
      case PointingMethod.photoFallback:
        return const Color(0xFFC2410C);
    }
  }

  static IconData iconOf(PointingMethod method) {
    switch (method) {
      case PointingMethod.geo:
        return Icons.gps_fixed;
      case PointingMethod.photo:
        return Icons.photo_camera_outlined;
      case PointingMethod.photoFallback:
        return Icons.gps_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = info;
    if (value == null) {
      return const Tooltip(
        message: 'Méthode non enregistrée (ancien pointage).',
        child: Text('—', style: TextStyle(color: Colors.black38)),
      );
    }
    final color = colorOf(value.method);
    return Tooltip(
      message: value.tooltip,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: dense ? 6 : 8, vertical: dense ? 2 : 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconOf(value.method), size: dense ? 11 : 13, color: color),
            const SizedBox(width: 4),
            Text(
              value.label,
              style: TextStyle(
                color: color,
                fontSize: dense ? 10.5 : 12,
                fontWeight: FontWeight.w600,
                fontStyle: value.inferred ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
