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
                          icon: Icons.lock_outline, title: 'Accès refusé'))
                  : StreamBuilder<List<InstallationOrder>>(
                      stream: _stream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: SingleChildScrollView(
                                  child: InstallationStateMessage(
                                      tone: InstallationTone.error,
                                      icon: Icons.cloud_off_outlined,
                                      title: 'Erreur de chargement',
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
                                  loading: true, title: 'Chargement…'));
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
    _form.dispose();
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

  void _notify(String message, {IconData icon = Icons.check_circle}) =>
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Row(children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Flexible(child: Text(message)),
        ])));

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
      _notify(editable ? 'À compléter' : _order!.validate().first,
          icon: Icons.error_outline);
    }
    return valid;
  }

  Future<void> _transmit() async {
    if (_busy || !await _checkForm()) return;
    await _move(InstallationStatus.submitted, success: 'Envoyé');
  }

  Future<void> _approve() async {
    if (_busy || !await _checkForm() || !mounted) return;
    final confirmed = await _confirm(
        title: 'Valider ce bon ?',
        message: _order!.bonNumber.isEmpty
            ? 'Numéro définitif'
            : 'N° ${_order!.bonNumber}',
        action: 'Valider',
        icon: Icons.check_circle);
    if (confirmed) {
      await _move(InstallationStatus.approved, success: 'Validé');
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
                              loading: true, title: 'Chargement…')
                          : SingleChildScrollView(
                              child: InstallationStateMessage(
                                  tone: InstallationTone.error,
                                  icon: Icons.error_outline,
                                  title: 'Erreur de chargement',
                                  message: _error!,
                                  action: Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      alignment: WrapAlignment.center,
                                      children: [
                                        OutlinedButton.icon(
                                            onPressed: () => context
                                                .go('/bons-mise-en-place'),
                                            icon: const Icon(Icons.list),
                                            label: const Text('Liste')),
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
        final editable = _service.canEdit(order);
        return Column(children: [
          if (_busy) const LinearProgressIndicator(minHeight: 3),
          Expanded(
              child: SingleChildScrollView(
                  controller: _scroll,
                  padding: EdgeInsets.fromLTRB(compact ? 12 : 32,
                      compact ? 8 : 20, compact ? 12 : 32, 24),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _header(order, compact),
                                const SizedBox(height: 12),
                                InstallationNextStepCard(
                                    status: order.status,
                                    guidance: installationGuidance(order.status,
                                        reviewer: _service.canReview)),
                                if (_error != null) ...[
                                  const SizedBox(height: 12),
                                  InstallationNotice(
                                      tone: InstallationTone.error,
                                      message: _error!,
                                      action: _dirty
                                          ? null
                                          : TextButton.icon(
                                              onPressed: _busy ? null : _load,
                                              icon: const Icon(Icons.refresh,
                                                  size: 18),
                                              label: const Text('Recharger'))),
                                ],
                                const SizedBox(height: 14),
                                InstallationTabs(
                                    selected: _tab,
                                    onSelected: _openTab,
                                    tabs: [
                                      const InstallationTab(
                                          _requestTab,
                                          'Demande',
                                          Icons.description_outlined),
                                      const InstallationTab(_pdfTab, 'Aperçu',
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
                                            Icons.draw_outlined),
                                    ]),
                                const SizedBox(height: 14),
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
                                            showNavigation: false,
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
          // Stays above the keyboard: the main button is never hidden.
          ListenableBuilder(
              listenable: _form, builder: (context, _) => _actionBar(order)),
        ]);
      });

  Widget _header(InstallationOrder order, bool compact) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          TextButton.icon(
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6)),
              onPressed: _leave,
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text('Liste')),
          const Spacer(),
          if (_persisted)
            IconButton(
                tooltip: 'Actualiser',
                onPressed: _busy
                    ? null
                    : () {
                        if (_dirty) {
                          _notify('Enregistrez d’abord',
                              icon: Icons.save_outlined);
                        } else {
                          _load();
                        }
                      },
                icon:
                    const Icon(Icons.refresh, color: InstallationStyle.muted)),
        ]),
        Text(order.siteName.isEmpty ? 'Nouvelle demande' : order.siteName,
            style: InstallationStyle.pageTitle
                .copyWith(fontSize: compact ? 22 : 28)),
        const SizedBox(height: 6),
        Wrap(spacing: 14, runSpacing: 4, children: [
          _fact(
              order.isSecurity
                  ? Icons.shield_outlined
                  : Icons.cleaning_services_outlined,
              order.serviceLabel),
          if (order.authorName.isNotEmpty)
            _fact(Icons.person_outline, order.authorName),
          if (order.bonNumber.isNotEmpty) _fact(Icons.numbers, order.bonNumber),
        ]),
      ]);

  Widget _fact(IconData icon, String text) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 17, color: InstallationStyle.muted),
        const SizedBox(width: 4),
        Text(text, style: InstallationStyle.caption.copyWith(fontSize: 13.5)),
      ]);

  Widget _actionBar(InstallationOrder order) {
    final editable = _service.canEdit(order);
    final reviewer = _service.canReview;
    final status = order.status;
    InstallationAction? primary;
    InstallationAction? back;
    final secondary = <InstallationAction>[];
    // On the follow-up tab, the only « send » is the message field.
    if (editable && status.authorCanEdit && _tab != _followTab) {
      final wizard = _tab == _requestTab && !_form.isLast;
      if (_tab == _requestTab && _form.step > 0) {
        back = InstallationAction('Retour', _form.back, icon: Icons.arrow_back);
      }
      primary = wizard
          ? InstallationAction('Suivant', _form.next, icon: Icons.arrow_forward)
          : InstallationAction('Envoyer', _transmit, icon: Icons.send);
    }
    if (reviewer && status == InstallationStatus.submitted) {
      primary =
          InstallationAction('Valider', _approve, icon: Icons.check_circle);
    }
    if (reviewer && status == InstallationStatus.approved) {
      primary = InstallationAction(
          'Bon remis',
          () => _move(InstallationStatus.awaitingSignature,
              success: 'Remise confirmée'),
          icon: Icons.handshake_outlined);
    }
    if (reviewer && status == InstallationStatus.awaitingSignature) {
      primary = InstallationAction(
          'Bon signé reçu',
          () => _move(InstallationStatus.signedReturned,
              success: 'Bon signé reçu'),
          icon: Icons.assignment_turned_in);
    }
    if (reviewer && status == InstallationStatus.signedReturned) {
      primary = InstallationAction('Créer le site', _finalize,
          icon: Icons.add_business);
    }
    if (_service.canPrint && InstallationPdf.isPrintable(order)) {
      secondary.add(InstallationAction('Imprimer', () => _openTab(_pdfTab),
          icon: Icons.print_outlined));
    }
    if (order.siteId != null) {
      final sites = InstallationAction(
          'Voir les sites', () => context.go('/sites'),
          icon: Icons.storefront);
      if (primary == null) {
        primary = sites;
      } else {
        secondary.add(sites);
      }
    }
    if (reviewer &&
        status.canMoveTo(InstallationStatus.changesRequested, reviewer: true)) {
      secondary.add(
          InstallationAction('À corriger', _requestChanges, icon: Icons.undo));
    }
    return InstallationActionBar(
        busy: _busy,
        primary: primary,
        back: back,
        secondary: secondary,
        save: editable
            ? InstallationAction(
                'Enregistrer', () => _run(_save, success: 'Enregistré'),
                icon: Icons.save_outlined)
            : null,
        status: !editable
            ? null
            : _dirty || !_persisted
                ? 'Non enregistré'
                : 'Enregistré',
        statusWarning: editable && (_dirty || !_persisted));
  }

  Future<bool> _confirm(
      {required String title,
      required String message,
      required String action,
      required IconData icon}) async {
    final result = await _installationDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                icon: Icon(icon, size: 36),
                title: Text(title),
                content: Text(message, textAlign: TextAlign.center),
                actions: [
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
      final leave = await _confirm(
          title: 'Quitter ?',
          message: 'Non enregistré',
          action: 'Quitter',
          icon: Icons.warning_amber_rounded);
      if (!leave) return;
    }
    if (mounted) context.go('/bons-mise-en-place');
  }

  Future<void> _requestChanges() async {
    final message = await _installationDialog<String>(
        context: context, builder: (context) => const _ChangesDialog());
    if (message != null) {
      await _move(InstallationStatus.changesRequested,
          message: message, success: 'Renvoyé pour correction');
    }
  }

  bool _canContribute(InstallationOrder order) =>
      _service.canReview ||
      (_service.canAdd && order.authorUid == _service.actor['uid']);

  Widget _attachments(InstallationOrder order) => InstallationPanel(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
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
          OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52)),
              onPressed: _busy
                  ? null
                  : () => _run(() async {
                        final picked = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            withData: true);
                        if (picked == null) return;
                        final file = picked.files.single;
                        if (file.bytes == null) {
                          throw StateError('Fichier illisible');
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
                      }, success: 'Document ajouté'),
              icon: const Icon(Icons.upload_file),
              label: const Text('Ajouter')),
          const SizedBox(height: 6),
          const Text('JPG, PNG, PDF · 10 Mo',
              textAlign: TextAlign.center, style: InstallationStyle.caption),
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
                    ? installationErrorMessage(snapshot.error!)
                    : null,
                onRetry: () => setState(() => _events = _service.events(order)),
                onSend: _canContribute(order)
                    ? (message) => _service.comment(order, message)
                    : null));
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
              icon: const Icon(Icons.add_business, size: 36),
              title: const Text('Créer le site'),
              content: SizedBox(
                  width: 420,
                  child: Form(
                      key: key,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        TextFormField(
                            controller: code,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                                labelText: 'Code du site',
                                prefixIcon: Icon(Icons.qr_code)),
                            validator: (value) =>
                                value!.trim().isEmpty ? 'Code manquant' : null),
                        const SizedBox(height: 14),
                        TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined)),
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
                                labelText: 'Mot de passe',
                                helperText: '8 caractères min.',
                                prefixIcon: Icon(Icons.lock_outline)),
                            validator: (value) => (value?.length ?? 0) < 8
                                ? '8 caractères min.'
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
                    child: const Text('Créer'))
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
      }, success: 'Site créé');
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
          icon: Icon(Icons.undo,
              size: 36,
              color:
                  installationStatusColor(InstallationStatus.changesRequested)),
          title: const Text('À corriger'),
          content: SizedBox(
              width: 440,
              child: TextField(
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
                      labelText: 'Message',
                      errorText: _attempted ? 'Message manquant' : null))),
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
