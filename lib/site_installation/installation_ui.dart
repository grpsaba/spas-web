import 'package:flutter/material.dart';
import 'installation_order.dart';

class InstallationStyle {
  static const background = Color(0xFFF5F7FB);
  static const ink = Color(0xFF17243B);
  static const muted = Color(0xFF69758A);
  static const line = Color(0xFFE3E8F0);
  static const primary = Color(0xFF4F46C8);
  static const green = Color(0xFF147D68);

  static ThemeData theme(BuildContext context) => Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: background,
        dividerColor: line,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          labelStyle: const TextStyle(color: muted, fontSize: 14),
          hintStyle: const TextStyle(color: muted, fontSize: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCDD5E2))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primary, width: 1.6)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: line)),
        ),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: line),
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: primary)),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: ink,
            elevation: 0,
            scrolledUnderElevation: 0),
      );
}

class InstallationPanel extends StatelessWidget {
  const InstallationPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(24)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: InstallationStyle.line)),
        child: child,
      );
}

Color installationStatusColor(InstallationStatus status) => const {
      InstallationStatus.draft: InstallationStyle.muted,
      InstallationStatus.submitted: Color(0xFF3468C0),
      InstallationStatus.changesRequested: Color(0xFFB86A13),
      InstallationStatus.approved: InstallationStyle.primary,
      InstallationStatus.awaitingSignature: Color(0xFF86632F),
      InstallationStatus.signedReturned: InstallationStyle.green,
      InstallationStatus.finalized: InstallationStyle.green,
    }[status]!;

class InstallationStatusBadge extends StatelessWidget {
  const InstallationStatusBadge(this.status, {super.key, this.label});
  final InstallationStatus status;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final color = installationStatusColor(status);
    return Container(
      constraints: const BoxConstraints(maxWidth: 245),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(7)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Flexible(
            child: Text(label ?? status.label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

String installationNextStep(InstallationStatus status, {bool mobile = false}) =>
    {
      InstallationStatus.draft:
          'Complétez la demande, puis transmettez-la au bureau pour vérification.',
      InstallationStatus.changesRequested:
          'Consultez les commentaires, apportez les corrections et transmettez à nouveau la demande.',
      InstallationStatus.submitted: mobile
          ? 'Le bureau vérifie les informations. Vous pouvez échanger avec le responsable dans le suivi.'
          : 'Vérifiez les informations, puis validez ou demandez une correction. Le numéro est attribué automatiquement à la première validation.',
      InstallationStatus.approved: mobile
          ? 'Le bon est validé. Le bureau prépare son impression et sa remise pour signature.'
          : 'Imprimez le bon, signez-le et remettez-le à l’initiateur pour la signature du client.',
      InstallationStatus.awaitingSignature: mobile
          ? 'Faites signer le bon par le client, puis rapportez l’original au bureau. Une photo peut être jointe.'
          : 'Le document est chez l’initiateur pour signature du client. Confirmez son retour une fois l’original reçu.',
      InstallationStatus.signedReturned: mobile
          ? 'Le bon signé est revenu au bureau. Le responsable peut maintenant ouvrir le site.'
          : 'Le retour signé est confirmé. Vous pouvez maintenant créer le site actif et son compte.',
      InstallationStatus.finalized:
          'Le site est actif. Ce dossier conserve le bon et l’historique des échanges.',
    }[status]!;

class InstallationProgress extends StatelessWidget {
  const InstallationProgress(this.status, {super.key});
  final InstallationStatus status;
  int get step => const {
        InstallationStatus.draft: 0,
        InstallationStatus.changesRequested: 0,
        InstallationStatus.submitted: 1,
        InstallationStatus.approved: 2,
        InstallationStatus.awaitingSignature: 2,
        InstallationStatus.signedReturned: 2,
        InstallationStatus.finalized: 3,
      }[status]!;
  @override
  Widget build(BuildContext context) =>
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < 4; i++)
          Expanded(
              child: Column(children: [
            Row(children: [
              Expanded(
                  child: Container(
                      height: 2,
                      color: i == 0
                          ? Colors.transparent
                          : i <= step
                              ? InstallationStyle.primary
                              : InstallationStyle.line)),
              Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= step
                          ? InstallationStyle.primary
                          : InstallationStyle.background),
                  child: i < step
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: i == step
                                  ? Colors.white
                                  : InstallationStyle.muted))),
              Expanded(
                  child: Container(
                      height: 2,
                      color: i == 3
                          ? Colors.transparent
                          : i < step
                              ? InstallationStyle.primary
                              : InstallationStyle.line)),
            ]),
            const SizedBox(height: 8),
            Text(
                const ['Demande', 'Vérification', 'Signature', 'Site actif'][i],
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: i == step
                        ? InstallationStyle.primary
                        : InstallationStyle.muted,
                    fontWeight: i == step ? FontWeight.w700 : FontWeight.w400)),
          ])),
      ]);
}

class InstallationNotice extends StatelessWidget {
  const InstallationNotice(
      {super.key,
      required this.message,
      this.icon = Icons.info_outline,
      this.warning = false,
      this.action});
  final String message;
  final IconData icon;
  final bool warning;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: warning ? const Color(0xFFFFF6E7) : const Color(0xFFEEF1FD),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon,
                size: 19,
                color: warning
                    ? const Color(0xFF9A5A13)
                    : InstallationStyle.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: InstallationStyle.ink))),
          ]),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 10), child: action!),
        ]),
      );
}

String installationDateLabel(DateTime? date) => date == null
    ? 'À l’instant'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

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
  @override
  Widget build(BuildContext context) {
    final title =
        order.siteName.isEmpty ? 'Demande à compléter' : order.siteName;
    final identity = Row(children: [
      Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: InstallationStyle.background,
              borderRadius: BorderRadius.circular(11)),
          child: Icon(
              order.isSecurity
                  ? Icons.shield_outlined
                  : Icons.cleaning_services_outlined,
              size: 20,
              color: InstallationStyle.primary)),
      const SizedBox(width: 13),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: InstallationStyle.ink)),
        const SizedBox(height: 4),
        Text(order.clientName.isEmpty ? order.serviceLabel : order.clientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                const TextStyle(color: InstallationStyle.muted, fontSize: 12)),
      ])),
    ]);
    return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(desktop ? 0 : 14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(desktop ? 0 : 14),
          child: Padding(
              padding: EdgeInsets.all(desktop ? 20 : 18),
              child: desktop
                  ? Row(children: [
                      Expanded(flex: 4, child: identity),
                      const SizedBox(width: 16),
                      Expanded(
                          flex: 2,
                          child: Text(order.authorName,
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
                                    style: const TextStyle(
                                        color: InstallationStyle.muted,
                                        fontSize: 12)),
                                if (order.bonNumber.isNotEmpty)
                                  Text('N° ${order.bonNumber}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: InstallationStyle.ink)),
                              ])),
                      const Icon(Icons.arrow_forward,
                          size: 18, color: InstallationStyle.muted),
                    ])
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(children: [
                            Expanded(child: identity),
                            const Icon(Icons.chevron_right,
                                size: 20, color: InstallationStyle.muted)
                          ]),
                          const SizedBox(height: 16),
                          Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                InstallationStatusBadge(order.status),
                                Text(
                                    order.bonNumber.isEmpty
                                        ? order.serviceLabel
                                        : 'Bon n° ${order.bonNumber}',
                                    style: const TextStyle(
                                        color: InstallationStyle.muted,
                                        fontSize: 12)),
                              ]),
                          if (syncLabel != null) ...[
                            const SizedBox(height: 13),
                            const Divider(height: 1),
                            const SizedBox(height: 11),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                      needsAttention
                                          ? Icons.cloud_upload_outlined
                                          : Icons.check_circle_outline,
                                      size: 15,
                                      color: needsAttention
                                          ? const Color(0xFFAB6B19)
                                          : InstallationStyle.green),
                                  const SizedBox(width: 6),
                                  Expanded(
                                      child: Text(syncLabel!,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: needsAttention
                                                  ? const Color(0xFFAB6B19)
                                                  : InstallationStyle.muted)))
                                ]),
                          ] else ...[
                            const SizedBox(height: 12),
                            Text(
                                '${order.authorName} · ${installationDateLabel(order.updatedAt)}',
                                style: const TextStyle(
                                    color: InstallationStyle.muted,
                                    fontSize: 12)),
                          ],
                        ])),
        ));
  }
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
      this.attentionIds = const {}});
  final List<InstallationOrder> orders;
  final String ownerUid;
  final ValueChanged<InstallationOrder> onOpen;
  final VoidCallback? onCreate;
  final bool reviewer;
  final bool mobile;
  final Map<String, String> syncLabels;
  final Set<String> attentionIds;
  @override
  State<InstallationWorkspace> createState() => _InstallationWorkspaceState();
}

class _InstallationWorkspaceState extends State<InstallationWorkspace> {
  String _query = '';
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _view = 'all';
  InstallationStatus? _status;
  bool _actionable(InstallationOrder o) => [
        InstallationStatus.submitted,
        InstallationStatus.signedReturned
      ].contains(o.status);
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final narrow = constraints.maxWidth < 680;
        final desktop = constraints.maxWidth >= 1050;
        final orders = widget.orders
            .where((o) =>
                (_view != 'mine' || o.authorUid == widget.ownerUid) &&
                (_view != 'action' || _actionable(o)) &&
                (_view != 'active' ||
                    o.status != InstallationStatus.finalized) &&
                (_status == null || o.status == _status) &&
                '${o.siteName} ${o.clientName} ${o.bonNumber} ${o.authorName}'
                    .toLowerCase()
                    .contains(_query))
            .toList();
        return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(narrow ? 16 : 32, 24, narrow ? 16 : 32,
                widget.mobile ? 100 : 36),
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1280),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!widget.mobile) ...[
                            const Text('OUVERTURE DES SITES',
                                style: TextStyle(
                                    color: InstallationStyle.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.6)),
                            const SizedBox(height: 10),
                            Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                spacing: 24,
                                runSpacing: 18,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  SizedBox(
                                      width: narrow
                                          ? double.infinity
                                          : constraints.maxWidth
                                                  .clamp(0, 720)
                                                  .toDouble() *
                                              .7,
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Bons de mise en place',
                                                style: TextStyle(
                                                    fontSize: 28,
                                                    height: 1.2,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        InstallationStyle.ink)),
                                            const SizedBox(height: 8),
                                            Text(
                                                widget.reviewer
                                                    ? 'Vérifiez les demandes du terrain et accompagnez chaque site jusqu’à son ouverture.'
                                                    : 'Initiez une demande et retrouvez ici son avancement jusqu’à l’ouverture du site.',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        InstallationStyle.muted,
                                                    height: 1.5)),
                                          ])),
                                  if (widget.onCreate != null)
                                    FilledButton.icon(
                                        onPressed: widget.onCreate,
                                        icon: const Icon(Icons.add, size: 19),
                                        label:
                                            const Text('Initier une demande')),
                                ]),
                            const SizedBox(height: 28),
                            LayoutBuilder(builder: (context, c) {
                              final columns = c.maxWidth >= 900 ? 4 : 2;
                              final stats = [
                                [
                                  InstallationStatus.submitted,
                                  'À vérifier',
                                  Icons.fact_check_outlined
                                ],
                                [
                                  InstallationStatus.awaitingSignature,
                                  'En signature',
                                  Icons.draw_outlined
                                ],
                                [
                                  InstallationStatus.signedReturned,
                                  'À finaliser',
                                  Icons.add_business_outlined
                                ],
                                [
                                  InstallationStatus.finalized,
                                  'Sites créés',
                                  Icons.check_circle_outline
                                ],
                              ];
                              return Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: stats.map((s) {
                                    final selected =
                                        _status == (s[0] as InstallationStatus);
                                    return SizedBox(
                                        width: (c.maxWidth - (columns - 1) * 12) /
                                            columns,
                                        child: Material(
                                            color: selected
                                                ? const Color(0xFFEEECFC)
                                                : Colors.white,
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                    color: selected
                                                        ? InstallationStyle
                                                            .primary
                                                        : InstallationStyle
                                                            .line)),
                                            child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: () => setState(() =>
                                                    _status = selected
                                                        ? null
                                                        : (s[0]
                                                            as InstallationStatus)),
                                                child: Padding(
                                                    padding: const EdgeInsets.all(
                                                        18),
                                                    child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Row(children: [
                                                            Icon(
                                                                (s[2]
                                                                    as IconData),
                                                                size: 19,
                                                                color: installationStatusColor((s[
                                                                        0]
                                                                    as InstallationStatus))),
                                                            const Spacer(),
                                                            Text(
                                                                '${widget.orders.where((o) => o.status == (s[0] as InstallationStatus)).length}',
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        25,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color:
                                                                        InstallationStyle
                                                                            .ink))
                                                          ]),
                                                          const SizedBox(
                                                              height: 14),
                                                          Text((s[1] as String),
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: InstallationStyle
                                                                      .muted)),
                                                        ])))));
                                  }).toList());
                            }),
                            const SizedBox(height: 28),
                          ] else ...[
                            const Text('Vos demandes, au même endroit',
                                style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    color: InstallationStyle.ink)),
                            const SizedBox(height: 8),
                            const Text('Du brouillon à l’ouverture du site.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: InstallationStyle.muted)),
                            const SizedBox(height: 14),
                            const Row(children: [
                              Icon(Icons.offline_pin_outlined,
                                  size: 15, color: InstallationStyle.green),
                              SizedBox(width: 6),
                              Expanded(
                                  child: Text(
                                      'Brouillons disponibles hors connexion',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: InstallationStyle.muted)))
                            ]),
                            const SizedBox(height: 20),
                          ],
                          SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(children: [
                                _viewChip(
                                    'all',
                                    widget.mobile
                                        ? 'Toutes'
                                        : 'Tous les dossiers',
                                    widget.orders.length),
                                if (widget.mobile)
                                  _viewChip(
                                      'active',
                                      'En cours',
                                      widget.orders
                                          .where((o) =>
                                              o.status !=
                                              InstallationStatus.finalized)
                                          .length),
                                if (widget.reviewer)
                                  _viewChip('action', 'À traiter',
                                      widget.orders.where(_actionable).length),
                                if (!widget.mobile)
                                  _viewChip(
                                      'mine',
                                      'Mes demandes',
                                      widget.orders
                                          .where((o) =>
                                              o.authorUid == widget.ownerUid)
                                          .length),
                              ])),
                          const SizedBox(height: 18),
                          if (widget.mobile)
                            Row(children: [
                              Expanded(
                                  child: TextField(
                                      controller: _search,
                                      decoration: const InputDecoration(
                                          hintText: 'Rechercher une demande…',
                                          prefixIcon:
                                              Icon(Icons.search, size: 20)),
                                      onChanged: (v) => setState(() =>
                                          _query = v.trim().toLowerCase()))),
                              const SizedBox(width: 10),
                              Container(
                                  decoration: BoxDecoration(
                                      color: _status == null
                                          ? Colors.white
                                          : const Color(0xFFEEECFC),
                                      border: Border.all(
                                          color: InstallationStyle.line),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: PopupMenuButton<String>(
                                    tooltip: 'Filtrer par statut',
                                    icon: Icon(Icons.tune,
                                        color: _status == null
                                            ? InstallationStyle.muted
                                            : InstallationStyle.primary),
                                    padding: const EdgeInsets.all(15),
                                    onSelected: (v) => setState(() => _status =
                                        v == 'all'
                                            ? null
                                            : InstallationStatus.values
                                                .firstWhere(
                                                    (s) => s.name == v)),
                                    itemBuilder: (_) => [
                                      const PopupMenuItem(
                                          value: 'all',
                                          child: Text('Tous les statuts')),
                                      ...InstallationStatus.values.map((s) =>
                                          PopupMenuItem(
                                              value: s.name,
                                              child: Text(s.label)))
                                    ],
                                  )),
                            ])
                          else
                            LayoutBuilder(
                                builder: (context, c) => Wrap(
                                        spacing: 12,
                                        runSpacing: 12,
                                        children: [
                                          SizedBox(
                                              width: c.maxWidth < 580
                                                  ? c.maxWidth
                                                  : c.maxWidth - 242,
                                              child: TextField(
                                                  controller: _search,
                                                  decoration: const InputDecoration(
                                                      hintText:
                                                          'Rechercher un site, un client, un bon…',
                                                      prefixIcon: Icon(
                                                          Icons.search,
                                                          size: 21)),
                                                  onChanged: (v) => setState(
                                                      () => _query = v
                                                          .trim()
                                                          .toLowerCase()))),
                                          SizedBox(
                                              width: c.maxWidth < 580
                                                  ? c.maxWidth
                                                  : 230,
                                              child: DropdownButtonFormField<
                                                      InstallationStatus>(
                                                  key: ValueKey(_status),
                                                  initialValue: _status,
                                                  isExpanded: true,
                                                  decoration:
                                                      const InputDecoration(
                                                          labelText: 'Statut'),
                                                  items: [
                                                    const DropdownMenuItem<
                                                            InstallationStatus>(
                                                        value: null,
                                                        child: Text(
                                                            'Tous les statuts')),
                                                    ...InstallationStatus.values.map(
                                                        (s) => DropdownMenuItem(
                                                            value: s,
                                                            child: Text(s.label,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis)))
                                                  ],
                                                  onChanged: (v) => setState(
                                                      () => _status = v))),
                                        ])),
                          const SizedBox(height: 20),
                          Row(children: [
                            Text(
                                '${orders.length} dossier${orders.length == 1 ? '' : 's'}',
                                style: const TextStyle(
                                    color: InstallationStyle.muted,
                                    fontSize: 12)),
                            const Spacer(),
                            if (_status != null ||
                                _query.isNotEmpty ||
                                _view != 'all')
                              TextButton(
                                  onPressed: () => setState(() {
                                        _status = null;
                                        _query = '';
                                        _search.clear();
                                        _view = 'all';
                                      }),
                                  child:
                                      const Text('Réinitialiser les filtres')),
                          ]),
                          const SizedBox(height: 8),
                          if (orders.isEmpty)
                            InstallationPanel(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 32),
                                    child: Column(children: [
                                      Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: const BoxDecoration(
                                              color:
                                                  InstallationStyle.background,
                                              shape: BoxShape.circle),
                                          child: const Icon(
                                              Icons.note_add_outlined,
                                              size: 32,
                                              color:
                                                  InstallationStyle.primary)),
                                      const SizedBox(height: 20),
                                      Text(
                                          widget.orders.isEmpty
                                              ? 'Le prochain site commence ici'
                                              : 'Aucun dossier dans cette vue',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                              color: InstallationStyle.ink)),
                                      const SizedBox(height: 10),
                                      Text(
                                          widget.orders.isEmpty
                                              ? 'Initiez une demande avec les informations du client.\nLe bon sera préparé après vérification au bureau.'
                                              : 'Modifiez les filtres pour retrouver vos demandes.',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              color: InstallationStyle.muted,
                                              fontSize: 13,
                                              height: 1.6)),
                                      if (widget.onCreate != null &&
                                          widget.orders.isEmpty) ...[
                                        const SizedBox(height: 22),
                                        FilledButton.icon(
                                            onPressed: widget.onCreate,
                                            icon:
                                                const Icon(Icons.add, size: 18),
                                            label: const Text(
                                                'Initier une demande'))
                                      ],
                                    ])))
                          else if (desktop && !widget.mobile)
                            InstallationPanel(
                                padding: EdgeInsets.zero,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Column(children: [
                                      Container(
                                          color: const Color(0xFFF9FAFC),
                                          padding: const EdgeInsets.all(20),
                                          child: const Row(children: [
                                            Expanded(
                                                flex: 4,
                                                child: Text('SITE / CLIENT',
                                                    style: _columnStyle)),
                                            SizedBox(width: 16),
                                            Expanded(
                                                flex: 2,
                                                child: Text('INITIATEUR',
                                                    style: _columnStyle)),
                                            Expanded(
                                                flex: 3,
                                                child: Text('AVANCEMENT',
                                                    style: _columnStyle)),
                                            Expanded(
                                                flex: 2,
                                                child: Text('MISE À JOUR',
                                                    style: _columnStyle)),
                                            SizedBox(width: 18),
                                          ])),
                                      for (final order in orders) ...[
                                        const Divider(height: 1),
                                        InstallationOrderTile(
                                            order: order,
                                            desktop: true,
                                            onTap: () => widget.onOpen(order))
                                      ],
                                    ])))
                          else
                            for (final order in orders)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: DecoratedBox(
                                      decoration: BoxDecoration(
                                          border: Border.all(
                                              color: InstallationStyle.line),
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: InstallationOrderTile(
                                          order: order,
                                          onTap: () => widget.onOpen(order),
                                          syncLabel:
                                              widget.syncLabels[order.id],
                                          needsAttention: widget.attentionIds
                                              .contains(order.id)))),
                        ]))));
      });
  static const _columnStyle = TextStyle(
      fontSize: 10,
      letterSpacing: 1,
      fontWeight: FontWeight.w600,
      color: InstallationStyle.muted);
  Widget _viewChip(String value, String label, int count) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
          label: Text('$label  $count'),
          selected: _view == value,
          showCheckmark: false,
          selectedColor: const Color(0xFFEEECFC),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _view == value
                  ? InstallationStyle.primary
                  : InstallationStyle.muted),
          side: BorderSide(
              color: _view == value
                  ? InstallationStyle.primary.withValues(alpha: .3)
                  : InstallationStyle.line),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          onSelected: (_) => setState(() => _view = value)));
}

class InstallationReadOnly extends StatelessWidget {
  const InstallationReadOnly(this.order, {super.key});
  final InstallationOrder order;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InstallationPanel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Le site et son client',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: InstallationStyle.ink)),
          const SizedBox(height: 20),
          _value('Client', order.clientName),
          _value('Site', order.siteName),
          _value('Adresse', order.address),
          if (order.phone.isNotEmpty) _value('Contact', order.phone),
          _value('Prestation', order.serviceLabel),
          if (order.bonNumber.isNotEmpty)
            _value('Numéro du bon', order.bonNumber),
        ])),
        const SizedBox(height: 16),
        InstallationPanel(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text('Agents prévus · ${order.agents.length}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: InstallationStyle.ink)),
              const SizedBox(height: 16),
              if (order.agents.isEmpty)
                const Text('Aucun nom renseigné.',
                    style: TextStyle(
                        color: InstallationStyle.muted, fontSize: 13)),
              for (final agent in order.agents)
                Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person_outline,
                              size: 19, color: InstallationStyle.muted),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(agent.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: InstallationStyle.ink)),
                                Text(
                                    [agent.type, agent.phone]
                                        .where((s) => s.isNotEmpty)
                                        .join(' · '),
                                    style: const TextStyle(
                                        color: InstallationStyle.muted,
                                        fontSize: 12))
                              ]))
                        ])),
            ])),
        const SizedBox(height: 16),
        InstallationPanel(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Text('Équipements · ${order.equipment.length}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: InstallationStyle.ink)),
              const SizedBox(height: 16),
              if (order.equipment.isEmpty)
                const Text('Aucun équipement renseigné.',
                    style: TextStyle(
                        color: InstallationStyle.muted, fontSize: 13)),
              for (final item in order.equipment)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(children: [
                      Expanded(
                          child: Text(item.designation,
                              style: const TextStyle(
                                  color: InstallationStyle.ink))),
                      Text('× ${item.quantity}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: InstallationStyle.ink))
                    ])),
            ])),
        const SizedBox(height: 16),
        InstallationPanel(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Organisation du site',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: InstallationStyle.ink)),
          const SizedBox(height: 20),
          _value('Zone', order.zone?['name'] as String? ?? ''),
          _value(
              'Superviseur',
              '${order.supervisor?['firstName'] ?? ''} ${order.supervisor?['lastName'] ?? ''}'
                  .trim()),
          if (order.supervisor2 != null)
            _value(
                'Second superviseur',
                '${order.supervisor2?['firstName'] ?? ''} ${order.supervisor2?['lastName'] ?? ''}'
                    .trim()),
          _value('Effectif / rondes',
              '${order.agentCount} agent(s) · ${order.roundCount} ronde(s)'),
          _value(
              'Pointage',
              order.pointageType == 'jour_nuit'
                  ? 'Jour et nuit'
                  : order.pointageType == 'nuit'
                      ? 'Nuit'
                      : 'Jour'),
          if (order.contractDate != null)
            _value(
                'Date du contrat', installationDateLabel(order.contractDate)),
          if (order.latitude != null && order.longitude != null)
            _value('Position GPS', '${order.latitude}, ${order.longitude}'),
        ])),
      ]);
  Widget _value(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                const TextStyle(color: InstallationStyle.muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value.isEmpty ? 'À compléter' : value,
            style: const TextStyle(
                color: InstallationStyle.ink,
                fontWeight: FontWeight.w500,
                fontSize: 14))
      ]));
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
    return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: comment
                      ? const Color(0xFFEEECFC)
                      : InstallationStyle.background,
                  shape: BoxShape.circle),
              child: Icon(comment ? Icons.chat_bubble_outline : Icons.check,
                  size: 15,
                  color: comment
                      ? InstallationStyle.primary
                      : InstallationStyle.muted)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(author.isEmpty ? 'Suivi du dossier' : author,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: InstallationStyle.ink)),
                const SizedBox(height: 5),
                SelectableText(event['message'] as String? ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: InstallationStyle.ink)),
                const SizedBox(height: 5),
                Text(
                    pending
                        ? 'En attente d’envoi'
                        : at == null
                            ? ''
                            : '${installationDateLabel(at)} · ${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                        color: InstallationStyle.muted, fontSize: 11)),
              ])),
        ]));
  }
}
