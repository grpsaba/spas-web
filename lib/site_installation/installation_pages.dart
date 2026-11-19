import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;

import '../administration/home.dart';
import 'installation_form.dart';
import 'installation_errors.dart';
import 'installation_order.dart';
import 'installation_numbering_panel.dart';
import 'installation_pdf.dart';
import 'installation_pdf_preview.dart';
import 'installation_service.dart';
import 'installation_ui.dart';

class InstallationListPage extends StatefulWidget {
  const InstallationListPage({super.key});
  @override
  State<InstallationListPage> createState() => _InstallationListPageState();
}

class _InstallationListPageState extends State<InstallationListPage> {
  final _service = InstallationService();
  late Stream<List<InstallationOrder>>? _stream =
      _service.canView ? _service.watchAll() : null;
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
                      child: InstallationStateMessage(
                          icon: Icons.lock_outline,
                          title: 'Accès non autorisé',
                          message:
                              'Votre profil ne donne pas accès aux bons de mise en place. Contactez un administrateur.'))
                  : StreamBuilder<List<InstallationOrder>>(
                      stream: _stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: SingleChildScrollView(
                                  child: InstallationStateMessage(
                                      tone: InstallationTone.error,
                                      icon: Icons.cloud_off_outlined,
                                      title:
                                          'Impossible de charger les demandes',
                                      message: installationErrorMessage(
                                          snapshot.error!),
                                      action: FilledButton.icon(
                                          onPressed: () => setState(() =>
                                              _stream = _service.watchAll()),
                                          icon: const Icon(Icons.refresh),
                                          label: const Text('Réessayer')))));
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                              child: InstallationStateMessage(
                                  loading: true,
                                  title: 'Chargement des demandes…'));
                        }
                        return InstallationWorkspace(
                          orders: snapshot.data!,
                          ownerUid: _service.actor['uid'] as String,
                          reviewer: _service.canReview,
                          headerExtra: _numbering == null
                              ? null
                              : InstallationNumberingPanel(
                                  stream: _numbering!,
                                  canInitialize: _service.canConfigureNumbering,
                                  onInitialize: _service.initializeNumbering),
                          onCreate: _service.canAdd
                              ? () => context.go('/bons-mise-en-place/nouveau')
                              : null,
                          onOpen: (order) =>
                              context.go('/bons-mise-en-place/${order.id}'),
                        );
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
  static const _requestTab = 0, _signedTab = 1, _followTab = 2, _pdfTab = 3;
  final _service = InstallationService();
  final _scroll = ScrollController();
  final _form = InstallationFormController();
  InstallationOrder? _order;
  Map<String, List<InstallationOption>> _options = {};
  Stream<QuerySnapshot<Map<String, dynamic>>>? _events;
  String? _error;
  bool _busy = false;
  bool _persisted = false;
  int _formVersion = 0;
  int _tab = _requestTab;
  bool _previewOpened = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final order = widget.id == 'nouveau'
          ? _service.newDraft()
          : await _service.one(widget.id);
      // Read-only requests do not need the zones, supervisors and catalogue.
      final options = _service.canEdit(order)
          ? await _service.options(order)
          : const <String, List<InstallationOption>>{};
      if (!mounted) return;
      setState(() {
        _order = order;
        _options = options;
        _error = null;
        _persisted = widget.id != 'nouveau';
        _dirty = false;
        _formVersion++;
        if (InstallationPdf.isPrintable(order)) {
          _tab = _pdfTab;
          _previewOpened = true;
        }
      });
    } catch (error) {
      if (mounted) setState(() => _error = installationErrorMessage(error));
    }
  }

  void _notify(String message) => ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _run(Future<void> Function() action, {String? success}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (success != null && mounted) _notify(success);
    } catch (error) {
      if (mounted) {
        setState(() => _error = installationErrorMessage(error));
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

  /// Required fields are checked in the form before any write.
  Future<bool> _checkForm() async {
    if (_tab != _requestTab) {
      setState(() => _tab = _requestTab);
      await WidgetsBinding.instance.endOfFrame;
    }
    final editable = _service.canEdit(_order!);
    final valid = (!editable || _form.validate()) && _order!.validate().isEmpty;
    if (!valid) {
      _notify(editable
          ? 'Complétez les informations signalées avant de continuer.'
          : _order!.validate().join('\n'));
    }
    return valid;
  }

  Future<void> _transmit() async {
    if (_busy || !await _checkForm()) return;
    await _move(InstallationStatus.submitted,
        success: 'Demande transmise au bureau.');
  }

  Future<void> _approve() async {
    if (_busy || !await _checkForm() || !mounted) return;
    final confirmed = await _confirm(
        title: 'Valider le bon ?',
        message: _order!.bonNumber.isEmpty
            ? 'Le prochain numéro de bon sera attribué définitivement à cette demande.'
            : 'Le bon conserve son numéro ${_order!.bonNumber}.',
        action: 'Valider le bon');
    if (confirmed) {
      await _move(InstallationStatus.approved, success: 'Bon validé.');
    }
  }

  Future<void> _move(InstallationStatus next,
          {String message = '', String? success}) =>
      _run(() async {
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
        if ((_dirty || !_persisted) &&
            _service.canEdit(_order!) &&
            next != InstallationStatus.changesRequested) {
          await _save();
        }
        final order = await _service.move(_order!, next, message: message);
        if (mounted) {
          setState(() {
            _order = order;
            _formVersion++;
            if (next == InstallationStatus.approved) {
              _tab = _pdfTab;
              _previewOpened = true;
            }
          });
        }
      }, success: success);

  void _openTab(int tab) {
    FocusScope.of(context).unfocus();
    setState(() {
      _tab = tab;
      if (tab == _pdfTab) _previewOpened = true;
    });
  }

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
                          ? const InstallationStateMessage(
                              loading: true, title: 'Ouverture de la demande…')
                          : SingleChildScrollView(
                              child: InstallationStateMessage(
                                  tone: InstallationTone.error,
                                  icon: Icons.error_outline,
                                  title: 'Impossible d’ouvrir la demande',
                                  message: _error!,
                                  action: Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        OutlinedButton(
                                            onPressed: () => context
                                                .go('/bons-mise-en-place'),
                                            child: const Text(
                                                'Retour à la liste')),
                                        FilledButton.icon(
                                            onPressed: _load,
                                            icon: const Icon(Icons.refresh),
                                            label: const Text('Réessayer')),
                                      ]))))
                  : _page(order),
            )));
  }

  Widget _page(InstallationOrder order) =>
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 700;
        final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
        final editable = _service.canEdit(order);
        final bar = _actionBar(order);
        return Column(children: [
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
              child: SingleChildScrollView(
                  controller: _scroll,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.manual,
                  padding: EdgeInsets.fromLTRB(compact ? 16 : 32,
                      compact ? 12 : 24, compact ? 16 : 32, 32),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _header(order, compact),
                                const SizedBox(height: 16),
                                InstallationNextStepCard(
                                    status: order.status,
                                    guidance: installationGuidance(order.status,
                                        reviewer: _service.canReview)),
                                if (_error != null) ...[
                                  const SizedBox(height: 14),
                                  InstallationNotice(
                                      tone: InstallationTone.error,
                                      title: 'L’action n’a pas abouti',
                                      message: _error!,
                                      action: _dirty
                                          ? null
                                          : TextButton.icon(
                                              onPressed: _busy ? null : _load,
                                              icon: const Icon(Icons.refresh,
                                                  size: 18),
                                              label: const Text(
                                                  'Recharger la fiche'))),
                                ],
                                const SizedBox(height: 18),
                                InstallationTabs(
                                    selected: _tab,
                                    onSelected: _openTab,
                                    tabs: [
                                      InstallationTab(
                                          _requestTab,
                                          editable ? 'Saisie' : 'La demande',
                                          Icons.description_outlined),
                                      const InstallationTab(
                                          _pdfTab,
                                          'Aperçu PDF',
                                          Icons.picture_as_pdf_outlined),
                                      if (_persisted)
                                        const InstallationTab(_followTab,
                                            'Suivi', Icons.forum_outlined),
                                      if (_persisted)
                                        InstallationTab(
                                            _signedTab,
                                            order.attachments.isEmpty
                                                ? 'Bon signé'
                                                : 'Bon signé (${order.attachments.length})',
                                            Icons.attach_file),
                                    ]),
                                const SizedBox(height: 16),
                                Visibility(
                                    visible: _tab == _requestTab,
                                    maintainState: true,
                                    child: editable
                                        ? InstallationForm(
                                            key: ValueKey(
                                                '${order.id}_$_formVersion'),
                                            order: order,
                                            enabled: !_busy,
                                            guided: true,
                                            controller: _form,
                                            departments: _service.departments,
                                            zones:
                                                _options['zones'] ?? const [],
                                            supervisors:
                                                _options['supervisors'] ??
                                                    const [],
                                            catalog:
                                                _options['catalog'] ?? const [],
                                            onChanged: () {
                                              if (!_dirty) {
                                                setState(() => _dirty = true);
                                              }
                                            },
                                            createEquipment: (label,
                                                    department) =>
                                                _service.createEquipment(
                                                    order, label, department),
                                          )
                                        : InstallationReadOnly(order)),
                                if (_tab == _signedTab) _attachments(order),
                                if (_tab == _followTab) _discussion(order),
                                if (_previewOpened)
                                  Visibility(
                                      visible: _tab == _pdfTab,
                                      maintainState: true,
                                      child: InstallationPdfPreview(
                                          order: order,
                                          canPrint: _service.canPrint,
                                          active: _tab == _pdfTab,
                                          hasUnsavedChanges: _dirty)),
                              ]))))),
          // Hidden while typing on a phone so fields stay visible.
          if (!(compact && keyboard)) bar,
        ]);
      });

  Widget _header(InstallationOrder order, bool compact) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          TextButton.icon(
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4)),
              onPressed: _leave,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Tous les dossiers')),
          const Spacer(),
          if (_persisted)
            IconButton(
                tooltip: 'Actualiser le dossier',
                onPressed: _busy
                    ? null
                    : () {
                        if (_dirty) {
                          _notify(
                              'Enregistrez vos modifications avant d’actualiser.');
                        } else {
                          _load();
                        }
                      },
                icon:
                    const Icon(Icons.refresh, color: InstallationStyle.muted)),
        ]),
        const SizedBox(height: 6),
        Text(order.siteName.isEmpty ? 'Nouvelle demande' : order.siteName,
            style: InstallationStyle.pageTitle
                .copyWith(fontSize: compact ? 22 : 28)),
        const SizedBox(height: 6),
        Text(
            [
              order.serviceLabel,
              if (order.authorName.isNotEmpty)
                'Initiée par ${order.authorName}',
              if (order.bonNumber.isNotEmpty) 'Bon n° ${order.bonNumber}',
              if (_persisted && order.updatedAt != null)
                'Mise à jour le ${installationDateLabel(order.updatedAt)}',
            ].join('  ·  '),
            style: InstallationStyle.caption.copyWith(fontSize: 13)),
      ]);

  Widget _actionBar(InstallationOrder order) {
    final editable = _service.canEdit(order);
    final reviewer = _service.canReview;
    final status = order.status;
    InstallationAction? primary;
    final secondary = <InstallationAction>[];
    if (editable && status.authorCanEdit) {
      primary = InstallationAction('Transmettre au bureau', _transmit,
          icon: Icons.send_outlined);
    }
    if (reviewer && status == InstallationStatus.submitted) {
      primary =
          InstallationAction('Valider le bon', _approve, icon: Icons.check);
    }
    if (reviewer && status == InstallationStatus.approved) {
      primary = InstallationAction(
          'Confirmer la remise',
          () => _move(InstallationStatus.awaitingSignature,
              success: 'Remise pour signature confirmée.'),
          icon: Icons.handshake_outlined);
    }
    if (reviewer && status == InstallationStatus.awaitingSignature) {
      primary = InstallationAction(
          'Confirmer le retour signé',
          () => _move(InstallationStatus.signedReturned,
              success: 'Retour du bon signé confirmé.'),
          icon: Icons.assignment_turned_in_outlined);
    }
    if (reviewer && status == InstallationStatus.signedReturned) {
      primary = InstallationAction('Créer le site actif', _finalize,
          icon: Icons.add_business_outlined);
    }
    if (_service.canPrint && InstallationPdf.isPrintable(order)) {
      secondary.add(InstallationAction(
          'Aperçu et impression', () => _openTab(_pdfTab),
          icon: Icons.print_outlined));
    }
    if (order.siteId != null) {
      final sites = InstallationAction(
          'Voir les sites', () => context.go('/sites'),
          icon: Icons.open_in_new);
      if (primary == null) {
        primary = sites;
      } else {
        secondary.add(sites);
      }
    }
    if (reviewer &&
        status.canMoveTo(InstallationStatus.changesRequested, reviewer: true)) {
      secondary.add(InstallationAction(
          'Demander une correction', _requestChanges,
          icon: Icons.undo));
    }
    return InstallationActionBar(
        busy: _busy,
        primary: primary,
        secondary: secondary,
        save: editable
            ? InstallationAction('Enregistrer',
                () => _run(_save, success: 'Modifications enregistrées.'),
                icon: Icons.save_outlined)
            : null,
        status: !editable
            ? null
            : _dirty
                ? 'Modifications non enregistrées'
                : _persisted
                    ? 'Modifications enregistrées'
                    : 'Brouillon pas encore enregistré',
        statusWarning: editable && (_dirty || !_persisted));
  }

  Future<bool> _confirm(
      {required String title,
      required String message,
      required String action}) async {
    final result = await _installationDialog<bool>(
        context: context,
        builder: (context) =>
            AlertDialog(title: Text(title), content: Text(message), actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler')),
              FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(action)),
            ]));
    return result == true;
  }

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
                        child: const Text('Quitter sans enregistrer'))
                  ]));
      if (leave != true) return;
    }
    if (mounted) context.go('/bons-mise-en-place');
  }

  Future<void> _requestChanges() async {
    final message = await _installationDialog<String>(
        context: context, builder: (context) => const _ChangesDialog());
    if (message != null) {
      await _move(InstallationStatus.changesRequested,
          message: message, success: 'Demande renvoyée pour correction.');
    }
  }

  bool _canContribute(InstallationOrder order) =>
      _service.canReview ||
      (_service.canAdd && order.authorUid == _service.actor['uid']);

  Widget _attachments(InstallationOrder order) => InstallationPanel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Bon signé', style: InstallationStyle.sectionTitle),
        const SizedBox(height: 4),
        const Text(
            'Joignez une photo ou un scan pour conserver une copie. Ce document est facultatif ; l’original signé doit revenir au bureau.',
            style: InstallationStyle.caption),
        const SizedBox(height: 16),
        InstallationAttachmentList(
            attachments: order.attachments,
            onOpen: (attachment) {
              final url = Uri.tryParse(attachment['url'] as String? ?? '');
              if (url?.scheme == 'https') {
                html.window.open(url.toString(), '_blank');
              }
            }),
        if (order.status != InstallationStatus.finalized &&
            _canContribute(order)) ...[
          const SizedBox(height: 8),
          Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
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
                          }, success: 'Document ajouté.'),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Joindre une photo ou un PDF'))),
          const SizedBox(height: 6),
          const Text('JPG, PNG ou PDF · 10 Mo maximum · connexion requise',
              style: InstallationStyle.caption),
        ],
      ]));

  Widget _discussion(InstallationOrder order) {
    // One subscription per opened request, not one per rebuild.
    final events = _events ??= _service.events(order);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: events,
        builder: (context, snapshot) => InstallationFollowUp(
                events: [
                  for (final doc in snapshot.data?.docs ?? const [])
                    {...doc.data(), 'id': doc.id}
                ],
                loading: !snapshot.hasData && !snapshot.hasError,
                error: snapshot.hasError
                    ? 'Impossible de charger le suivi. ${installationErrorMessage(snapshot.error!)}'
                    : null,
                onRetry: () => setState(() => _events = _service.events(order)),
                onSend: _canContribute(order)
                    ? (message) => _service.comment(order, message)
                    : null,
                composerHint: _service.canReview
                    ? 'Écrire un message à l’initiateur…'
                    : 'Écrire un message au bureau…'));
  }

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
              scrollable: true,
              title: const Text('Créer le site actif'),
              content: SizedBox(
                  width: 460,
                  child: Form(
                      key: key,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const InstallationNotice(
                            message:
                                'Le retour signé est confirmé. Cette action crée le site actif et son compte de connexion.'),
                        const SizedBox(height: 16),
                        TextFormField(
                            controller: code,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                                labelText: 'Code du site'),
                            validator: (value) =>
                                value!.trim().isEmpty ? 'Code requis' : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                                labelText: 'Email du compte site'),
                            validator: (value) =>
                                RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                        .hasMatch(value!.trim())
                                    ? null
                                    : 'Email invalide'),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: password,
                            obscureText: true,
                            decoration: const InputDecoration(
                                labelText: 'Mot de passe initial du site',
                                helperText: 'Huit caractères minimum'),
                            validator: (value) => (value?.length ?? 0) < 8
                                ? 'Huit caractères minimum'
                                : null),
                      ]))),
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
      }, success: 'Site actif créé.');
    }
    code.dispose();
    email.dispose();
    password.dispose();
  }
}

class _ChangesDialog extends StatefulWidget {
  const _ChangesDialog();
  @override
  State<_ChangesDialog> createState() => _ChangesDialogState();
}

class _ChangesDialogState extends State<_ChangesDialog> {
  final _controller = TextEditingController();
  bool _attempted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _attempted = true);
      return;
    }
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          scrollable: true,
          title: const Text('Demander une correction'),
          content: SizedBox(
              width: 480,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text(
                    'La demande revient à l’initiateur avec votre message. Le numéro déjà attribué est conservé.',
                    style: InstallationStyle.caption),
                const SizedBox(height: 14),
                TextField(
                    controller: _controller,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 4000,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      if (_attempted) setState(() => _attempted = false);
                    },
                    decoration: InputDecoration(
                        labelText: 'Corrections à apporter',
                        hintText: 'Exemple : préciser le contact du client.',
                        errorText: _attempted
                            ? 'Indiquez les corrections attendues.'
                            : null)),
              ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(onPressed: _submit, child: const Text('Renvoyer')),
          ]);
}

Future<T?> _installationDialog<T>(
        {required BuildContext context, required WidgetBuilder builder}) =>
    showDialog<T>(
        context: context,
        builder: (dialogContext) => Theme(
            data: InstallationStyle.theme(dialogContext),
            child: Builder(builder: builder)));
