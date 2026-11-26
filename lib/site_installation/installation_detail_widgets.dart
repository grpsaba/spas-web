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
      child: Row(children: [
        for (final tab in tabs)
          Expanded(
              child: Semantics(
                  selected: tab.id == selected,
                  button: true,
                  label: tab.label,
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
                          child: ExcludeSemantics(
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(minHeight: 56),
                                  child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 6),
                                      child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(tab.icon,
                                                size: 22,
                                                color: tab.id == selected
                                                    ? InstallationStyle.primary
                                                    : InstallationStyle.muted),
                                            const SizedBox(height: 3),
                                            Text(tab.label,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: tab.id == selected
                                                        ? InstallationStyle.ink
                                                        : InstallationStyle
                                                            .muted)),
                                          ])))))))),
      ]));
}

/// Status with its colour and icon, who acts next and the progress.
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
    final color = installationStatusColor(status);
    final mine = guidance.owner == 'À vous';
    return InstallationPanel(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(installationStatusIcon(status),
                    size: 28, color: Colors.white)),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(badgeLabel ?? status.label,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: color)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(guidance.icon ?? installationOwnerIcon(guidance.owner),
                        size: 17,
                        color: mine
                            ? InstallationStyle.primary
                            : InstallationStyle.muted),
                    const SizedBox(width: 5),
                    Flexible(
                        child: Text('${guidance.owner} · ${guidance.title}',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    mine ? FontWeight.w700 : FontWeight.w500,
                                color: mine
                                    ? InstallationStyle.primary
                                    : InstallationStyle.ink))),
                  ]),
                ])),
          ]),
          if (extra != null) ...[const SizedBox(height: 10), extra!],
          if (showProgress) ...[
            const SizedBox(height: 16),
            InstallationProgress(status),
          ],
        ]));
  }
}

class _Value {
  const _Value(this.icon, this.label, this.value, {this.required = true});
  final IconData icon;
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
        return Wrap(spacing: 20, runSpacing: 12, children: [
          for (final entry in values)
            SizedBox(
                width: width,
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Icon(entry.icon,
                              size: 20, color: InstallationStyle.muted)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(entry.label, style: InstallationStyle.caption),
                            const SizedBox(height: 2),
                            Text(
                                entry.value.isEmpty
                                    ? entry.required
                                        ? 'Manquant'
                                        : '—'
                                    : entry.value,
                                style: TextStyle(
                                    color: entry.value.isEmpty && entry.required
                                        ? InstallationStyle.warning
                                        : InstallationStyle.ink,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5)),
                          ])),
                    ])),
        ]);
      });
}

/// Request displayed without form controls (sent, validated…).
class InstallationReadOnly extends StatelessWidget {
  const InstallationReadOnly(this.order, {super.key});
  final InstallationOrder order;

  Widget _section(IconData icon, String title, Widget child, {int? count}) =>
      InstallationPanel(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Icon(icon, size: 22, color: InstallationStyle.primary),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title, style: InstallationStyle.sectionTitle)),
              if (count != null)
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: InstallationStyle.background,
                        borderRadius: BorderRadius.circular(12)),
                    child: Text('$count',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: InstallationStyle.ink))),
            ]),
            const SizedBox(height: 14),
            child,
          ]));

  Widget _missing(String text) => Row(children: [
        const Icon(Icons.warning_amber_rounded,
            size: 18, color: InstallationStyle.warning),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: InstallationStyle.warning, fontWeight: FontWeight.w600)),
      ]);

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _section(
            Icons.storefront,
            'Site',
            _Values([
              _Value(Icons.storefront_outlined, 'Site', order.siteName),
              _Value(Icons.business_outlined, 'Client', order.clientName),
              _Value(Icons.place_outlined, 'Adresse', order.address),
              _Value(Icons.phone_outlined, 'Téléphone', order.phone,
                  required: false),
              _Value(
                  order.isSecurity
                      ? Icons.shield_outlined
                      : Icons.cleaning_services_outlined,
                  'Prestation',
                  order.serviceLabel),
              if (order.bonNumber.isNotEmpty)
                _Value(Icons.numbers, 'N° du bon',
                    installationBonLabel(order.bonNumber)),
            ])),
        const SizedBox(height: 12),
        _section(
            Icons.groups_outlined,
            'Agents',
            order.agents.isEmpty
                ? _missing('Aucun agent')
                : Column(children: [
                    for (var i = 0; i < order.agents.length; i++)
                      Padding(
                          padding: EdgeInsets.only(
                              bottom: i == order.agents.length - 1 ? 0 : 12),
                          child: Row(children: [
                            CircleAvatar(
                                radius: 16,
                                backgroundColor: InstallationStyle.background,
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        fontSize: 12,
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
                                          ? 'Nom manquant'
                                          : order.agents[i].name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: InstallationStyle.ink)),
                                  Text(
                                      [
                                        order.agents[i].type,
                                        order.agents[i].phone
                                      ].where((s) => s.isNotEmpty).join(' · '),
                                      style: InstallationStyle.caption)
                                ]))
                          ])),
                  ]),
            count: order.agents.length),
        const SizedBox(height: 12),
        _section(
            Icons.inventory_2_outlined,
            'Équipements',
            order.equipment.isEmpty
                ? _missing('Aucun équipement')
                : Column(children: [
                    for (final item in order.equipment)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    item.designation.isEmpty
                                        ? 'Nom manquant'
                                        : item.designation,
                                    style: const TextStyle(
                                        fontSize: 14.5,
                                        color: InstallationStyle.ink))),
                            Text('× ${item.quantity}',
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: InstallationStyle.ink))
                          ])),
                  ]),
            count: order.equipment.length),
        const SizedBox(height: 12),
        _section(
            Icons.tune,
            'Organisation',
            _Values([
              _Value(Icons.map_outlined, 'Zone',
                  order.zone?['name'] as String? ?? ''),
              _Value(Icons.badge_outlined, 'Superviseur',
                  installationPersonName(order.supervisor)),
              _Value(Icons.badge_outlined, '2e superviseur',
                  installationPersonName(order.supervisor2),
                  required: false),
              _Value(Icons.groups_outlined, 'Agents / rondes',
                  '${order.agentCount} / ${order.roundCount}'),
              _Value(
                  order.pointageType == 'nuit'
                      ? Icons.nightlight_outlined
                      : Icons.wb_sunny_outlined,
                  'Pointage',
                  installationPointageLabel(order.pointageType)),
              _Value(
                  Icons.event_outlined,
                  'Date du contrat',
                  order.contractDate == null
                      ? ''
                      : installationDateLabel(order.contractDate)),
              _Value(
                  Icons.my_location,
                  'GPS',
                  order.latitude != null && order.longitude != null
                      ? '${order.latitude}, ${order.longitude}'
                      : '',
                  required: false),
            ])),
      ]);
}

class InstallationEventTile extends StatelessWidget {
  const InstallationEventTile(
      {super.key, required this.event, this.pending = false, this.repeat = 1});
  final Map<String, dynamic> event;
  final bool pending;

  /// Number of identical consecutive events shown by this tile.
  final int repeat;
  @override
  Widget build(BuildContext context) {
    final comment = event['kind'] == 'comment';
    final author = installationMap(event['author'])['name'] as String? ?? '';
    final at = installationDate(event['at']);
    final when = pending
        ? 'En attente'
        : at == null
            ? ''
            : '${installationDateLabel(at)} ${installationTimeLabel(at)}';
    final message = event['message'] as String? ?? '';
    if (!comment) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: InstallationStyle.background,
                    shape: BoxShape.circle),
                child: Icon(
                    event['kind'] == 'attachment'
                        ? Icons.attach_file
                        : Icons.flag_outlined,
                    size: 16,
                    color: InstallationStyle.muted)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(repeat > 1 ? '$message  ×$repeat' : message,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: InstallationStyle.ink)),
                  Text(
                      [if (author.isNotEmpty) author, if (when.isNotEmpty) when]
                          .join(' · '),
                      style: const TextStyle(
                          color: InstallationStyle.muted, fontSize: 12)),
                ])),
          ]));
    }
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
              radius: 15,
              backgroundColor: InstallationStyle.primarySoft,
              child: Text(
                  author.isEmpty ? '?' : author.characters.first.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: InstallationStyle.primary))),
          const SizedBox(width: 10),
          Expanded(
              child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
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
                        Text(author.isEmpty ? 'Message' : author,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: InstallationStyle.ink)),
                        const SizedBox(height: 3),
                        SelectableText(message,
                            style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.4,
                                color: InstallationStyle.ink)),
                        const SizedBox(height: 3),
                        Row(children: [
                          Icon(pending ? Icons.schedule : Icons.done_all,
                              size: 14,
                              color: pending
                                  ? InstallationStyle.warning
                                  : InstallationStyle.muted),
                          const SizedBox(width: 4),
                          Text(when,
                              style: TextStyle(
                                  color: pending
                                      ? InstallationStyle.warning
                                      : InstallationStyle.muted,
                                  fontSize: 12)),
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
      this.hint = 'Message…',
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
                  maxLines: 4,
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
                          minimumSize: const Size(52, 52)),
                      onPressed: !widget.enabled ||
                              _sending ||
                              value.text.trim().isEmpty
                          ? null
                          : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 22)))),
        ]),
        if (widget.note != null) ...[
          const SizedBox(height: 4),
          Text(widget.note!, style: InstallationStyle.caption),
        ],
      ]);
}

/// One history line: its most recent event and how many identical events
/// it stands for.
class InstallationEventGroup {
  const InstallationEventGroup(this.event, this.count);
  final Map<String, dynamic> event;
  final int count;
}

/// Groups identical consecutive history events (same kind, message and
/// author), newest first: each group keeps its most recent event and its
/// size. Comments and pending events are never grouped.
List<InstallationEventGroup> installationGroupEvents(
    List<Map<String, dynamic>> newestFirst,
    {Set<String> pendingIds = const {}}) {
  String? keyOf(Map<String, dynamic> event) {
    if (event['kind'] == 'comment' ||
        pendingIds.contains(event['id'] as String? ?? '')) {
      return null;
    }
    return [
      event['kind'] ?? '',
      event['message'] ?? '',
      installationMap(event['author'])['uid'] ??
          installationMap(event['author'])['name'] ??
          '',
    ].join('\u0000');
  }

  final groups = <InstallationEventGroup>[];
  String? previous;
  for (final event in newestFirst) {
    final key = keyOf(event);
    if (key != null && key == previous) {
      final last = groups.removeLast();
      groups.add(InstallationEventGroup(last.event, last.count + 1));
    } else {
      groups.add(InstallationEventGroup(event, 1));
    }
    previous = key;
  }
  return groups;
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
      this.composerHint = 'Message…',
      this.composerNote});

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

  @override
  Widget build(BuildContext context) {
    final ordered = installationGroupEvents(events.reversed.toList(),
        pendingIds: pendingIds);
    return InstallationPanel(
        padding: const EdgeInsets.all(16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (onSend != null) ...[
            InstallationCommentComposer(
                onSend: onSend!,
                enabled: composerEnabled,
                hint: composerHint,
                note: composerNote),
            const Divider(height: 28),
          ],
          if (error != null)
            InstallationNotice(
                tone: InstallationTone.error,
                message: error!,
                action: onRetry == null
                    ? null
                    : TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Réessayer')))
          else if (loading)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3))))
          else if (ordered.isEmpty)
            const InstallationStateMessage(
                icon: Icons.chat_bubble_outline, title: 'Aucun message')
          else
            for (final group in ordered)
              InstallationEventTile(
                  event: group.event,
                  repeat: group.count,
                  pending:
                      pendingIds.contains(group.event['id'] as String? ?? '')),
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
      ? const InstallationStateMessage(
          icon: Icons.description_outlined, title: 'Aucun document')
      : Column(children: [
          for (final attachment in attachments)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                    color: InstallationStyle.background,
                    borderRadius: BorderRadius.circular(10),
                    child: ListTile(
                        minTileHeight: 56,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        leading: Icon(
                            (attachment['contentType'] as String? ?? '')
                                    .contains('pdf')
                                ? Icons.picture_as_pdf_outlined
                                : Icons.image_outlined,
                            color: InstallationStyle.primary),
                        title: Text(
                            attachment['name'] as String? ?? 'Bon signé',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14.5)),
                        trailing: const Icon(Icons.open_in_new, size: 20),
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

/// Bottom bar: one large primary action. Secondary actions stay discreet:
/// a back button, an icon save button and a menu for the others.
class InstallationActionBar extends StatelessWidget {
  const InstallationActionBar(
      {super.key,
      this.primary,
      this.back,
      this.save,
      this.secondary = const [],
      this.status,
      this.statusWarning = false,
      this.busy = false});
  final InstallationAction? primary;
  final InstallationAction? back;
  final InstallationAction? save;
  final List<InstallationAction> secondary;

  /// A few words next to a cloud icon (save state).
  final String? status;
  final bool statusWarning;
  final bool busy;

  bool get isEmpty =>
      primary == null && back == null && save == null && secondary.isEmpty;

  Widget _menu() => PopupMenuButton<int>(
      tooltip: 'Autres actions',
      enabled: !busy,
      onSelected: (index) => secondary[index].onPressed?.call(),
      itemBuilder: (_) => [
            for (var i = 0; i < secondary.length; i++)
              PopupMenuItem(
                  value: i,
                  height: 52,
                  enabled: secondary[i].onPressed != null,
                  child: Row(children: [
                    Icon(secondary[i].icon ?? Icons.chevron_right,
                        size: 22,
                        color: secondary[i].danger
                            ? InstallationStyle.danger
                            : InstallationStyle.ink),
                    const SizedBox(width: 12),
                    Text(secondary[i].label,
                        style: TextStyle(
                            fontSize: 15,
                            color: secondary[i].danger
                                ? InstallationStyle.danger
                                : InstallationStyle.ink)),
                  ]))
          ],
      child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
              border: Border.all(color: InstallationStyle.strongLine),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.more_horiz, color: InstallationStyle.ink)));

  @override
  Widget build(BuildContext context) {
    if (isEmpty && status == null) return const SizedBox.shrink();
    final compact = MediaQuery.sizeOf(context).width < 640;
    return Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: InstallationStyle.line))),
        child: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(children: [
                  if (status != null)
                    Tooltip(
                        message: status!,
                        child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                  statusWarning
                                      ? Icons.cloud_upload
                                      : Icons.cloud_done,
                                  size: 22,
                                  color: statusWarning
                                      ? InstallationStyle.warning
                                      : InstallationStyle.green),
                              if (!compact) ...[
                                const SizedBox(width: 6),
                                Text(status!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: statusWarning
                                            ? InstallationStyle.warning
                                            : InstallationStyle.muted)),
                              ],
                            ]))),
                  if (secondary.isNotEmpty) ...[
                    _menu(),
                    const SizedBox(width: 8),
                  ],
                  if (save != null) ...[
                    compact
                        ? IconButton.outlined(
                            tooltip: save!.label,
                            style: IconButton.styleFrom(
                                minimumSize: const Size(52, 52),
                                side: const BorderSide(
                                    color: InstallationStyle.strongLine)),
                            onPressed: busy ? null : save!.onPressed,
                            icon: Icon(save!.icon ?? Icons.save_outlined))
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 52)),
                            onPressed: busy ? null : save!.onPressed,
                            icon: Icon(save!.icon ?? Icons.save_outlined,
                                size: 20),
                            label: Text(save!.label)),
                    const SizedBox(width: 8),
                  ],
                  if (back != null) ...[
                    OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 52),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14)),
                        onPressed: busy ? null : back!.onPressed,
                        icon: Icon(back!.icon ?? Icons.arrow_back, size: 20),
                        label: Text(back!.label)),
                    const SizedBox(width: 8),
                  ],
                  if (primary != null)
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerRight,
                            child: ConstrainedBox(
                                constraints: BoxConstraints(
                                    maxWidth: compact ? double.infinity : 320),
                                child: SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                        style: FilledButton.styleFrom(
                                            minimumSize: const Size(0, 54),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14),
                                            textStyle: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700)),
                                        onPressed:
                                            busy ? null : primary!.onPressed,
                                        icon: busy
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: CircularProgressIndicator(
                                                    strokeWidth: 2))
                                            : Icon(
                                                primary!.icon ?? Icons.arrow_forward,
                                                size: 22),
                                        label: Text(primary!.label, maxLines: 1, overflow: TextOverflow.ellipsis))))))
                  else
                    const Spacer(),
                ]))));
  }
}
