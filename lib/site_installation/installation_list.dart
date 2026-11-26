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
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Row(children: [
                Expanded(
                    flex: 5,
                    child: Row(children: [
                      Icon(installationStatusIcon(order.status),
                          size: 20, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(_title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: order.siteName.isEmpty
                                        ? InstallationStyle.muted
                                        : InstallationStyle.ink)),
                            if (order.clientName.isNotEmpty)
                              Text(order.clientName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: InstallationStyle.caption),
                          ])),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    flex: 3,
                    child: Text(order.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: InstallationStyle.ink, fontSize: 13))),
                Expanded(
                    flex: 3,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: InstallationStatusBadge(order.status))),
                Expanded(
                    flex: 2,
                    child: Text(
                        order.bonNumber.isEmpty
                            ? '—'
                            : installationBonLabel(order.bonNumber),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: order.bonNumber.isEmpty
                                ? InstallationStyle.muted
                                : InstallationStyle.ink))),
                Expanded(
                    flex: 2,
                    child: Text(installationDateLabel(order.updatedAt),
                        style:
                            InstallationStyle.caption.copyWith(fontSize: 13))),
                const Icon(Icons.chevron_right,
                    size: 20, color: InstallationStyle.muted),
              ])));
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
                              : 'N° ${installationBonLabel(order.bonNumber)}',
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
      this.ownOnly = false,
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

  /// The list already contains only the user's requests (no « Mes demandes »).
  final bool ownOnly;

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
        if (!widget.mobile && !widget.ownOnly)
          _View('mine', 'Mes demandes', Icons.person,
              (o) => o.authorUid == widget.ownerUid),
      ];

  void _index() {
    if (identical(_indexed, widget.orders)) return;
    _indexed = widget.orders;
    _keys = [
      for (final o in widget.orders)
        installationNormalize(
            '${o.siteName} ${o.clientName} ${o.bonNumber} ${installationBonLabel(o.bonNumber)} ${o.authorName} ${o.address}')
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
      final desktop = constraints.maxWidth >= 760 && !widget.mobile;
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
            SliverToBoxAdapter(child: SizedBox(height: narrow ? 10 : 14)),
            box(_header(narrow)),
            if (!widget.mobile) box(_counters(contentWidth)),
            for (final notice in widget.notices)
              box(Padding(
                  padding: const EdgeInsets.only(bottom: 10), child: notice)),
            box(_toolbar(narrow, views.values.toList())),
            // No isolated count: only the way back when a filter is on.
            box(_filtered
                ? Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                        onPressed: _reset,
                        icon:
                            const Icon(Icons.filter_alt_off_outlined, size: 18),
                        label: const Text('Effacer')))
                : const SizedBox(height: 8)),
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
            InstallationStyle.pageTitle.copyWith(fontSize: narrow ? 20 : 22));
    final create = widget.onCreate == null
        ? null
        : FilledButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add, size: 22),
            label: const Text('Nouvelle demande'));
    return Padding(
        padding: const EdgeInsets.only(bottom: 10),
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
            const SizedBox(height: 4),
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
        padding: const EdgeInsets.only(bottom: 10),
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
                  if (i > 0) const SizedBox(width: 8),
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
                        horizontal: 12, vertical: compact ? 10 : 8),
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
                                  fontSize: compact ? 16 : 18,
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
            isDense: !narrow,
            contentPadding: narrow
                ? null
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
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
    final status = _status;
    final control = narrow ? 56.0 : 48.0;
    final statusButton = SizedBox(
        width: control,
        height: control,
        child: status == null
            ? IconButton.outlined(
                tooltip: 'Statut',
                onPressed: _pickStatus,
                style: IconButton.styleFrom(
                    side: const BorderSide(color: InstallationStyle.line),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.filter_list,
                    size: 24, color: InstallationStyle.ink))
            : IconButton.filled(
                tooltip: status.label,
                onPressed: _pickStatus,
                style: IconButton.styleFrom(
                    backgroundColor: installationStatusColor(status),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                icon: Icon(installationStatusIcon(status),
                    size: 24, color: Colors.white)));
    // « Tous » is the state with no shortcut selected: the shortcuts share the
    // width, so all of them stay visible on a small phone.
    final shortcuts = views.where((view) => view.id != 'all').toList();
    final segments = Row(children: [
      for (var i = 0; i < shortcuts.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        Expanded(child: _viewSegment(shortcuts[i], height: control)),
      ]
    ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (narrow) ...[
        search,
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: segments),
          const SizedBox(width: 8),
          statusButton,
        ]),
      ] else
        // One row on large screens: search, shortcuts and status filter.
        Row(children: [
          Expanded(child: SizedBox(height: control, child: search)),
          if (shortcuts.isNotEmpty) ...[
            const SizedBox(width: 8),
            SizedBox(width: 150.0 * shortcuts.length, child: segments),
          ],
          const SizedBox(width: 8),
          statusButton,
        ]),
    ]);
  }

  Widget _viewSegment(_View view, {double height = 56}) {
    final selected = _view == view.id;
    final color =
        selected ? InstallationStyle.primary : InstallationStyle.muted;
    return Semantics(
        button: true,
        selected: selected,
        label: '${view.label} : ${_counts[view.id] ?? 0}',
        child: Material(
            color: selected ? InstallationStyle.primarySoft : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: selected
                        ? InstallationStyle.primary.withValues(alpha: .5)
                        : InstallationStyle.line,
                    width: selected ? 1.5 : 1)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                // A second tap on the selected shortcut shows everything.
                onTap: () => setState(() => _view = selected ? 'all' : view.id),
                child: ExcludeSemantics(
                    child: SizedBox(
                        height: height,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(view.icon, size: 18, color: color),
                                        const SizedBox(width: 4),
                                        Text('${_counts[view.id] ?? 0}',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: color)),
                                      ]),
                                  const SizedBox(height: 2),
                                  FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(view.label,
                                          maxLines: 1,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: color))),
                                ])))))));
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: const Row(children: [
        Expanded(flex: 5, child: Text('SITE', style: _style)),
        SizedBox(width: 12),
        Expanded(flex: 3, child: Text('INITIATEUR', style: _style)),
        Expanded(flex: 3, child: Text('STATUT', style: _style)),
        Expanded(flex: 2, child: Text('N° BON', style: _style)),
        Expanded(flex: 2, child: Text('MISE À JOUR', style: _style)),
        SizedBox(width: 20),
      ]));
}
