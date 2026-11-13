import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;

import '../administration/home.dart';
import 'installation_form.dart';
import 'installation_order.dart';
import 'installation_numbering_panel.dart';
import 'installation_pdf.dart';
import 'installation_service.dart';
import 'installation_ui.dart';

class InstallationListPage extends StatefulWidget {
  const InstallationListPage({super.key});
  @override
  State<InstallationListPage> createState() => _InstallationListPageState();
}

class _InstallationListPageState extends State<InstallationListPage> {
  final _service = InstallationService();
  late final _stream = _service.canView ? _service.watchAll() : null;
  late final _numbering =
      _service.canView && _service.canReview ? _service.watchNumbering() : null;
  @override
  Widget build(BuildContext context) => PageModel(
        pageIndex: 22,
        title: 'Bons de mise en place',
        child: Theme(
            data: InstallationStyle.theme(context),
            child: ColoredBox(
              color: InstallationStyle.background,
              child: !_service.canView
                  ? const Center(
                      child: InstallationNotice(
                          icon: Icons.lock_outline,
                          message:
                              'Votre profil ne donne pas accès aux bons de mise en place.'))
                  : StreamBuilder<List<InstallationOrder>>(
                      stream: _stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Padding(
                                  padding: const EdgeInsets.all(32),
                                  child: InstallationNotice(
                                      warning: true,
                                      message:
                                          'Impossible de charger les demandes. ${snapshot.error}')));
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return Column(children: [
                          if (_numbering != null)
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(32, 16, 32, 0),
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: InstallationNumberingPanel(
                                        stream: _numbering!,
                                        canInitialize:
                                            _service.canConfigureNumbering,
                                        onInitialize:
                                            _service.initializeNumbering))),
                          Expanded(
                              child: InstallationWorkspace(
                            orders: snapshot.data!,
                            ownerUid: _service.actor['uid'] as String,
                            reviewer: _service.canReview,
                            onCreate: _service.canAdd
                                ? () =>
                                    context.go('/bons-mise-en-place/nouveau')
                                : null,
                            onOpen: (order) =>
                                context.go('/bons-mise-en-place/${order.id}'),
                          )),
                        ]);
                      }),
            )),
      );
}

class InstallationDetailPage extends StatefulWidget {
  const InstallationDetailPage({super.key, required this.id});
  final String id;
  @override
  State<InstallationDetailPage> createState() => _InstallationDetailPageState();
}

class _InstallationDetailPageState extends State<InstallationDetailPage> {
  final _service = InstallationService();
  final _comment = TextEditingController();
  final _scroll = ScrollController();
  InstallationOrder? _order;
  Map<String, List<InstallationOption>> _options = {};
  String? _error;
  bool _busy = false;
  bool _persisted = false;
  int _formVersion = 0;
  final _validationKey = GlobalKey<FormState>();
  int _validationAttempt = 0;
  int _tab = 0;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _comment.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final order = widget.id == 'nouveau'
          ? _service.newDraft()
          : await _service.one(widget.id);
      final options = await _service.options(order);
      if (!mounted) return;
      setState(() {
        _order = order;
        _options = options;
        _error = null;
        _persisted = widget.id != 'nouveau';
        _dirty = false;
        _formVersion++;
      });
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _error = '$error');
        if (_scroll.hasClients) {
          _scroll.animateTo(0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut);
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted && _persisted && widget.id == 'nouveau' && _error == null) {
      context.replace('/bons-mise-en-place/${_order!.id}');
    }
  }

  Future<void> _save() async {
    _order = await _service.save(_order!);
    _persisted = true;
    _dirty = false;
    if (mounted) setState(() => _formVersion++);
  }

  Future<void> _move(InstallationStatus next, {String message = ''}) =>
      _run(() async {
        if (next == InstallationStatus.submitted ||
            next == InstallationStatus.approved) {
          setState(() {
            _validationAttempt++;
            _tab = 0;
          });
          final fieldsValid = _validationKey.currentState?.validate() ?? true;
          final errors = _order!.validate();
          if (!fieldsValid || errors.isNotEmpty) {
            throw StateError(errors.isEmpty
                ? 'Vérifier les champs indiqués dans le formulaire.'
                : errors.join('\n'));
          }
        }
        // Return first so even an incomplete older request can be sent back.
        // Keep any reviewer edits and save them in the editable correction state.
        if (next == InstallationStatus.changesRequested && _dirty) {
          final edited = _order!;
          final returned = await _service.move(edited, next, message: message);
          edited.status = returned.status;
          edited.revision = returned.revision;
          _order = edited;
          await _save();
          return;
        }
        if (_service.canEdit(_order!) &&
            next != InstallationStatus.changesRequested) {
          await _save();
        }
        final order = await _service.move(_order!, next, message: message);
        if (mounted) {
          setState(() {
            _order = order;
            _formVersion++;
          });
        }
      });

  @override
  Widget build(BuildContext context) {
    final order = _order;
    return PageModel(
        pageIndex: 22,
        title: 'Bons de mise en place',
        child: Theme(
            data: InstallationStyle.theme(context),
            child: ColoredBox(
              color: InstallationStyle.background,
              child: order == null
                  ? Center(
                      child: _error == null
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: InstallationNotice(
                                  warning: true,
                                  message: _error!,
                                  action: TextButton(
                                      onPressed: _load,
                                      child: const Text('Réessayer')))))
                  : LayoutBuilder(builder: (context, constraints) {
                      final compact = constraints.maxWidth < 700;
                      return Column(children: [
                        if (_busy) const LinearProgressIndicator(minHeight: 2),
                        Expanded(
                            child: SingleChildScrollView(
                                controller: _scroll,
                                padding: EdgeInsets.all(compact ? 16 : 32),
                                child: Center(
                                    child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                            maxWidth: 1280),
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(children: [
                                                TextButton.icon(
                                                    onPressed: () => _leave(),
                                                    icon: const Icon(
                                                        Icons.arrow_back,
                                                        size: 16),
                                                    label: const Text(
                                                        'Tous les dossiers')),
                                                const Spacer(),
                                                if (_persisted)
                                                  IconButton(
                                                      tooltip:
                                                          'Actualiser le dossier',
                                                      onPressed: _busy
                                                          ? null
                                                          : () {
                                                              if (_dirty) {
                                                                ScaffoldMessenger.of(
                                                                        context)
                                                                    .showSnackBar(const SnackBar(
                                                                        content:
                                                                            Text('Enregistrez vos modifications avant d’actualiser.')));
                                                              } else {
                                                                _load();
                                                              }
                                                            },
                                                      icon: const Icon(
                                                          Icons.refresh,
                                                          color:
                                                              InstallationStyle
                                                                  .muted)),
                                              ]),
                                              const SizedBox(height: 18),
                                              Wrap(
                                                  spacing: 20,
                                                  runSpacing: 14,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  children: [
                                                    Text(
                                                        order.siteName.isEmpty
                                                            ? 'Nouvelle demande de site'
                                                            : order.siteName,
                                                        style: TextStyle(
                                                            fontSize: compact
                                                                ? 24
                                                                : 30,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            color:
                                                                InstallationStyle
                                                                    .ink)),
                                                    InstallationStatusBadge(
                                                        order.status),
                                                  ]),
                                              const SizedBox(height: 10),
                                              Text(
                                                  '${order.serviceLabel}  ·  Initiée par ${order.authorName}${order.bonNumber.isEmpty ? '' : '  ·  Bon n° ${order.bonNumber}'}',
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color: InstallationStyle
                                                          .muted,
                                                      height: 1.5)),
                                              const SizedBox(height: 24),
                                              InstallationPanel(child:
                                                  LayoutBuilder(
                                                      builder: (context, c) {
                                                final guidance = Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const Text(
                                                          'PROCHAINE ÉTAPE',
                                                          style: TextStyle(
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              letterSpacing:
                                                                  1.3,
                                                              color:
                                                                  InstallationStyle
                                                                      .primary)),
                                                      const SizedBox(
                                                          height: 10),
                                                      Text(
                                                          installationNextStep(
                                                              order.status),
                                                          style: const TextStyle(
                                                              color:
                                                                  InstallationStyle
                                                                      .ink,
                                                              fontSize: 14,
                                                              height: 1.6)),
                                                    ]);
                                                if (c.maxWidth < 800) {
                                                  return Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .stretch,
                                                      children: [
                                                        guidance,
                                                        const SizedBox(
                                                            height: 24),
                                                        InstallationProgress(
                                                            order.status)
                                                      ]);
                                                }
                                                return Row(children: [
                                                  Expanded(child: guidance),
                                                  const SizedBox(width: 40),
                                                  SizedBox(
                                                      width: 390,
                                                      child:
                                                          InstallationProgress(
                                                              order.status))
                                                ]);
                                              })),
                                              const SizedBox(height: 24),
                                              if (_error != null) ...[
                                                InstallationNotice(
                                                    warning: true,
                                                    icon: Icons.error_outline,
                                                    message: _error!),
                                                const SizedBox(height: 18)
                                              ],
                                              SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(children: [
                                                    _tabButton(
                                                        0,
                                                        'La demande',
                                                        Icons
                                                            .description_outlined),
                                                    if (_persisted)
                                                      _tabButton(
                                                          1,
                                                          'Bon signé (${order.attachments.length})',
                                                          Icons.attach_file),
                                                    if (_persisted)
                                                      _tabButton(
                                                          2,
                                                          'Échanges & historique',
                                                          Icons.forum_outlined),
                                                  ])),
                                              const SizedBox(height: 22),
                                              Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                        child: Column(
                                                            children: [
                                                          Visibility(
                                                              visible:
                                                                  _tab == 0,
                                                              maintainState:
                                                                  true,
                                                              child: _service
                                                                      .canEdit(
                                                                          order)
                                                                  ? InstallationForm(
                                                                      key: ValueKey(
                                                                          '${order.id}_$_formVersion'),
                                                                      order:
                                                                          order,
                                                                      enabled:
                                                                          !_busy,
                                                                      guided:
                                                                          true,
                                                                      validationKey:
                                                                          _validationKey,
                                                                      validationAttempt:
                                                                          _validationAttempt,
                                                                      departments:
                                                                          _service
                                                                              .departments,
                                                                      zones:
                                                                          _options['zones'] ??
                                                                              [],
                                                                      supervisors:
                                                                          _options['supervisors'] ??
                                                                              [],
                                                                      catalog:
                                                                          _options['catalog'] ??
                                                                              [],
                                                                      onChanged: () =>
                                                                          setState(() =>
                                                                              _dirty = true),
                                                                      createEquipment: (label, department) => _service.createEquipment(
                                                                          order,
                                                                          label,
                                                                          department),
                                                                    )
                                                                  : InstallationReadOnly(
                                                                      order)),
                                                          if (_tab == 1)
                                                            _attachments(order),
                                                          if (_tab == 2)
                                                            _discussion(order),
                                                        ])),
                                                    if (constraints.maxWidth >=
                                                        1180) ...[
                                                      const SizedBox(width: 24),
                                                      SizedBox(
                                                          width: 265,
                                                          child:
                                                              InstallationPanel(
                                                                  child: Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                const Text(
                                                                    'Le dossier en bref',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            15,
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w700,
                                                                        color: InstallationStyle
                                                                            .ink)),
                                                                const SizedBox(
                                                                    height: 24),
                                                                _summaryLine(
                                                                    Icons
                                                                        .person_outline,
                                                                    'Initiateur',
                                                                    order
                                                                        .authorName),
                                                                _summaryLine(
                                                                    Icons
                                                                        .business_outlined,
                                                                    'Client',
                                                                    order.clientName
                                                                            .isEmpty
                                                                        ? 'À renseigner'
                                                                        : order
                                                                            .clientName),
                                                                _summaryLine(
                                                                    Icons
                                                                        .people_outline,
                                                                    'Agents sur le bon',
                                                                    '${order.agents.length}'),
                                                                _summaryLine(
                                                                    Icons
                                                                        .inventory_2_outlined,
                                                                    'Équipements',
                                                                    '${order.equipment.length} ligne(s)'),
                                                                const Divider(
                                                                    height: 28),
                                                                const Text(
                                                                    'Le site sera créé uniquement après le retour du bon signé et la finalisation par le responsable.',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        height:
                                                                            1.6,
                                                                        color: InstallationStyle
                                                                            .muted)),
                                                              ])))
                                                    ],
                                                  ]),
                                            ]))))),
                        Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                                horizontal: compact ? 16 : 32, vertical: 14),
                            decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                    top: BorderSide(
                                        color: InstallationStyle.line))),
                            child: SafeArea(
                                top: false,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (_service.canEdit(order))
                                        Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10),
                                            child: Text(
                                                _dirty
                                                    ? 'Modifications non enregistrées'
                                                    : _persisted
                                                        ? 'Dernières modifications enregistrées'
                                                        : 'Le site sera créé à la fin du circuit.',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: _dirty
                                                        ? const Color(
                                                            0xFFAB6B19)
                                                        : InstallationStyle
                                                            .muted))),
                                      _actions(order),
                                    ]))),
                      ]);
                    }),
            )));
  }

  Widget _tabButton(int index, String text, IconData icon) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton.icon(
          style: TextButton.styleFrom(
              backgroundColor:
                  _tab == index ? Colors.white : Colors.transparent,
              foregroundColor: _tab == index
                  ? InstallationStyle.primary
                  : InstallationStyle.muted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(
                      color: _tab == index
                          ? InstallationStyle.line
                          : Colors.transparent))),
          onPressed: () => setState(() => _tab = index),
          icon: Icon(icon, size: 18),
          label: Text(text,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))));

  Widget _summaryLine(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: InstallationStyle.muted),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: InstallationStyle.muted)),
          const SizedBox(height: 5),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: InstallationStyle.ink))
        ]))
      ]));

  Future<void> _leave() async {
    if (_dirty) {
      final leave = await _installationDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Quitter la demande ?'),
                  content: const Text(
                      'Vos dernières modifications ne sont pas enregistrées.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Continuer la saisie')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Quitter'))
                  ]));
      if (leave != true) return;
    }
    if (mounted) context.go('/bons-mise-en-place');
  }

  Widget _actions(InstallationOrder order) =>
      Wrap(spacing: 10, runSpacing: 10, children: [
        if (_service.canEdit(order))
          OutlinedButton.icon(
              onPressed: _busy ? null : () => _run(_save),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Enregistrer')),
        if (order.status.authorCanEdit && _service.canEdit(order))
          FilledButton.icon(
              onPressed:
                  _busy ? null : () => _move(InstallationStatus.submitted),
              icon: const Icon(Icons.send_outlined),
              label: const Text('Transmettre au bureau')),
        if (_service.canReview && order.status == InstallationStatus.submitted)
          FilledButton.icon(
              onPressed:
                  _busy ? null : () => _move(InstallationStatus.approved),
              icon: const Icon(Icons.check),
              label: const Text('Valider le bon')),
        if (_service.canReview &&
            ![
              InstallationStatus.draft,
              InstallationStatus.changesRequested,
              InstallationStatus.finalized
            ].contains(order.status))
          OutlinedButton.icon(
              onPressed: _busy ? null : _requestChanges,
              icon: const Icon(Icons.undo),
              label: const Text('Demander une correction')),
        if (_service.canPrint &&
            [
              InstallationStatus.approved,
              InstallationStatus.awaitingSignature,
              InstallationStatus.signedReturned,
              InstallationStatus.finalized
            ].contains(order.status))
          OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _run(() => InstallationPdf.printOrder(order)),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Imprimer le bon')),
        if (_service.canReview && order.status == InstallationStatus.approved)
          FilledButton(
              onPressed: _busy
                  ? null
                  : () => _move(InstallationStatus.awaitingSignature),
              child: const Text('Confirmer la remise')),
        if (_service.canReview &&
            order.status == InstallationStatus.awaitingSignature)
          FilledButton(
              onPressed:
                  _busy ? null : () => _move(InstallationStatus.signedReturned),
              child: const Text('Retour signé reçu')),
        if (_service.canReview &&
            order.status == InstallationStatus.signedReturned)
          FilledButton.icon(
              onPressed: _busy ? null : _finalize,
              icon: const Icon(Icons.add_business),
              label: const Text('Créer le site actif')),
        if (order.siteId != null)
          OutlinedButton.icon(
              onPressed: () => context.go('/sites'),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Voir les sites')),
      ]);

  Future<void> _requestChanges() async {
    final controller = TextEditingController();
    final message = await _installationDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Corrections demandées'),
                content: SizedBox(
                    width: 480,
                    child: TextField(
                        controller: controller,
                        minLines: 3,
                        maxLines: 6,
                        maxLength: 4000,
                        decoration: const InputDecoration(
                            labelText: 'Message à l’initiateur'))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler')),
                  FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          Navigator.pop(context, controller.text.trim());
                        }
                      },
                      child: const Text('Renvoyer'))
                ]));
    controller.dispose();
    if (message != null) {
      await _move(InstallationStatus.changesRequested, message: message);
    }
  }

  Widget _attachments(InstallationOrder order) => InstallationPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Le bon signé',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: InstallationStyle.ink)),
        const SizedBox(height: 10),
        const Text(
            'Joignez une photo ou un scan pour conserver une copie. Le document reste facultatif ; l’original signé doit revenir au bureau.',
            style: TextStyle(
                fontSize: 13, height: 1.6, color: InstallationStyle.muted)),
        const SizedBox(height: 22),
        if (order.attachments.isEmpty)
          const InstallationNotice(
              icon: Icons.description_outlined,
              message: 'Aucun document joint pour le moment.'),
        const SizedBox(height: 12),
        for (final attachment in order.attachments)
          ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(attachment['name'] as String? ?? 'Document'),
              trailing: const Icon(Icons.open_in_new),
              onTap: () {
                final url = Uri.tryParse(attachment['url'] as String? ?? '');
                if (url?.scheme == 'https') {
                  html.window.open(url.toString(), '_blank');
                }
              }),
        if (order.status != InstallationStatus.finalized &&
            (_service.canReview ||
                (_service.canAdd && order.authorUid == _service.actor['uid'])))
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            final picked = await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'pdf',
                                  'jpg',
                                  'jpeg',
                                  'png'
                                ],
                                withData: true);
                            if (picked == null) return;
                            final file = picked.files.single;
                            if (file.bytes == null) {
                              throw StateError(
                                  'Impossible de lire ce document.');
                            }
                            if (_service.canEdit(_order!)) await _save();
                            final updated = await _service.attach(
                                _order!, file.name, file.bytes!);
                            if (mounted) {
                              setState(() {
                                _order = updated;
                                _formVersion++;
                              });
                            }
                          }),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Joindre une photo ou un scan PDF'))),
      ]));

  Widget _discussion(InstallationOrder order) => InstallationPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Échanges & historique',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: InstallationStyle.ink)),
        const SizedBox(height: 8),
        const Text(
            'Les précisions et les étapes du dossier sont conservées ici.',
            style: TextStyle(fontSize: 13, color: InstallationStyle.muted)),
        const SizedBox(height: 12),
        StreamBuilder(
            stream: _service.events(order),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SelectableText('${snapshot.error}');
              }
              if (!snapshot.hasData) return const LinearProgressIndicator();
              return Column(
                  children: snapshot.data!.docs.reversed.map((doc) {
                final event = doc.data();
                return InstallationEventTile(event: event);
              }).toList());
            }),
        if (_service.canReview ||
            (_service.canAdd && order.authorUid == _service.actor['uid'])) ...[
          TextField(
              controller: _comment,
              maxLength: 4000,
              minLines: 1,
              maxLines: 5,
              decoration: const InputDecoration(
                  labelText: 'Ajouter un commentaire',
                  border: OutlineInputBorder())),
          Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await _service.comment(order, _comment.text);
                            _comment.clear();
                          }),
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer'))),
        ],
      ]));

  Future<void> _finalize() async {
    final order = _order!;
    final slug =
        order.siteName.toLowerCase().replaceAll(RegExp('[^a-z0-9]'), '');
    final code = TextEditingController(
        text: '${slug.isEmpty ? 'site' : slug}${order.id.substring(0, 6)}');
    final email = TextEditingController(text: '${code.text}@gmail.com');
    final password = TextEditingController();
    final key = GlobalKey<FormState>();
    final accepted = await _installationDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Créer le site actif'),
              content: SingleChildScrollView(
                  child: SizedBox(
                      width: 460,
                      child: Form(
                          key: key,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text(
                                'Le retour signé est confirmé. Cette action crée le site actif et son compte de connexion.'),
                            const SizedBox(height: 16),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: code,
                                decoration: const InputDecoration(
                                    labelText: 'Code du site'),
                                validator: (value) => value!.trim().isEmpty
                                    ? 'Code requis'
                                    : null),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: email,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                    labelText: 'Email du compte site'),
                                validator: (value) =>
                                    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                            .hasMatch(value!.trim())
                                        ? null
                                        : 'Email invalide'),
                            const SizedBox(height: 16),
                            TextFormField(
                                controller: password,
                                obscureText: true,
                                decoration: const InputDecoration(
                                    labelText: 'Mot de passe initial du site'),
                                validator: (value) => (value?.length ?? 0) < 8
                                    ? 'Huit caractères minimum'
                                    : null),
                          ])))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuler')),
                FilledButton(
                    onPressed: () {
                      if (key.currentState!.validate()) {
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Créer le site actif'))
              ],
            ));
    if (accepted == true) {
      await _run(() async {
        final updated = await _service.finalize(order,
            code: code.text, email: email.text, password: password.text);
        if (mounted) {
          setState(() {
            _order = updated;
            _formVersion++;
          });
        }
      });
    }
    code.dispose();
    email.dispose();
    password.dispose();
  }
}

Future<T?> _installationDialog<T>(
        {required BuildContext context, required WidgetBuilder builder}) =>
    showDialog<T>(
        context: context,
        builder: (dialogContext) => Theme(
            data: InstallationStyle.theme(dialogContext),
            child: Builder(builder: builder)));
