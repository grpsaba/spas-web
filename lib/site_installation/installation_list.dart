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

  String get _title =>
      order.siteName.isEmpty ? 'Demande à compléter' : order.siteName;

  String get _subtitle => [
        if (order.clientName.isNotEmpty) order.clientName,
        order.serviceLabel,
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final identity = Row(children: [
      Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: InstallationStyle.background,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(
              order.isSecurity
                  ? Icons.shield_outlined
                  : Icons.cleaning_services_outlined,
              size: 19,
              color: InstallationStyle.primary)),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: order.siteName.isEmpty
                    ? InstallationStyle.muted
                    : InstallationStyle.ink)),
        const SizedBox(height: 3),
        Text(_subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: InstallationStyle.caption),
      ])),
    ]);
    if (desktop) {
      return InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    flex: 3,
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: InstallationStatusBadge(order.status))),
                Expanded(
                    flex: 2,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(installationDateLabel(order.updatedAt),
                              style: InstallationStyle.caption),
                          if (order.bonNumber.isNotEmpty)
                            Text('Bon n° ${order.bonNumber}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: InstallationStyle.ink)),
                        ])),
                const Icon(Icons.chevron_right,
                    size: 20, color: InstallationStyle.muted),
              ])));
    }
    final attention =
        needsAttention ? InstallationStyle.warning : InstallationStyle.muted;
    return Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
                color: needsAttention
                    ? InstallationStyle.warning.withValues(alpha: .45)
                    : InstallationStyle.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: identity),
                      const Icon(Icons.chevron_right,
                          size: 20, color: InstallationStyle.muted)
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Flexible(child: InstallationStatusBadge(order.status)),
                      const SizedBox(width: 10),
                      Text(
                          order.bonNumber.isEmpty
                              ? installationDateLabel(order.updatedAt)
                              : 'Bon n° ${order.bonNumber}',
                          style: InstallationStyle.caption),
                    ]),
                    if (syncLabel != null) ...[
                      const SizedBox(height: 10),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                                needsAttention
                                    ? Icons.cloud_upload_outlined
                                    : Icons.cloud_done_outlined,
                                size: 15,
                                color: needsAttention
                                    ? attention
                                    : InstallationStyle.green),
                            const SizedBox(width: 6),
                            Expanded(
                                child: Text(syncLabel!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: attention,
                                        fontWeight: needsAttention
                                            ? FontWeight.w600
                                            : FontWeight.w400)))
                          ]),
                    ] else if (order.authorName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Initiée par ${order.authorName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: InstallationStyle.caption),
                    ],
                  ])),
        ));
  }
}

/// One shortcut of the list (view or status counter).
class _View {
  const _View(this.id, this.label, this.test);
  final String id;
  final String label;
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

  /// Banners displayed above the filters (synchronisation, offline…).
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
        _View(
            'all', widget.mobile ? 'Toutes' : 'Tous les dossiers', (_) => true),
        if (widget.mobile) ...[
          _View('todo', 'À compléter', (o) => o.status.authorCanEdit),
          _View(
              'office',
              'Au bureau',
              (o) =>
                  !o.status.authorCanEdit &&
                  o.status != InstallationStatus.finalized),
          _View('done', 'Sites créés',
              (o) => o.status == InstallationStatus.finalized),
        ],
        if (widget.reviewer && !widget.mobile)
          const _View('action', 'À traiter', _actionable),
        if (!widget.mobile)
          _View('mine', 'Mes demandes', (o) => o.authorUid == widget.ownerUid),
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
                      const Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text('Filtrer par statut',
                              style: InstallationStyle.sectionTitle)),
                      _statusOption(context, null, 'Tous les statuts',
                          widget.orders.length),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: status == null
              ? const Icon(Icons.all_inclusive, size: 20)
              : Icon(installationStatusIcon(status),
                  size: 20, color: installationStatusColor(status)),
          title: Text(label, style: const TextStyle(fontSize: 14)),
          trailing: Text('$count', style: InstallationStyle.caption),
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
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: narrow ? 16 : 28)),
            box(_header(narrow)),
            if (!widget.mobile) box(_counters(contentWidth)),
            for (final notice in widget.notices)
              box(Padding(
                  padding: const EdgeInsets.only(bottom: 12), child: notice)),
            box(_toolbar(narrow, views.values.toList())),
            box(Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 8),
                child: Row(children: [
                  Expanded(
                      child: Text(
                          '${orders.length} dossier${orders.length > 1 ? 's' : ''}'
                          '${_filtered ? ' sur ${widget.orders.length}' : ''}',
                          style: InstallationStyle.caption)),
                  if (_filtered)
                    Flexible(
                        child: TextButton.icon(
                            onPressed: _reset,
                            icon: const Icon(Icons.filter_alt_off_outlined,
                                size: 18),
                            label: const Text('Réinitialiser les filtres',
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
    if (widget.mobile) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
              widget.orders.isEmpty
                  ? 'Vos demandes de mise en place apparaîtront ici.'
                  : 'Suivez vos demandes, du brouillon à l’ouverture du site. Les brouillons restent disponibles hors connexion.',
              style: InstallationStyle.caption));
    }
    final title =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('OUVERTURE DES SITES', style: InstallationStyle.overline),
      const SizedBox(height: 6),
      Text('Bons de mise en place',
          style:
              InstallationStyle.pageTitle.copyWith(fontSize: narrow ? 22 : 26)),
      const SizedBox(height: 6),
      Text(
          widget.reviewer
              ? 'Vérifiez les demandes du terrain et suivez chaque site jusqu’à son ouverture.'
              : 'Initiez une demande et suivez son avancement jusqu’à l’ouverture du site.',
          style: InstallationStyle.caption.copyWith(fontSize: 13.5)),
    ]);
    final create = widget.onCreate == null
        ? null
        : FilledButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add, size: 19),
            label: const Text('Nouvelle demande'));
    return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (narrow) ...[
            title,
            if (create != null) ...[const SizedBox(height: 14), create],
          ] else
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: title),
              if (create != null) ...[const SizedBox(width: 24), create],
            ]),
          if (widget.headerExtra != null) ...[
            const SizedBox(height: 14),
            widget.headerExtra!,
          ],
        ]));
  }

  Widget _counters(double width) {
    const stats = {
      InstallationStatus.submitted: 'À vérifier',
      InstallationStatus.awaitingSignature: 'En signature',
      InstallationStatus.signedReturned: 'À finaliser',
      InstallationStatus.finalized: 'Sites créés',
    };
    final compact = width < 640;
    final tiles = [
      for (final entry in stats.entries)
        _counter(entry.key, entry.value, compact: compact),
    ];
    return Padding(
        padding: const EdgeInsets.only(bottom: 16),
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
            color: selected ? InstallationStyle.primarySoft : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: selected
                        ? InstallationStyle.primary
                        : InstallationStyle.line)),
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
                              size: 19, color: color),
                          const SizedBox(width: 10),
                          if (compact)
                            Text(label,
                                style: const TextStyle(
                                    fontSize: 13, color: InstallationStyle.ink))
                          else
                            Expanded(
                                child: Text(label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: InstallationStyle.ink))),
                          const SizedBox(width: 10),
                          Text('$count',
                              style: TextStyle(
                                  fontSize: compact ? 15 : 20,
                                  fontWeight: FontWeight.w700,
                                  color: InstallationStyle.ink)),
                        ]))))));
  }

  Widget _toolbar(bool narrow, List<_View> views) {
    final search = TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
            hintText: widget.mobile
                ? 'Rechercher un site, un client…'
                : 'Rechercher un site, un client, un bon…',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Effacer la recherche',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                          _search.clear();
                          _query = '';
                        }))),
        onChanged: (v) => setState(() => _query = v.trim()));
    final statusButton = _status == null
        ? OutlinedButton.icon(
            onPressed: _pickStatus,
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Statut'))
        : InputChip(
            label: Text(_status!.label),
            avatar: Icon(installationStatusIcon(_status!),
                size: 17, color: installationStatusColor(_status!)),
            onPressed: _pickStatus,
            onDeleted: () => setState(() => _status = null),
            deleteButtonTooltipMessage: 'Retirer le filtre de statut',
            backgroundColor: InstallationStyle.primarySoft,
            side: BorderSide.none,
            labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: InstallationStyle.primary));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (narrow) ...[
        search,
        const SizedBox(height: 10),
      ],
      Row(children: [
        if (!narrow) ...[
          Expanded(child: search),
          const SizedBox(width: 12),
          statusButton,
        ] else ...[
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    for (final view in views) _viewChip(view),
                  ]))),
          const SizedBox(width: 8),
          statusButton,
        ],
      ]),
      if (!narrow) ...[
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final view in views) _viewChip(view),
        ]),
      ],
    ]);
  }

  Widget _viewChip(_View view) {
    final selected = _view == view.id;
    return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
            label: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(view.label),
              const SizedBox(width: 6),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                      color: selected
                          ? Colors.white
                          : InstallationStyle.background,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('${_counts[view.id] ?? 0}',
                      style: const TextStyle(fontSize: 11))),
            ]),
            selected: selected,
            showCheckmark: false,
            selectedColor: InstallationStyle.primarySoft,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
                fontSize: 13,
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
        icon: none ? Icons.note_add_outlined : Icons.search_off_outlined,
        title: none ? 'Aucune demande pour le moment' : 'Aucun dossier trouvé',
        message: none
            ? widget.onCreate == null
                ? 'Les demandes initiées par le terrain apparaîtront ici.'
                : 'Créez une demande avec les informations du client. Le bon sera préparé après vérification au bureau.'
            : 'Aucun dossier ne correspond à la recherche ou aux filtres.',
        action: none
            ? widget.onCreate == null
                ? null
                : FilledButton.icon(
                    onPressed: widget.onCreate,
                    icon: const Icon(Icons.add, size: 19),
                    label: const Text('Nouvelle demande'))
            : OutlinedButton(
                onPressed: _reset,
                child: const Text('Réinitialiser les filtres')));
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();
  static const _style = TextStyle(
      fontSize: 10.5,
      letterSpacing: 1,
      fontWeight: FontWeight.w600,
      color: InstallationStyle.muted);
  @override
  Widget build(BuildContext context) => Container(
      decoration: const BoxDecoration(
          color: Color(0xFFF9FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          border: Border(bottom: BorderSide(color: InstallationStyle.line))),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(children: [
        Expanded(flex: 4, child: Text('SITE / CLIENT', style: _style)),
        SizedBox(width: 16),
        Expanded(flex: 2, child: Text('INITIATEUR', style: _style)),
        Expanded(flex: 3, child: Text('STATUT', style: _style)),
        Expanded(flex: 2, child: Text('MISE À JOUR', style: _style)),
        SizedBox(width: 20),
      ]));
}
