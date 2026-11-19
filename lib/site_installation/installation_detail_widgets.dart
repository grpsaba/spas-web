import 'package:flutter/material.dart';

import 'installation_order.dart';
import 'installation_ui.dart';

String installationPointageLabel(String type) =>
    const {
      'jour': 'Jour',
      'nuit': 'Nuit',
      'jour_nuit': 'Jour et nuit',
    }[type] ??
    'Jour';

String installationPersonName(Map<String, dynamic>? data) =>
    '${data?['firstName'] ?? ''} ${data?['lastName'] ?? ''}'.trim();

/// Tabs of a request (form, PDF preview, follow-up, signed document).
class InstallationTab {
  const InstallationTab(this.id, this.label, this.icon);
  final int id;
  final String label;
  final IconData icon;
}

class InstallationTabs extends StatelessWidget {
  const InstallationTabs(
      {super.key,
      required this.tabs,
      required this.selected,
      required this.onSelected});
  final List<InstallationTab> tabs;
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: const Color(0xFFE9EDF4),
          borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final tab in tabs)
              Semantics(
                  selected: tab.id == selected,
                  button: true,
                  child: Material(
                      color: tab.id == selected
                          ? Colors.white
                          : Colors.transparent,
                      elevation: tab.id == selected ? 1 : 0,
                      shadowColor: Colors.black26,
                      borderRadius: BorderRadius.circular(9),
                      child: InkWell(
                          borderRadius: BorderRadius.circular(9),
                          onTap: () => onSelected(tab.id),
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(minHeight: 42),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(tab.icon,
                                            size: 17,
                                            color: tab.id == selected
                                                ? InstallationStyle.primary
                                                : InstallationStyle.muted),
                                        const SizedBox(width: 7),
                                        Text(tab.label,
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: tab.id == selected
                                                    ? InstallationStyle.ink
                                                    : InstallationStyle.muted)),
                                      ])))))),
          ])));
}

/// Status, who acts next and the overall progress of a request.
class InstallationNextStepCard extends StatelessWidget {
  const InstallationNextStepCard(
      {super.key,
      required this.status,
      required this.guidance,
      this.badgeLabel,
      this.showProgress = true,
      this.extra});
  final InstallationStatus status;
  final InstallationGuidance guidance;
  final String? badgeLabel;
  final bool showProgress;
  final Widget? extra;
  @override
  Widget build(BuildContext context) {
    final mine = guidance.owner == 'À vous';
    final text =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            InstallationStatusBadge(status, label: badgeLabel),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                    color: mine
                        ? InstallationStyle.primary
                        : InstallationStyle.background,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(guidance.owner,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: mine ? Colors.white : InstallationStyle.muted))),
          ]),
      const SizedBox(height: 12),
      const Text('PROCHAINE ÉTAPE', style: InstallationStyle.overline),
      const SizedBox(height: 4),
      Text(guidance.title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: InstallationStyle.ink)),
      const SizedBox(height: 4),
      Text(guidance.detail,
          style: const TextStyle(
              fontSize: 13.5, height: 1.5, color: InstallationStyle.muted)),
      if (extra != null) ...[const SizedBox(height: 10), extra!],
    ]);
    return InstallationPanel(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
            builder: (context, c) => !showProgress
                ? text
                : c.maxWidth < 760
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            text,
                            const SizedBox(height: 16),
                            InstallationProgress(status),
                          ])
                    : Row(children: [
                        Expanded(child: text),
                        const SizedBox(width: 32),
                        SizedBox(
                            width: 360, child: InstallationProgress(status)),
                      ])));
  }
}

class _Value {
  const _Value(this.label, this.value, {this.required = true});
  final String label;
  final String value;
  final bool required;
}

class _Values extends StatelessWidget {
  const _Values(this.values);
  final List<_Value> values;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final columns = c.maxWidth >= 560 ? 2 : 1;
        final width = (c.maxWidth - (columns - 1) * 20) / columns;
        return Wrap(spacing: 20, runSpacing: 14, children: [
          for (final entry in values)
            SizedBox(
                width: width,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.label, style: InstallationStyle.caption),
                      const SizedBox(height: 3),
                      Text(
                          entry.value.isEmpty
                              ? entry.required
                                  ? 'À compléter'
                                  : 'Non renseigné'
                              : entry.value,
                          style: TextStyle(
                              color: entry.value.isEmpty
                                  ? entry.required
                                      ? InstallationStyle.warning
                                      : InstallationStyle.muted
                                  : InstallationStyle.ink,
                              fontWeight: FontWeight.w500,
                              fontSize: 14)),
                    ])),
        ]);
      });
}

/// Request displayed without form controls (transmitted, approved…).
class InstallationReadOnly extends StatelessWidget {
  const InstallationReadOnly(this.order, {super.key});
  final InstallationOrder order;

  Widget _section(String title, Widget child, {String? count}) =>
      InstallationPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(title, style: InstallationStyle.sectionTitle)),
          if (count != null)
            Text(count,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: InstallationStyle.muted)),
        ]),
        const SizedBox(height: 14),
        child,
      ]));

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _section(
            'Site et client',
            _Values([
              _Value('Client', order.clientName),
              _Value('Site', order.siteName),
              _Value('Adresse', order.address),
              _Value('Téléphone du contact', order.phone),
              _Value('Prestation', order.serviceLabel),
              if (order.bonNumber.isNotEmpty)
                _Value('Numéro du bon', order.bonNumber),
            ])),
        const SizedBox(height: 12),
        _section(
            'Agents prévus',
            order.agents.isEmpty
                ? const Text('Aucun agent renseigné.',
                    style: TextStyle(
                        color: InstallationStyle.warning, fontSize: 13))
                : Column(children: [
                    for (var i = 0; i < order.agents.length; i++)
                      Padding(
                          padding: EdgeInsets.only(
                              bottom: i == order.agents.length - 1 ? 0 : 12),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                    radius: 15,
                                    backgroundColor:
                                        InstallationStyle.background,
                                    child: Text('${i + 1}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: InstallationStyle.muted))),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(
                                          order.agents[i].name.isEmpty
                                              ? 'Nom à compléter'
                                              : order.agents[i].name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: InstallationStyle.ink)),
                                      Text(
                                          [
                                            order.agents[i].type,
                                            order.agents[i].phone
                                          ]
                                              .where((s) => s.isNotEmpty)
                                              .join(' · '),
                                          style: InstallationStyle.caption)
                                    ]))
                              ])),
                  ]),
            count: '${order.agents.length}'),
        const SizedBox(height: 12),
        _section(
            'Équipements',
            order.equipment.isEmpty
                ? const Text('Aucun équipement renseigné.',
                    style: TextStyle(
                        color: InstallationStyle.warning, fontSize: 13))
                : Column(children: [
                    for (final item in order.equipment)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Row(children: [
                            const Icon(Icons.inventory_2_outlined,
                                size: 17, color: InstallationStyle.muted),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(
                                    item.designation.isEmpty
                                        ? 'Désignation à compléter'
                                        : item.designation,
                                    style: const TextStyle(
                                        color: InstallationStyle.ink))),
                            Text('× ${item.quantity}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: InstallationStyle.ink))
                          ])),
                  ]),
            count: '${order.equipment.length}'),
        const SizedBox(height: 12),
        _section(
            'Organisation du site',
            _Values([
              _Value('Zone', order.zone?['name'] as String? ?? ''),
              _Value('Superviseur', installationPersonName(order.supervisor)),
              _Value('Second superviseur',
                  installationPersonName(order.supervisor2),
                  required: false),
              _Value('Effectif et rondes',
                  '${order.agentCount} agent(s) · ${order.roundCount} ronde(s)'),
              _Value('Pointage', installationPointageLabel(order.pointageType)),
              _Value(
                  'Date du contrat',
                  order.contractDate == null
                      ? ''
                      : installationDateLabel(order.contractDate)),
              _Value(
                  'Position GPS',
                  order.latitude != null && order.longitude != null
                      ? '${order.latitude}, ${order.longitude}'
                      : '',
                  required: false),
            ])),
      ]);
}

class InstallationEventTile extends StatelessWidget {
  const InstallationEventTile(
      {super.key, required this.event, this.pending = false});
  final Map<String, dynamic> event;
  final bool pending;
  @override
  Widget build(BuildContext context) {
    final comment = event['kind'] == 'comment';
    final author = installationMap(event['author'])['name'] as String? ?? '';
    final at = installationDate(event['at']);
    final when = pending
        ? 'En attente d’envoi'
        : at == null
            ? ''
            : '${installationDateLabel(at)} · ${installationTimeLabel(at)}';
    final message = event['message'] as String? ?? '';
    if (!comment) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                    color: InstallationStyle.background,
                    shape: BoxShape.circle),
                child: Icon(
                    event['kind'] == 'attachment'
                        ? Icons.attach_file
                        : Icons.flag_outlined,
                    size: 14,
                    color: InstallationStyle.muted)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(message,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: InstallationStyle.ink)),
                  const SizedBox(height: 2),
                  Text(
                      [if (author.isNotEmpty) author, if (when.isNotEmpty) when]
                          .join(' · '),
                      style: const TextStyle(
                          color: InstallationStyle.muted, fontSize: 11.5)),
                ])),
          ]));
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
              radius: 14,
              backgroundColor: InstallationStyle.primarySoft,
              child: Text(
                  author.isEmpty ? '?' : author.characters.first.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: InstallationStyle.primary))),
          const SizedBox(width: 12),
          Expanded(
              child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                      color: pending
                          ? InstallationStyle.warningSoft
                          : InstallationStyle.background,
                      borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12))),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author.isEmpty ? 'Suivi du dossier' : author,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: InstallationStyle.ink)),
                        const SizedBox(height: 4),
                        SelectableText(message,
                            style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: InstallationStyle.ink)),
                        const SizedBox(height: 4),
                        Row(children: [
                          if (pending) ...[
                            const Icon(Icons.schedule,
                                size: 13, color: InstallationStyle.warning),
                            const SizedBox(width: 4),
                          ],
                          Text(when,
                              style: TextStyle(
                                  color: pending
                                      ? InstallationStyle.warning
                                      : InstallationStyle.muted,
                                  fontSize: 11.5)),
                        ]),
                      ]))),
        ]));
  }
}

/// Message field of the follow-up tab. It keeps its own text and errors.
class InstallationCommentComposer extends StatefulWidget {
  const InstallationCommentComposer(
      {super.key,
      required this.onSend,
      this.enabled = true,
      this.hint = 'Écrire un message…',
      this.note});
  final Future<void> Function(String message) onSend;
  final bool enabled;
  final String hint;
  final String? note;
  @override
  State<InstallationCommentComposer> createState() =>
      _InstallationCommentComposerState();
}

class _InstallationCommentComposerState
    extends State<InstallationCommentComposer> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.onSend(text);
      _controller.clear();
    } catch (error) {
      _error = installationReadableError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
              child: TextField(
                  controller: _controller,
                  enabled: widget.enabled && !_sending,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 4000,
                  textCapitalization: TextCapitalization.sentences,
                  buildCounter: (context,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      currentLength > 3500
                          ? Text('$currentLength / $maxLength')
                          : null,
                  decoration: InputDecoration(
                      hintText: widget.hint, errorText: _error))),
          const SizedBox(width: 8),
          Padding(
              padding: EdgeInsets.only(bottom: _error == null ? 0 : 26),
              child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) => IconButton.filled(
                      tooltip: 'Envoyer le message',
                      style: IconButton.styleFrom(
                          backgroundColor: InstallationStyle.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 48)),
                      onPressed: !widget.enabled ||
                              _sending ||
                              value.text.trim().isEmpty
                          ? null
                          : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 20)))),
        ]),
        if (widget.note != null) ...[
          const SizedBox(height: 6),
          Text(widget.note!, style: InstallationStyle.caption),
        ],
      ]);
}

/// Comments and history of a request, newest first.
class InstallationFollowUp extends StatelessWidget {
  const InstallationFollowUp(
      {super.key,
      required this.events,
      this.pendingIds = const {},
      this.loading = false,
      this.error,
      this.onRetry,
      this.onSend,
      this.composerEnabled = true,
      this.composerHint = 'Écrire un message…',
      this.composerNote,
      this.subtitle =
          'Les échanges avec le bureau et les étapes du dossier sont conservés ici.',
      this.emptyMessage = 'Aucun échange pour le moment.'});

  /// Events in chronological order.
  final List<Map<String, dynamic>> events;
  final Set<String> pendingIds;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;
  final Future<void> Function(String message)? onSend;
  final bool composerEnabled;
  final String composerHint;
  final String? composerNote;
  final String subtitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final ordered = events.reversed.toList();
    return InstallationPanel(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const Text('Suivi', style: InstallationStyle.sectionTitle),
      const SizedBox(height: 4),
      Text(subtitle, style: InstallationStyle.caption),
      if (onSend != null) ...[
        const SizedBox(height: 16),
        InstallationCommentComposer(
            onSend: onSend!,
            enabled: composerEnabled,
            hint: composerHint,
            note: composerNote),
      ],
      const SizedBox(height: 8),
      const Divider(height: 24),
      if (error != null)
        InstallationNotice(
            tone: InstallationTone.error,
            message: error!,
            action: onRetry == null
                ? null
                : TextButton(
                    onPressed: onRetry, child: const Text('Réessayer')))
      else if (loading)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.5))))
      else if (ordered.isEmpty)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(emptyMessage,
                textAlign: TextAlign.center, style: InstallationStyle.caption))
      else
        for (final event in ordered)
          InstallationEventTile(
              event: event,
              pending: pendingIds.contains(event['id'] as String? ?? '')),
    ]));
  }
}

class InstallationAttachmentList extends StatelessWidget {
  const InstallationAttachmentList(
      {super.key, required this.attachments, required this.onOpen});
  final List<Map<String, dynamic>> attachments;
  final ValueChanged<Map<String, dynamic>> onOpen;
  @override
  Widget build(BuildContext context) => attachments.isEmpty
      ? const InstallationNotice(
          icon: Icons.description_outlined,
          message: 'Aucun document joint pour le moment.')
      : Column(children: [
          for (final attachment in attachments)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                    color: InstallationStyle.background,
                    borderRadius: BorderRadius.circular(10),
                    child: ListTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        leading: Icon(
                            (attachment['contentType'] as String? ?? '')
                                    .contains('pdf')
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            color: InstallationStyle.primary),
                        title: Text(
                            attachment['name'] as String? ?? 'Document signé',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14)),
                        trailing: const Icon(Icons.open_in_new, size: 18),
                        onTap: () => onOpen(attachment)))),
        ]);
}

class InstallationAction {
  const InstallationAction(this.label, this.onPressed,
      {this.icon, this.danger = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool danger;
}

/// Bottom bar with a single primary action, an optional save button and
/// secondary actions grouped in a menu on small screens.
class InstallationActionBar extends StatelessWidget {
  const InstallationActionBar(
      {super.key,
      this.primary,
      this.save,
      this.secondary = const [],
      this.status,
      this.statusWarning = false,
      this.busy = false});
  final InstallationAction? primary;
  final InstallationAction? save;
  final List<InstallationAction> secondary;
  final String? status;
  final bool statusWarning;
  final bool busy;

  bool get isEmpty => primary == null && save == null && secondary.isEmpty;

  Widget _menu() => PopupMenuButton<int>(
      tooltip: 'Autres actions',
      enabled: !busy,
      onSelected: (index) => secondary[index].onPressed?.call(),
      itemBuilder: (_) => [
            for (var i = 0; i < secondary.length; i++)
              PopupMenuItem(
                  value: i,
                  enabled: secondary[i].onPressed != null,
                  child: Row(children: [
                    Icon(secondary[i].icon ?? Icons.chevron_right,
                        size: 19,
                        color: secondary[i].danger
                            ? InstallationStyle.danger
                            : InstallationStyle.ink),
                    const SizedBox(width: 12),
                    Text(secondary[i].label,
                        style: TextStyle(
                            color: secondary[i].danger
                                ? InstallationStyle.danger
                                : InstallationStyle.ink)),
                  ]))
          ],
      child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
              border: Border.all(color: InstallationStyle.strongLine),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.more_horiz, color: InstallationStyle.ink)));

  Widget _primaryButton(bool compact) => FilledButton.icon(
      style: compact
          ? FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12))
          : null,
      onPressed: busy ? null : primary!.onPressed,
      icon: busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(primary!.icon ?? Icons.arrow_forward, size: 18),
      label:
          Text(primary!.label, maxLines: 1, overflow: TextOverflow.ellipsis));

  Widget _saveButton(bool compact) => OutlinedButton.icon(
      style: compact
          ? OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12))
          : null,
      onPressed: busy ? null : save!.onPressed,
      icon: Icon(save!.icon ?? Icons.save_outlined, size: 18),
      label: Text(save!.label, maxLines: 1, overflow: TextOverflow.ellipsis));

  @override
  Widget build(BuildContext context) {
    if (isEmpty && status == null) return const SizedBox.shrink();
    final statusText = status == null
        ? null
        : Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
                statusWarning
                    ? Icons.edit_note_outlined
                    : Icons.cloud_done_outlined,
                size: 15,
                color: statusWarning
                    ? InstallationStyle.warning
                    : InstallationStyle.green),
            const SizedBox(width: 6),
            Flexible(
                child: Text(status!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: statusWarning
                            ? InstallationStyle.warning
                            : InstallationStyle.muted))),
          ]);
    return Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: InstallationStyle.line))),
        child: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: LayoutBuilder(builder: (context, c) {
                  final compact = c.maxWidth < 640;
                  if (compact) {
                    return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (statusText != null) ...[
                            statusText,
                            if (!isEmpty) const SizedBox(height: 8),
                          ],
                          if (!isEmpty)
                            Row(children: [
                              if (secondary.isNotEmpty) ...[
                                _menu(),
                                const SizedBox(width: 8),
                              ],
                              if (save != null)
                                Expanded(flex: 2, child: _saveButton(true)),
                              if (save != null && primary != null)
                                const SizedBox(width: 8),
                              if (primary != null)
                                Expanded(flex: 3, child: _primaryButton(true)),
                              if (save == null && primary == null)
                                const Spacer(),
                            ]),
                        ]);
                  }
                  return Row(children: [
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: statusText ?? const SizedBox.shrink())),
                    if (secondary.length > 2) ...[
                      _menu(),
                      const SizedBox(width: 10),
                    ] else
                      for (final action in secondary) ...[
                        OutlinedButton.icon(
                            style: action.danger
                                ? OutlinedButton.styleFrom(
                                    foregroundColor: InstallationStyle.danger)
                                : null,
                            onPressed: busy ? null : action.onPressed,
                            icon: Icon(action.icon ?? Icons.chevron_right,
                                size: 18),
                            label: Text(action.label)),
                        const SizedBox(width: 10),
                      ],
                    if (save != null) ...[
                      _saveButton(false),
                      const SizedBox(width: 10),
                    ],
                    if (primary != null) _primaryButton(false),
                  ]);
                }))));
  }
}
