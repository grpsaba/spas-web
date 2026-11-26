import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';

import '../models/error_log_model.dart';
import '../models/geo_diagnostic.dart';
import '../models/visit_timeline.dart';
import '../services/visit_timeline_service.dart';

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PointageSpacing.lg),
      decoration: PointageCardDecorations.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: PointageColors.primary),
              const SizedBox(width: PointageSpacing.sm),
              Expanded(
                child: Text(title, style: PointageTextStyles.headline4),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: PointageSpacing.sm),
          const Divider(),
          const SizedBox(height: PointageSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow(this.label, this.value, {this.selectable = false});

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final valueWidget = selectable
        ? SelectableText(value,
            style: PointageTextStyles.body2.copyWith(fontFamily: 'monospace'))
        : Text(value, style: PointageTextStyles.body2);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: PointageTextStyles.caption
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}

/// App version, phone and attempt fields of an error log.
class ErrorLogPhoneAttemptCard extends StatelessWidget {
  const ErrorLogPhoneAttemptCard({super.key, required this.log});

  final ErrorLog log;

  static bool hasContent(ErrorLog log) =>
      log.appVersion != null ||
      log.device != null ||
      log.visitId != null ||
      log.hasAttemptInfo ||
      log.geoSettings != null ||
      log.geoRuleVersion != null;

  @override
  Widget build(BuildContext context) {
    final device = log.device;
    final settings = geoSettingsLabel(log.geoSettings);
    return _SectionCard(
      title: 'Téléphone et essai GPS',
      icon: Icons.phone_android,
      children: [
        if (log.appVersion != null)
          _FactRow('Version de l\'app', log.appVersion!),
        if (device != null) ...[
          _FactRow('Téléphone', device.modelLabel),
          if (device.os != null) _FactRow('Système', device.os!),
          if (device.hardware != null) _FactRow('Matériel', device.hardware!),
        ],
        if (log.attemptNumber != null)
          _FactRow('Essai n°', '${log.attemptNumber}'),
        if (log.attemptOutcome != null)
          _FactRow('Résultat de l\'essai',
              '${AttemptOutcome.label(log.attemptOutcome)} (${log.attemptOutcome})'),
        if (log.attemptDurationMs != null)
          _FactRow(
              'Durée de l\'essai', formatDurationMs(log.attemptDurationMs)),
        if (settings != null) _FactRow('Réglage appliqué', settings),
        if (log.geoRuleVersion != null)
          _FactRow('Version de la règle GPS', '${log.geoRuleVersion}'),
        if (log.visitId != null)
          Row(
            children: [
              Expanded(
                child: _FactRow('Visite', log.visitId!, selectable: true),
              ),
              IconButton(
                tooltip: 'Copier l\'identifiant de visite',
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: log.visitId!)),
              ),
            ],
          ),
      ],
    );
  }
}

/// Readable summary of `geoDiagnostic`, including the GPS readings.
class GeoDiagnosticCard extends StatelessWidget {
  const GeoDiagnosticCard({super.key, required this.summary});

  final GeoDiagnosticSummary summary;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Diagnostic GPS du téléphone',
      icon: Icons.satellite_alt,
      children: [
        for (final fact in summary.facts) _FactRow(fact.key, fact.value),
        if (summary.readings.isNotEmpty) ...[
          const SizedBox(height: PointageSpacing.sm),
          Text(
            'Dernières positions reçues (${summary.readings.length})',
            style:
                PointageTextStyles.label.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          for (var i = 0; i < summary.readings.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${i + 1}. ${summary.readings[i].summary}',
                style: PointageTextStyles.body2.copyWith(
                  color: summary.readings[i].isMocked == true
                      ? PointageColors.error
                      : null,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// "Parcours de la visite": every log, phone action and pointing of a visit.
class VisitTimelineCard extends StatefulWidget {
  const VisitTimelineCard({
    super.key,
    required this.visitId,
    required this.currentLogId,
    this.onOpenErrorLog,
    this.loader,
  });

  final String visitId;
  final String currentLogId;
  final ValueChanged<ErrorLog>? onOpenErrorLog;

  /// Injected in tests; defaults to [VisitTimelineService].
  final Future<VisitTimelineResult> Function()? loader;

  @override
  State<VisitTimelineCard> createState() => _VisitTimelineCardState();
}

class _VisitTimelineCardState extends State<VisitTimelineCard> {
  late Future<VisitTimelineResult> _future = _load();

  Future<VisitTimelineResult> _load() =>
      widget.loader?.call() ??
      VisitTimelineService()
          .load(widget.visitId, currentErrorLogId: widget.currentLogId);

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Parcours de la visite',
      icon: Icons.timeline,
      trailing: IconButton(
        tooltip: 'Actualiser',
        icon: const Icon(Icons.refresh, size: 18),
        onPressed: () => setState(() => _future = _load()),
      ),
      children: [
        FutureBuilder<VisitTimelineResult>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(PointageSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text(
                  'Impossible de charger le parcours : ${snapshot.error}',
                  style: PointageTextStyles.body2
                      .copyWith(color: PointageColors.error));
            }
            final result = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (result.entries.isEmpty)
                  const Text('Aucun autre élément pour cette visite.',
                      style: PointageTextStyles.caption),
                for (final entry in result.entries) _buildEntry(entry),
                for (final warning in result.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('Non chargé — $warning',
                        style: PointageTextStyles.caption
                            .copyWith(color: PointageColors.warning)),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildEntry(VisitTimelineEntry entry) {
    final IconData icon;
    final Color color;
    switch (entry.kind) {
      case VisitTimelineKind.mobileEvent:
        icon = Icons.touch_app_outlined;
        color = PointageColors.textSecondary;
        break;
      case VisitTimelineKind.errorLog:
        icon = Icons.error_outline;
        color = PointageColors.error;
        break;
      case VisitTimelineKind.pointing:
        icon = Icons.check_circle;
        color = PointageColors.success;
        break;
    }
    final time = entry.time;
    final timeLabel = time == null
        ? '--:--:--'
        : '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}:'
            '${time.second.toString().padLeft(2, '0')}';
    final log = entry.errorLog;
    final canOpen =
        log != null && !entry.isCurrent && widget.onOpenErrorLog != null;

    return InkWell(
      onTap: canOpen ? () => widget.onOpenErrorLog!(log) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: entry.isCurrent
              ? PointageColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: PointageBorderRadius.small,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 68,
              child: Text(timeLabel,
                  style: PointageTextStyles.caption
                      .copyWith(fontFamily: 'monospace')),
            ),
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.isCurrent
                        ? '${entry.title} (cette erreur)'
                        : entry.title,
                    style: PointageTextStyles.body2.copyWith(
                      fontWeight:
                          entry.isCurrent ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  if (entry.detail != null && entry.detail!.isNotEmpty)
                    Text(entry.detail!, style: PointageTextStyles.caption),
                ],
              ),
            ),
            if (canOpen)
              const Icon(Icons.chevron_right,
                  size: 16, color: PointageColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
