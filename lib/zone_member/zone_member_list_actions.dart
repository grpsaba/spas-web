import 'package:flutter/material.dart';

import '../pointage_redesign/presentation/design_system.dart';

class ZoneMemberListActions extends StatelessWidget {
  const ZoneMemberListActions({
    super.key,
    required this.onAdd,
    required this.onManualPointing,
  });

  final VoidCallback onAdd;
  final VoidCallback onManualPointing;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      visualDensity: VisualDensity.standard,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: onManualPointing,
          icon: const Icon(Icons.add_location_alt_outlined, size: 18),
          label: const Text('Pointage manuel'),
          style: style.copyWith(
            foregroundColor: const WidgetStatePropertyAll(Color(0xFF9B6200)),
            side: const WidgetStatePropertyAll(
              BorderSide(color: PointageColors.warning),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Ajouter'),
          style: style.copyWith(
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            backgroundColor:
                const WidgetStatePropertyAll(PointageColors.primary),
          ),
        ),
      ],
    );
  }
}
