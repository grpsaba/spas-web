import 'package:flutter/material.dart';

import '../models/pointage_mode_override.dart';

/// "Mode de pointage" choice of a supervisor / zone chief.
/// `null` = follow the country (default), "photo" / "geo" = forced.
class PointageModeOverrideField extends StatelessWidget {
  const PointageModeOverrideField({
    super.key,
    required this.value,
    required this.countryMode,
    required this.onChanged,
    this.enabled = true,
    this.decoration,
  });

  final String? value;

  /// Current mode of the person's country for this role, if known.
  final String? countryMode;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final InputDecoration? decoration;

  // A non-null sentinel: DropdownButton treats a null value as "no selection".
  static const String _countryValue = 'country';

  @override
  Widget build(BuildContext context) {
    final current = PointageModeOverride.normalize(value) ?? _countryValue;
    final base = decoration ??
        InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: const Icon(Icons.rule_rounded),
        );
    return DropdownButtonFormField<String>(
      key: ValueKey('pointage-mode:$current:$countryMode'),
      initialValue: current,
      isExpanded: true,
      decoration: base.copyWith(
        labelText: 'Mode de pointage',
        helperText: current == _countryValue
            ? 'Suit le réglage du pays. Forcez un mode seulement pour un cas particulier.'
            : 'Ce mode s\'applique à cette personne quel que soit le réglage du pays.',
        helperMaxLines: 2,
      ),
      items: [
        DropdownMenuItem(
          value: _countryValue,
          child: Text(
              PointageModeOverride.optionLabel(null, countryMode: countryMode)),
        ),
        DropdownMenuItem(
          value: PointageModeOverride.photo,
          child: Text(
              PointageModeOverride.optionLabel(PointageModeOverride.photo)),
        ),
        DropdownMenuItem(
          value: PointageModeOverride.geo,
          child:
              Text(PointageModeOverride.optionLabel(PointageModeOverride.geo)),
        ),
      ],
      onChanged: enabled
          ? (selected) => onChanged(PointageModeOverride.normalize(selected))
          : null,
    );
  }
}

/// Small badge shown in lists when a person does not follow the country.
class PointageModeOverrideBadge extends StatelessWidget {
  const PointageModeOverrideBadge({super.key, required this.mode});

  /// Raw `pointageModeOverride` value.
  final String? mode;

  @override
  Widget build(BuildContext context) {
    final label = PointageModeOverride.badgeLabel(mode);
    if (label == null) return const SizedBox.shrink();
    final isGeo =
        PointageModeOverride.normalize(mode) == PointageModeOverride.geo;
    final color = isGeo ? const Color(0xFF1565C0) : const Color(0xFF6D4C41);
    return Tooltip(
      message:
          'Mode de pointage forcé pour cette personne (le réglage du pays est ignoré).',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isGeo ? Icons.gps_fixed : Icons.photo_camera,
                size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reminder shown next to the per-country modes.
class PointageModeOverrideHint extends StatelessWidget {
  const PointageModeOverrideHint({super.key});

  static const String message =
      'Un superviseur ou un chef de zone peut avoir un mode forcé dans sa fiche '
      '(« Toujours Photo » ou « Toujours Géolocalisation ») : il ignore alors le '
      'réglage de son pays. Ces personnes ont un badge dans les listes.';

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 16, color: Colors.blueGrey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
          ),
        ),
      ],
    );
  }
}
