import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../services/monthly_pointing_calculator.dart';

class PointingControlColors {
  PointingControlColors._();

  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFDDE2EA);
  static const primary = Color(0xFF3F51B5);
  static const primarySoft = Color(0xFFEEF0FB);
  static const day = Color(0xFFB76E00);
  static const daySoft = Color(0xFFFFF7E8);
  static const night = Color(0xFF46506A);
  static const nightSoft = Color(0xFFE9ECF2);
  static const success = Color(0xFF198754);
  static const successSoft = Color(0xFFEAF7F0);
  static const warning = Color(0xFFB76E00);
  static const warningSoft = Color(0xFFFFF4DF);
  static const danger = Color(0xFFD14343);
  static const dangerSoft = Color(0xFFFDEEEE);
  static const info = Color(0xFF2878B8);
  static const infoSoft = Color(0xFFEAF4FB);
}

class PointingControlFormat {
  PointingControlFormat._();

  static const _months = <String>[
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  static const _weekdays = <String>[
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  static String month(DateTime date) {
    return '${_months[date.month - 1]} ${date.year}';
  }

  static String fullDate(DateTime date) {
    return '${_weekdays[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';
  }

  static String shortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String time(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static String dateTime(DateTime? date) {
    if (date == null) return 'À l’instant';
    return '${shortDate(date)} à ${time(date)}';
  }
}

class DailyStateVisual {
  const DailyStateVisual({
    required this.label,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color background;
  final IconData icon;

  static DailyStateVisual fromResult(DailyPointingResult result) {
    switch (result.state) {
      case DailyPointingState.future:
        return const DailyStateVisual(
          label: 'À venir',
          color: PointingControlColors.muted,
          background: Color(0xFFF1F3F6),
          icon: HugeIcons.strokeRoundedCalendar03,
        );
      case DailyPointingState.inProgress:
        return const DailyStateVisual(
          label: 'En cours',
          color: PointingControlColors.info,
          background: PointingControlColors.infoSoft,
          icon: HugeIcons.strokeRoundedClock03,
        );
      case DailyPointingState.noTarget:
        return const DailyStateVisual(
          label: 'Non planifié',
          color: PointingControlColors.muted,
          background: Color(0xFFF1F3F6),
          icon: HugeIcons.strokeRoundedInformationCircle,
        );
      case DailyPointingState.compliant:
        return const DailyStateVisual(
          label: 'Conforme',
          color: PointingControlColors.success,
          background: PointingControlColors.successSoft,
          icon: HugeIcons.strokeRoundedCheckmarkCircle01,
        );
      case DailyPointingState.partial:
      case DailyPointingState.missing:
        if (result.hasReason) {
          return const DailyStateVisual(
            label: 'Justifié',
            color: PointingControlColors.warning,
            background: PointingControlColors.warningSoft,
            icon: HugeIcons.strokeRoundedNoteEdit,
          );
        }
        return const DailyStateVisual(
          label: 'Motif requis',
          color: PointingControlColors.danger,
          background: PointingControlColors.dangerSoft,
          icon: HugeIcons.strokeRoundedAlertCircle,
        );
    }
  }
}

class ControlStatusBadge extends StatelessWidget {
  const ControlStatusBadge({super.key, required this.visual});

  final DailyStateVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 106),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: visual.background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(visual.icon, size: 15, color: visual.color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              visual.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: visual.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ControlAvatar extends StatelessWidget {
  const ControlAvatar({
    super.key,
    required this.initials,
    this.size = 40,
  });

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: PointingControlColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6DBF3)),
      ),
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: PointingControlColors.primary,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class ControlMetricTile extends StatelessWidget {
  const ControlMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.detail,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190, minHeight: 104),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PointingControlColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PointingControlColors.ink,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PointingControlColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ControlLoading extends StatelessWidget {
  const ControlLoading({super.key, this.label = 'Chargement des données…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(color: PointingControlColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class ControlError extends StatelessWidget {
  const ControlError({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PointingControlColors.dangerSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFF3CACA)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              HugeIcons.strokeRoundedAlertCircle,
              color: PointingControlColors.danger,
              size: 30,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PointingControlColors.ink),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(HugeIcons.strokeRoundedRefresh, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
