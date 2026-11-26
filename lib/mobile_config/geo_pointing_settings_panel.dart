import 'package:flutter/material.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/services/geo_pointing_config.dart';

/// "Pointage par géolocalisation" block of the mobile configuration page.
///
/// Only bounded controls (stepper/slider/segmented buttons): no free typing,
/// so a value the phones would refuse can never be entered.
class GeoPointingSettingsPanel extends StatefulWidget {
  const GeoPointingSettingsPanel({
    super.key,
    required this.initial,
    required this.canEdit,
    required this.onSave,
    this.readOnlyReason,
  });

  final GeoPointingConfig initial;
  final bool canEdit;

  /// Persists the settings; the panel shows a confirmation first.
  final Future<void> Function(GeoPointingConfig config) onSave;
  final String? readOnlyReason;

  @override
  State<GeoPointingSettingsPanel> createState() =>
      _GeoPointingSettingsPanelState();
}

class _GeoPointingSettingsPanelState extends State<GeoPointingSettingsPanel> {
  late GeoPointingConfig _draft = widget.initial;
  bool _saving = false;

  @override
  void didUpdateWidget(covariant GeoPointingSettingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final saved = oldWidget.initial;
    // A new saved value replaces the draft only if it was not being edited.
    if (!identical(saved, widget.initial) && _draft.hasSameSettingsAs(saved)) {
      _draft = widget.initial;
    }
  }

  bool get _dirty => !_draft.hasSameSettingsAs(widget.initial);
  bool get _enabled => widget.canEdit && !_saving;

  void _update(GeoPointingConfig next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 14),
          _buildSummary(),
          if (!widget.canEdit && widget.readOnlyReason != null) ...[
            const SizedBox(height: 10),
            Text(
              widget.readOnlyReason!,
              style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          _SettingTile(
            title: 'Temps d\'attente du GPS par essai',
            help:
                'Durée max où le téléphone cherche la position avant d\'abandonner l\'essai.',
            recommended:
                'Recommandé : ${GeoPointingConfig.recommendedTimeoutSeconds} s'
                ' (entre ${GeoPointingConfig.minTimeoutSeconds} et ${GeoPointingConfig.maxTimeoutSeconds} s)',
            isRecommended: _draft.attemptTimeoutSeconds ==
                GeoPointingConfig.recommendedTimeoutSeconds,
            control: _buildTimeoutControl(),
          ),
          _SettingTile(
            title: 'Nombre d\'essais GPS avant la photo',
            help:
                'Nombre de recherches GPS faites avant d\'abandonner (et de proposer la photo si elle est autorisée).',
            recommended:
                'Recommandé : ${GeoPointingConfig.recommendedAttempts} (entre ${GeoPointingConfig.minAttempts} et ${GeoPointingConfig.maxAttempts})',
            isRecommended: _draft.attemptsBeforePhoto ==
                GeoPointingConfig.recommendedAttempts,
            control: SegmentedButton<int>(
              key: const ValueKey('geo-attempts'),
              showSelectedIcon: false,
              segments: [
                for (var value = GeoPointingConfig.minAttempts;
                    value <= GeoPointingConfig.maxAttempts;
                    value++)
                  ButtonSegment(
                    value: value,
                    label: Text(value == 1 ? '1 essai' : '$value essais'),
                  ),
              ],
              selected: {_draft.attemptsBeforePhoto},
              onSelectionChanged: _enabled
                  ? (values) => _update(
                      _draft.copyWith(attemptsBeforePhoto: values.first))
                  : null,
            ),
          ),
          _SettingTile(
            title: 'Proposer la photo si le GPS ne répond pas',
            help: 'Jamais proposée si le superviseur est loin du site.',
            recommended: 'Recommandé : Oui',
            isRecommended: _draft.photoFallbackEnabled ==
                GeoPointingConfig.recommendedPhotoFallbackEnabled,
            control: SegmentedButton<bool>(
              key: const ValueKey('geo-fallback'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: true, label: Text('Oui')),
                ButtonSegment(value: false, label: Text('Non')),
              ],
              selected: {_draft.photoFallbackEnabled},
              onSelectionChanged: _enabled
                  ? (values) => _update(
                      _draft.copyWith(photoFallbackEnabled: values.first))
                  : null,
            ),
          ),
          _SettingTile(
            title: 'Exigence de précision GPS',
            help:
                'Normale : accepte une position moins précise si elle est sans aucun doute dans le site. '
                'Stricte : ancienne règle, plus d\'échecs sur les téléphones bas de gamme.',
            recommended: 'Recommandé : Normale',
            isRecommended: _draft.accuracyRule ==
                GeoPointingConfig.recommendedAccuracyRule,
            isLast: true,
            control: SegmentedButton<String>(
              key: const ValueKey('geo-accuracy'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: GeoAccuracyRule.normal,
                  label: Text('Normale (recommandée)'),
                ),
                ButtonSegment(
                  value: GeoAccuracyRule.strict,
                  label: Text('Stricte'),
                ),
              ],
              selected: {_draft.accuracyRule},
              onSelectionChanged: _enabled
                  ? (values) =>
                      _update(_draft.copyWith(accuracyRule: values.first))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final modified = widget.initial.lastModifiedLabel;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.gps_fixed_rounded,
              color: AppConstants.primaryColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pointage par géolocalisation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'S\'applique seulement aux pays/rôles en mode Géolocalisation',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                modified ??
                    'Jamais modifié : les téléphones utilisent les valeurs recommandées.',
                key: const ValueKey('geo-last-modified'),
                style: const TextStyle(color: Colors.black45, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Container(
      key: const ValueKey('geo-summary'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.record_voice_over_outlined,
              color: Color(0xFF1D4ED8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _draft.summary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _draft.accuracySummary,
                  style:
                      const TextStyle(fontSize: 12.5, color: Color(0xFF1E40AF)),
                ),
                if (_dirty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Modifications non enregistrées : les téléphones utilisent encore l\'ancien réglage.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutControl() {
    const min = GeoPointingConfig.minTimeoutSeconds;
    const max = GeoPointingConfig.maxTimeoutSeconds;
    const step = GeoPointingConfig.timeoutStepSeconds;
    final value = _draft.attemptTimeoutSeconds;
    void set(int next) =>
        _update(_draft.copyWith(attemptTimeoutSeconds: next.clamp(min, max)));

    return Row(
      children: [
        IconButton.outlined(
          key: const ValueKey('geo-timeout-minus'),
          tooltip: 'Moins $step s',
          onPressed: _enabled && value > min ? () => set(value - step) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 64,
          child: Text(
            '$value s',
            key: const ValueKey('geo-timeout-value'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton.outlined(
          key: const ValueKey('geo-timeout-plus'),
          tooltip: 'Plus $step s',
          onPressed: _enabled && value < max ? () => set(value + step) : null,
          icon: const Icon(Icons.add),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            label: '$value s',
            onChanged: _enabled ? (v) => set(v.round()) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 12,
      runSpacing: 10,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('geo-recommended'),
          onPressed: _enabled && !_draft.isRecommended
              ? () => _update(_draft.withRecommendedValues())
              : null,
          icon: const Icon(Icons.auto_fix_high_rounded),
          label: const Text('Valeurs recommandées'),
        ),
        if (_dirty)
          TextButton(
            onPressed: _enabled ? () => _update(widget.initial) : null,
            child: const Text('Annuler les modifications'),
          ),
        ElevatedButton.icon(
          key: const ValueKey('geo-save'),
          onPressed: _enabled && (_dirty || !widget.initial.isStored)
              ? _confirmAndSave
              : null,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_rounded),
          label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _confirmAndSave() async {
    final draft = _draft;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appliquer ce réglage aux téléphones ?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Les téléphones des pays/rôles en mode Géolocalisation '
                'appliqueront ce réglage dès leur prochaine connexion :',
              ),
              const SizedBox(height: 10),
              Text(draft.summary,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text(draft.accuracySummary),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            key: const ValueKey('geo-confirm-save'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(draft);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.help,
    required this.recommended,
    required this.isRecommended,
    required this.control,
    this.isLast = false,
  });

  final String title;
  final String help;
  final String recommended;
  final bool isRecommended;
  final Widget control;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(help, style: const TextStyle(color: Colors.black87, fontSize: 13)),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isRecommended ? Icons.check_circle : Icons.info_outline,
              size: 14,
              color: isRecommended ? Colors.green.shade700 : Colors.black45,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                isRecommended ? '$recommended · valeur choisie' : recommended,
                style: TextStyle(
                  fontSize: 12,
                  color: isRecommended ? Colors.green.shade800 : Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF0F1F4))),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [details, const SizedBox(height: 10), control],
          );
        }
        return Row(
          children: [
            Expanded(flex: 5, child: details),
            const SizedBox(width: 20),
            Expanded(
                flex: 5,
                child: Align(alignment: Alignment.centerLeft, child: control)),
          ],
        );
      }),
    );
  }
}
