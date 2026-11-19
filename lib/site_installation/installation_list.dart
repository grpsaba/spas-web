import 'package:flutter/material.dart';

import 'installation_order.dart';
import 'installation_ui.dart';

class InstallationOrderTile extends StatelessWidget {
  const InstallationOrderTile(
      {super.key,
      required this.order,
      required this.onTap,
      this.syncLabel,
      this.needsAttention = false,
      this.desktop = false});
  final InstallationOrder order;
  final VoidCallback onTap;
  final String? syncLabel;
  final bool needsAttention;
  final bool desktop;

  String get _title => order.siteName.isEmpty ? 'Sans nom' : order.siteName;

  @override
  Widget build(BuildContext context) {
    final color = installationStatusColor(order.status);
    final identity = Row(children: [
      Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12)),
          child: Icon(installationStatusIcon(order.status),
              size: 22, color: color)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: order.siteName.isEmpty
                    ? InstallationStyle.muted
                    : InstallationStyle.ink)),
        if (order.clientName.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(order.clientName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: InstallationStyle.caption.copyWith(fontSize: 13)),
        ],
      ])),
    ]);
    if (desktop) {
      return InkWell(
          onTap: onTap,
          child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(children: [
                    Expanded(flex: 4, child: identity),
                    const SizedBox(width: 16),
                    Expanded(
                        flex: 2,
                        child: Text(order.authorName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: InstallationStyle.ink, fontSize: 13))),
                    Expanded(
                        flex: 2,
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: InstallationStatusBadge(order.status))),
                    Expanded(
                        flex: 2,
                        child: Text(
                            order.bonNumber.isEmpty
                                ? installationDateLabel(order.updatedAt)
                                : 'N° ${order.bonNumber}',
                            style: InstallationStyle.caption)),
                    const Icon(Icons.chevron_right,
                        size: 22, color: InstallationStyle.muted),
                  ]))));
    }
    return Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: needsAttention
                    ? InstallationStyle.warning.withValues(alpha: .5)
                    : InstallationStyle.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: identity),
                      const Icon(Icons.chevron_right,
                          size: 24, color: InstallationStyle.muted)
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      Flexible(child: InstallationStatusBadge(order.status)),
                      const SizedBox(width: 8),
                      if (syncLabel != null)
                        Expanded(
                            child: Row(children: [
                          Icon(
                              needsAttention
                                  ? Icons.cloud_upload
                                  : Icons.cloud_done,
                              size: 16,
                              color: needsAttention
                                  ? InstallationStyle.warning
                                  : InstallationStyle.green),
                          const SizedBox(width: 4),
                          Expanded(
                              child: Text(syncLabel!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: needsAttention
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: needsAttention
                                          ? InstallationStyle.warning
                                          : InstallationStyle.muted))),
                        ]))
                      else
                        const Spacer(),
                      Text(
                          order.bonNumber.isEmpty
                              ? installationDateLabel(order.updatedAt)
                              : 'N° ${order.bonNumber}',
                          style: InstallationStyle.caption),
                    ]),
                  ])),
        ));
  }
}

/// One shortcut of the list.
class _View {
  const _View(this.id, this.label, this.icon, this.test);
  final String id;
  final String label;
  final IconData icon;
  final bool Function(InstallationOrder) test;
}

class InstallationWorkspace extends StatefulWidget {
  const InstallationWorkspace(
      {super.key,
      required this.orders,
      required this.ownerUid,
      required this.onOpen,
      this.onCreate,
      this.reviewer = false,
      this.mobile = false,
      this.syncLabels = const {},
      this.attentionIds = const {},
      this.headerExtra,
      this.notices = const []});
  final List<InstallationOrder> orders;
  final String ownerUid;
  final ValueChanged<InstallationOrder> onOpen;
  final VoidCallback? onCreate;
  final bool reviewer;
  final bool mobile;
  final Map<String, String> syncLabels;
  final Set<String> attentionIds;

  /// Displayed under the page title (e.g. the numbering panel on the web).
  final Widget? headerExtra;

  /// Short banners displayed above the filters (offline, synchronisation…).
  final List<Widget> notices;
  @override
  State<InstallationWorkspace> createState() => _InstallationWorkspaceState();
}

class _InstallationWorkspaceState extends State<InstallationWorkspace> {
  final _search = TextEditingController();
  String _query = '';
  String _view = 'all';
  InstallationStatus? _status;

  // Search keys are computed once per list of orders, not on every keystroke.
  List<InstallationOrder>? _indexed;
  List<String> _keys = const [];
  Map<String, int> _counts = const {};
  Map<InstallationStatus, int> _statusCounts = const {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static bool _actionable(InstallationOrder o) => const [
        InstallationStatus.submitted,
        InstallationStatus.signedReturned
      ].contains(o.status);

  List<_View> get _views => [
        _View('all', 'Tous', Icons.list, (_) => true),
        if (widget.mobile) ...[
          _View('todo', 'À faire', Icons.edit_note,
              (o) => o.status.authorCanEdit),
          _View(
              'office',
              'Envoyés',
              Icons.send,
              (o) =>
                  !o.status.authorCanEdit &&
                  o.status != InstallationStatus.finalized),
          _View('done', 'Terminés', Icons.verified,
              (o) => o.status == InstallationStatus.finalized),
        ],
        if (widget.reviewer && !widget.mobile)
          const _View(
              'action', 'À traiter', Icons.notifications_active, _actionable),
        if (!widget.mobile)
          _View('mine', 'Mes demandes', Icons.person,
              (o) => o.authorUid == widget.ownerUid),
      ];

  void _index() {
    if (identical(_indexed, widget.orders)) return;
    _indexed = widget.orders;
    _keys = [
      for (final o in widget.orders)
        installationNormalize(
            '${o.siteName} ${o.clientName} ${o.bonNumber} ${o.authorName} ${o.address}')
    ];
    _counts = {
      for (final view in _views) view.id: widget.orders.where(view.test).length
    };
    _statusCounts = {
      for (final status in InstallationStatus.values)
        status: widget.orders.where((o) => o.status == status).length
    };
  }

  @override
  void didUpdateWidget(covariant InstallationWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reviewer != widget.reviewer ||
        oldWidget.mobile != widget.mobile ||
        oldWidget.ownerUid != widget.ownerUid) {
      _indexed = null;
    }
  }

  bool get _filtered => _status != null || _query.isNotEmpty || _view != 'all';

  void _reset() => setState(() {
        _status = null;
        _query = '';
        _search.clear();
        _view = 'all';
      });

  Future<void> _pickStatus() async {
    final picked = await showModalBottomSheet<Object>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        builder: (context) => SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _statusOption(
                          context, null, 'Tous', widget.orders.length),
                      for (final status in InstallationStatus.values)
                        _statusOption(context, status, status.label,
                            _statusCounts[status] ?? 0),
                    ]))));
    if (picked == null || !mounted) return;
    setState(() => _status = picked is InstallationStatus ? picked : null);
  }

  Widget _statusOption(BuildContext sheet, InstallationStatus? status,
          String label, int count) =>
      ListTile(
          selected: _status == status,
          selectedTileColor: InstallationStyle.primarySoft,
          minTileHeight: 54,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: status == null
              ? const Icon(Icons.list, size: 24)
              : Icon(installationStatusIcon(status),
                  size: 24, color: installationStatusColor(status)),
          title: Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          trailing: Text('$count',
              style: const TextStyle(
                  fontSize: 15, color: InstallationStyle.muted)),
          onTap: () => Navigator.pop(sheet, status ?? 'all'));

  @override
  Widget build(BuildContext context) {
    _index();
    final views = {for (final v in _views) v.id: v};
    final view = views[_view] ?? views['all']!;
    final normalizedQuery = installationNormalize(_query);
    final orders = <InstallationOrder>[
      for (var i = 0; i < widget.orders.length; i++)
        if (view.test(widget.orders[i]) &&
            (_status == null || widget.orders[i].status == _status) &&
            (normalizedQuery.isEmpty || _keys[i].contains(normalizedQuery)))
          widget.orders[i]
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final narrow = constraints.maxWidth < 680;
      final desktop = constraints.maxWidth >= 1050 && !widget.mobile;
      final horizontal = narrow ? 16.0 : 32.0;
      final contentWidth =
          (constraints.maxWidth - 2 * horizontal).clamp(0.0, 1280.0);
      final side = (constraints.maxWidth - contentWidth) / 2;
      Widget box(Widget child) => SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: side),
          sliver: SliverToBoxAdapter(child: child));
      return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: narrow ? 14 : 28)),
            box(_header(narrow)),
            if (!widget.mobile) box(_counters(contentWidth)),
            for (final notice in widget.notices)
              box(Padding(
                  padding: const EdgeInsets.only(bottom: 10), child: notice)),
            box(_toolbar(narrow, views.values.toList())),
            box(Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 6),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          _filtered
                              ? '${orders.length} / ${widget.orders.length}'
                              : '${orders.length}',
                          style: InstallationStyle.caption)),
                  if (_filtered)
                    Flexible(
                        child: TextButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.filter_alt_off_outlined,
                                size: 18),
                            label: const Text('Effacer',
                                overflow: TextOverflow.ellipsis))),
                ]))),
            if (orders.isEmpty)
              box(InstallationPanel(child: _empty()))
            else if (desktop)
              SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  sliver: DecoratedSliver(
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: InstallationStyle.line)),
                      sliver: SliverMainAxisGroup(slivers: [
                        const SliverToBoxAdapter(child: _TableHeader()),
                        SliverList.separated(
                            itemCount: orders.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) =>
                                InstallationOrderTile(
                                    key: ValueKey(orders[index].id),
                                    order: orders[index],
                                    desktop: true,
                                    onTap: () => widget.onOpen(orders[index]))),
                      ])))
            else
              SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: side),
                  sliver: SliverList.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return InstallationOrderTile(
                            key: ValueKey(order.id),
                            order: order,
                            onTap: () => widget.onOpen(order),
                            syncLabel: widget.syncLabels[order.id],
                            needsAttention:
                                widget.attentionIds.contains(order.id));
                      })),
            SliverToBoxAdapter(
                child: SizedBox(height: widget.mobile ? 104 : 40)),
          ]);
    });
  }

  Widget _header(bool narrow) {
    if (widget.mobile) return const SizedBox.shrink();
    final title = Text('Bons de mise en place',
        style:
            InstallationStyle.pageTitle.copyWith(fontSize: narrow ? 22 : 26));
    final create = widget.onCreate == null
        ? null
        : FilledButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add, size: 22),
            label: const Text('Nouvelle demande'));
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (narrow) ...[
            title,
            if (create != null) ...[const SizedBox(height: 12), create],
          ] else
            Row(children: [
              Expanded(child: title),
              if (create != null) ...[const SizedBox(width: 24), create],
            ]),
          if (widget.headerExtra != null) ...[
            const SizedBox(height: 12),
            widget.headerExtra!,
          ],
        ]));
  }

  Widget _counters(double width) {
    const stats = {
      InstallationStatus.submitted: 'À vérifier',
      InstallationStatus.awaitingSignature: 'À signer',
      InstallationStatus.signedReturned: 'Signés',
      InstallationStatus.finalized: 'Sites créés',
    };
    final compact = width < 640;
    final tiles = [
      for (final entry in stats.entries)
        _counter(entry.key, entry.value, compact: compact),
    ];
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: compact
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final tile in tiles)
                    Padding(
                        padding: const EdgeInsets.only(right: 8), child: tile)
                ]))
            : Row(children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: tiles[i]),
                ]
              ]));
  }

  Widget _counter(InstallationStatus status, String label,
      {required bool compact}) {
    final selected = _status == status;
    final count = _statusCounts[status] ?? 0;
    final color = installationStatusColor(status);
    return Semantics(
        button: true,
        selected: selected,
        label: '$label : $count',
        child: Material(
            color: selected ? color.withValues(alpha: .1) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: selected ? color : InstallationStyle.line,
                    width: selected ? 1.5 : 1)),
            child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _status = selected ? null : status),
                child: Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: compact ? 10 : 14),
                    child: ExcludeSemantics(
                        child: Row(
                            mainAxisSize:
                                compact ? MainAxisSize.min : MainAxisSize.max,
                            children: [
                          Icon(installationStatusIcon(status),
                              size: 22, color: color),
                          const SizedBox(width: 10),
                          Text('$count',
                              style: TextStyle(
                                  fontSize: compact ? 16 : 22,
                                  fontWeight: FontWeight.w700,
                                  color: InstallationStyle.ink)),
                          const SizedBox(width: 8),
                          if (compact)
                            Text(label,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: InstallationStyle.muted))
                          else
                            Expanded(
                                child: Text(label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: InstallationStyle.muted))),
                        ]))))));
  }

  Widget _toolbar(bool narrow, List<_View> views) {
    final search = TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
            hintText: 'Rechercher',
            prefixIcon: const Icon(Icons.search, size: 22),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }))),
        onChanged: (v) => setState(() => _query = v.trim()));
    final statusButton = _status == null
        ? OutlinedButton.icon(
            onPressed: _pickStatus,
            icon: const Icon(Icons.filter_list, size: 20),
            label: const Text('Statut'))
        : InputChip(
            label: Text(_status!.label),
            avatar: Icon(installationStatusIcon(_status!),
                size: 18, color: Colors.white),
            onPressed: _pickStatus,
            onDeleted: () => setState(() => _status = null),
            deleteIconColor: Colors.white,
            deleteButtonTooltipMessage: 'Retirer le filtre de statut',
            backgroundColor: installationStatusColor(_status!),
            side: BorderSide.none,
            labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white));
    final chips = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [for (final view in views) _viewChip(view)]));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (narrow) ...[
        search,
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: chips),
          const SizedBox(width: 8),
          statusButton,
        ]),
      ] else ...[
        Row(children: [
          Expanded(child: search),
          const SizedBox(width: 12),
          statusButton,
        ]),
        const SizedBox(height: 12),
        chips,
      ],
    ]);
  }

  Widget _viewChip(_View view) {
    final selected = _view == view.id;
    return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
            avatar: Icon(view.icon,
                size: 18,
                color: selected
                    ? InstallationStyle.primary
                    : InstallationStyle.muted),
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(view.label),
              const SizedBox(width: 6),
              Text('${_counts[view.id] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.w400)),
            ]),
            selected: selected,
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            selectedColor: InstallationStyle.primarySoft,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: selected
                    ? InstallationStyle.primary
                    : InstallationStyle.muted),
            side: BorderSide(
                color: selected
                    ? InstallationStyle.primary.withValues(alpha: .35)
                    : InstallationStyle.line),
            onSelected: (_) => setState(() => _view = view.id)));
  }

  Widget _empty() {
    final none = widget.orders.isEmpty;
    return InstallationStateMessage(
        icon: none ? Icons.inbox_outlined : Icons.search_off,
        title: none ? 'Aucune demande' : 'Aucun résultat',
        action: none
            ? widget.onCreate == null
                ? null
                : FilledButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.add, size: 22),
                    label: const Text('Nouvelle demande'))
            : OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                label: const Text('Effacer les filtres')));
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();
  static const _style = TextStyle(
      fontSize: 11,
      letterSpacing: .8,
      fontWeight: FontWeight.w600,
      color: InstallationStyle.muted);
  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(
          color: Color(0xFFF9FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          border: Border(bottom: BorderSide(color: InstallationStyle.line))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: const Row(children: [
        Expanded(flex: 4, child: Text('SITE', style: _style)),
        SizedBox(width: 16),
        Expanded(flex: 2, child: Text('INITIATEUR', style: _style)),
        Expanded(flex: 2, child: Text('STATUT', style: _style)),
        Expanded(flex: 2, child: Text('DATE', style: _style)),
        SizedBox(width: 22),
      ]));
}
