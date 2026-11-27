import 'package:flutter/material.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';

import '../services/geo_tracking_service.dart';

/// Last 7 days, today included.
DateTimeRange defaultGeoRange([DateTime? now]) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  return DateTimeRange(
    start: today.subtract(const Duration(days: 6)),
    end: today,
  );
}

String formatGeoDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

Future<DateTimeRange?> _pickRange(
    BuildContext context, DateTimeRange current) async {
  final picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2024),
    lastDate: DateUtils.dateOnly(DateTime.now()),
    initialDateRange: current,
    helpText: 'Période (${GeoTrackingService.maxRangeDays} jours max)',
  );
  if (picked == null) return null;
  final days = picked.end.difference(picked.start).inDays + 1;
  if (days > GeoTrackingService.maxRangeDays) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Période trop longue : ${GeoTrackingService.maxRangeDays} jours maximum.'),
      ));
    }
    return null;
  }
  return picked;
}

/// « Du 20/11/2026 au 26/11/2026 », opens the range picker (bounded).
class GeoRangeButton extends StatelessWidget {
  const GeoRangeButton({super.key, required this.range, required this.onChanged});

  final DateTimeRange range;
  final ValueChanged<DateTimeRange> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await _pickRange(context, range);
        if (picked != null) onChanged(picked);
      },
      icon: const Icon(Icons.date_range, size: 18),
      label: Text(
          'Du ${formatGeoDay(range.start)} au ${formatGeoDay(range.end)}'),
    );
  }
}

class GeoNotice extends StatelessWidget {
  const GeoNotice(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PointageSpacing.sm),
      child: Text(text,
          style:
              PointageTextStyles.body2.copyWith(color: PointageColors.warning)),
    );
  }
}

class GeoKpi extends StatelessWidget {
  const GeoKpi(this.label, this.value, this.color,
      {super.key, this.tooltip, this.large = false});

  final String label;
  final String value;
  final Color color;
  final String? tooltip;

  /// Bigger tile for the headline figure.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      constraints: BoxConstraints(minWidth: large ? 200 : 130),
      padding: EdgeInsets.symmetric(
          horizontal: large ? 18 : 14, vertical: large ? 14 : 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: large ? 0.12 : 0.07),
        borderRadius: PointageBorderRadius.medium,
        border: Border.all(
            color: color.withValues(alpha: large ? 0.5 : 0.25),
            width: large ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: (large
                      ? PointageTextStyles.headline2
                      : PointageTextStyles.headline4)
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
          Text(label,
              style: large
                  ? PointageTextStyles.body2
                      .copyWith(fontWeight: FontWeight.w600)
                  : PointageTextStyles.caption),
        ],
      ),
    );
    return tooltip == null ? tile : Tooltip(message: tooltip!, child: tile);
  }
}
