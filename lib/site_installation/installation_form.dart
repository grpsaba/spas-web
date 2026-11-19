import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'installation_order.dart';
import 'installation_ui.dart';
import 'installation_catalog.dart';
import 'installation_equipment_picker.dart';

const installationFormSteps = [
  'Site et client',
  'Agents',
  'Équipements',
  'Organisation',
];

const _stepDescriptions = [
  'Identifiez le client et le lieu de la prestation.',
  'Indiquez les personnes qui figureront sur le bon.',
  'Choisissez les articles du catalogue et leurs quantités.',
  'Préparez les informations nécessaires à l’ouverture du site.',
];

/// Lets a page validate the whole request before its transmission.
class InstallationFormController {
  _InstallationFormState? _state;

  /// Checks every step. On failure, opens the first incomplete step, shows
  /// what is missing and moves to the first field to correct.
  bool validate() => _state?._validateAll() ?? true;

  /// Current step of the guided form.
  int get step => _state?._step ?? 0;
}

class _Field {
  _Field(this.step) : key = GlobalKey<FormFieldState>();
  final int step;
  final GlobalKey<FormFieldState> key;
  FocusNode? focus;
}

/// Same fields and wire schema in the web and mobile applications.
///
/// Fields are independent [FormField]s rather than children of a [Form]: a
/// keystroke only rebuilds its own field instead of every field of the request.
class InstallationForm extends StatefulWidget {
  const InstallationForm({
    super.key,
    required this.order,
    required this.enabled,
    required this.zones,
    required this.supervisors,
    required this.catalog,
    required this.departments,
    this.createEquipment,
    this.onChanged,
    this.guided = false,
    this.validationAttempt = 0,
    this.controller,
  });

  final InstallationOrder order;
  final bool enabled;
  final List<String> departments;
  final List<InstallationOption> zones;
  final List<InstallationOption> supervisors;
  final List<InstallationOption> catalog;
  final Future<InstallationOption> Function(String, String)? createEquipment;
  final VoidCallback? onChanged;
  final bool guided;

  /// Incremented by the page after a failed transmission: all errors are
  /// displayed and the first incomplete step is opened.
  final int validationAttempt;
  final InstallationFormController? controller;

  @override
  State<InstallationForm> createState() => _InstallationFormState();
}

class _InstallationFormState extends State<InstallationForm> {
  InstallationOrder get order => widget.order;
  final Set<String> _adding = {};
  final List<InstallationOption> _newCatalog = [];
  int _step = 0;
  final Set<String> _freeEntry = {};
  final Set<int> _attemptedSteps = {};
  final Map<String, _Field> _fields = {};
  final Map<String, TextEditingController> _quantities = {};
  final _date = TextEditingController();

  // Reference lists are filtered once, not for every row and every build.
  List<Object>? _catalogSource;
  List<InstallationOption> _catalog = const [];
  List<Object>? _supervisorSource;
  List<InstallationOption> _supervisorOptions = const [];

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
    _date.text = _formatDate(order.contractDate);
    if (widget.validationAttempt > 0) _openFirstIncomplete(reveal: false);
  }

  @override
  void didUpdateWidget(covariant InstallationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller?._state == this) {
        oldWidget.controller!._state = null;
      }
      widget.controller?._state = this;
    }
    if (widget.validationAttempt != oldWidget.validationAttempt &&
        widget.validationAttempt > 0) {
      _openFirstIncomplete();
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller!._state = null;
    for (final field in _fields.values) {
      field.focus?.dispose();
    }
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    _date.dispose();
    super.dispose();
  }

  bool get _allAttempted => widget.validationAttempt > 0;

  AutovalidateMode _mode(int step) =>
      _allAttempted || _attemptedSteps.contains(step)
          ? AutovalidateMode.always
          : AutovalidateMode.disabled;

  _Field _field(String id, int step, {bool focusable = false}) {
    final field = _fields.putIfAbsent(id, () => _Field(step));
    if (focusable) field.focus ??= FocusNode(debugLabel: id);
    return field;
  }

  void _forget(String prefix) {
    _fields.removeWhere((id, field) {
      if (!id.startsWith(prefix)) return false;
      field.focus?.dispose();
      return true;
    });
  }

  Iterable<FormFieldState> _states(int step) => _fields.values
      .where((f) => f.step == step)
      .map((f) => f.key.currentState)
      .whereType<FormFieldState>();

  bool _fieldsValid(int step) => _states(step).every((s) => s.isValid);

  bool _stepComplete(int step) =>
      order.validateStep(step).isEmpty && _fieldsValid(step);

  int? get _firstIncomplete {
    for (var step = 0; step < 4; step++) {
      if (!_stepComplete(step)) return step;
    }
    return null;
  }

  bool _validateAll() {
    var valid = true;
    for (var step = 0; step < 4; step++) {
      _attemptedSteps.add(step);
      for (final state in _states(step)) {
        if (!state.validate()) valid = false;
      }
    }
    final incomplete = _firstIncomplete;
    if (incomplete != null) {
      _openStep(incomplete);
      return false;
    }
    setState(() {});
    return valid;
  }

  void _openFirstIncomplete({bool reveal = true}) {
    final incomplete = _firstIncomplete;
    if (widget.guided) _step = incomplete ?? 3;
    if (reveal && incomplete != null) _revealFirstError(incomplete);
  }

  void _openStep(int step) {
    if (!mounted) return;
    setState(() {
      _attemptedSteps.add(step);
      if (widget.guided) _step = step;
    });
    _revealFirstError(step);
  }

  /// Scrolls to the first invalid field of [step] and focuses it.
  void _revealFirstError(int step) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _Field? first;
      double? firstTop;
      for (final field in _fields.values.where((f) => f.step == step)) {
        final state = field.key.currentState;
        if (state == null || state.isValid) continue;
        final box = state.context.findRenderObject();
        if (box is! RenderBox || !box.attached || !box.hasSize) continue;
        final top = box.localToGlobal(Offset.zero).dy;
        if (firstTop == null || top < firstTop) {
          first = field;
          firstTop = top;
        }
      }
      final target =
          first?.key.currentState?.context ?? _summaryKey.currentContext;
      if (target == null) return;
      Scrollable.ensureVisible(target,
          alignment: .15, duration: const Duration(milliseconds: 250));
      first?.focus?.requestFocus();
    });
  }

  final _summaryKey = GlobalKey();

  void _goToStep(int target) {
    if (target == _step) return;
    FocusScope.of(context).unfocus();
    if (target > _step) {
      for (var step = 0; step < target; step++) {
        if (!_stepComplete(step)) {
          _openStep(step);
          return;
        }
      }
    }
    setState(() => _step = target);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _stepHeaderKey.currentContext;
      if (mounted && context != null) {
        Scrollable.ensureVisible(context,
            duration: const Duration(milliseconds: 200));
      }
    });
  }

  final _stepHeaderKey = GlobalKey();

  void _change(VoidCallback action) {
    setState(action);
    widget.onChanged?.call();
  }

  void _typed(ValueChanged<String> changed, String value) {
    changed(value);
    widget.onChanged?.call();
  }

  List<InstallationOption> get _catalogOptions {
    final source = [widget.catalog, _newCatalog.length, order.departmentId];
    if (!_same(_catalogSource, source)) {
      _catalogSource = source;
      _catalog = installationCatalogOptions({
        for (final option in [...widget.catalog, ..._newCatalog])
          option.id: {...option.data, 'label': option.label}
      }, [
        order.departmentId
      ]);
    }
    return _catalog;
  }

  List<InstallationOption> get _supervisors {
    final source = [widget.supervisors, order.departmentId];
    if (!_same(_supervisorSource, source)) {
      _supervisorSource = source;
      _supervisorOptions = widget.supervisors.where((option) {
        final data = option.data;
        final dept =
            data['departmentId'] ?? installationMap(data['department'])['id'];
        return dept == order.departmentId &&
            data['actif'] != false &&
            data['isPortal'] != true;
      }).toList();
    }
    return _supervisorOptions;
  }

  static bool _same(List<Object>? a, List<Object> b) {
    if (a == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i]) && a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final sections = [
      _siteStep,
      _agentsStep,
      _equipmentStep,
      _organisationStep
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (widget.guided) ...[
        KeyedSubtree(key: _stepHeaderKey, child: _stepHeader()),
        const SizedBox(height: 14),
      ] else
        const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
                'Les champs marqués * sont obligatoires pour transmettre la demande. Le brouillon peut être enregistré à tout moment.',
                style: InstallationStyle.caption)),
      for (var i = 0; i < sections.length; i++)
        Visibility(
            visible: !widget.guided || _step == i,
            maintainState: true,
            child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: InstallationPanel(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!widget.guided) ...[
                            Text(
                                const [
                                  'Client et site',
                                  'Agents prévus',
                                  'Équipements',
                                  'Organisation du site'
                                ][i],
                                style: InstallationStyle.sectionTitle),
                            const SizedBox(height: 4),
                            Text(_stepDescriptions[i],
                                style: InstallationStyle.caption),
                            const SizedBox(height: 16),
                          ],
                          if (_attemptedSteps.contains(i) || _allAttempted)
                            _summary(i),
                          ...sections[i](),
                        ])))),
      if (widget.guided) _footer(),
    ]);
  }

  Widget _summary(int step) {
    final missing = order.validateStep(step);
    if (missing.isEmpty && _fieldsValid(step)) return const SizedBox.shrink();
    return Padding(
        key: step == _step ? _summaryKey : null,
        padding: const EdgeInsets.only(bottom: 16),
        child: InstallationNotice(
            tone: InstallationTone.error,
            title: 'À compléter avant de continuer',
            message: missing.isEmpty
                ? 'Corrigez les champs signalés en rouge.'
                : missing.length == 1
                    ? missing.single
                    : 'Il manque ${missing.length} informations :',
            lines: missing.length > 1 ? missing : const []));
  }

  Widget _stepHeader() {
    final complete = [for (var i = 0; i < 4; i++) _stepComplete(i)];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('ÉTAPE ${_step + 1} SUR 4', style: InstallationStyle.overline),
      const SizedBox(height: 4),
      Text(installationFormSteps[_step],
          style: InstallationStyle.pageTitle.copyWith(fontSize: 20)),
      const SizedBox(height: 2),
      Text(_stepDescriptions[_step], style: InstallationStyle.caption),
      const SizedBox(height: 14),
      Row(children: [
        for (var i = 0; i < 4; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(child: _stepButton(i, complete[i])),
        ]
      ]),
    ]);
  }

  Widget _stepButton(int index, bool complete) {
    final current = _step == index;
    final error = !complete &&
        (_attemptedSteps.contains(index) || _allAttempted) &&
        !current;
    final color = current
        ? InstallationStyle.primary
        : error
            ? InstallationStyle.danger
            : complete
                ? InstallationStyle.green
                : InstallationStyle.muted;
    return Semantics(
        button: true,
        selected: current,
        label:
            'Étape ${index + 1} : ${installationFormSteps[index]}${complete ? ', complète' : error ? ', à compléter' : ''}',
        child: InkWell(
            key: ValueKey('installation-step-$index'),
            borderRadius: BorderRadius.circular(8),
            onTap: widget.enabled ? () => _goToStep(index) : null,
            child: ExcludeSemantics(
                child: Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 6),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              height: 4,
                              decoration: BoxDecoration(
                                  color: current || complete || error
                                      ? color
                                      : InstallationStyle.line,
                                  borderRadius: BorderRadius.circular(2))),
                          const SizedBox(height: 7),
                          Row(children: [
                            Icon(
                                error
                                    ? Icons.error_outline
                                    : complete && !current
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                size: 13,
                                color: color),
                            const SizedBox(width: 4),
                            Expanded(
                                child: Text(installationFormSteps[index],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.2,
                                        fontWeight: current
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: current
                                            ? InstallationStyle.ink
                                            : InstallationStyle.muted))),
                          ]),
                        ])))));
  }

  Widget _footer() => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        if (_step > 0)
          Flexible(
              child: TextButton.icon(
                  onPressed: widget.enabled ? () => _goToStep(_step - 1) : null,
                  icon: const Icon(Icons.arrow_back, size: 17),
                  label: const Text('Précédent',
                      overflow: TextOverflow.ellipsis))),
        const SizedBox(width: 8),
        if (_step < 3)
          Expanded(
              child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                          backgroundColor: InstallationStyle.primarySoft,
                          foregroundColor: InstallationStyle.primary,
                          iconAlignment: IconAlignment.end),
                      onPressed:
                          widget.enabled ? () => _goToStep(_step + 1) : null,
                      icon: const Icon(Icons.arrow_forward, size: 17),
                      label: const Text('Continuer',
                          overflow: TextOverflow.ellipsis))))
        else
          const Expanded(
              child: Text('Dernière étape : vérifiez puis transmettez.',
                  textAlign: TextAlign.right,
                  style: InstallationStyle.caption)),
      ]));

  List<Widget> _siteStep() => [
        _grid([
          _text('siteName', 0, 'Nom du site', order.siteName,
              (value) => order.siteName = value,
              capitalization: TextCapitalization.words),
          _text('clientName', 0, 'Client', order.clientName,
              (value) => order.clientName = value,
              capitalization: TextCapitalization.words),
          _text('address', 0, 'Adresse', order.address,
              (value) => order.address = value,
              capitalization: TextCapitalization.sentences),
          _text('phone', 0, 'Téléphone du contact', order.phone,
              (value) => order.phone = value,
              keyboard: TextInputType.phone, action: TextInputAction.done),
        ]),
        const SizedBox(height: 14),
        _department(),
        const SizedBox(height: 14),
        Row(children: [
          const Icon(Icons.numbers, size: 16, color: InstallationStyle.muted),
          const SizedBox(width: 6),
          Expanded(
              child: Text(
                  order.bonNumber.isEmpty
                      ? 'Le numéro du bon sera attribué automatiquement lors de la validation par le responsable.'
                      : 'Bon n° ${order.bonNumber} · Ce numéro est définitif.',
                  style: InstallationStyle.caption)),
        ]),
      ];

  Widget _department() {
    final departments = widget.departments;
    if (departments.length == 1 && departments.single == order.departmentId) {
      return Row(children: [
        const Text('Prestation', style: InstallationStyle.caption),
        const SizedBox(width: 10),
        Chip(
            avatar: Icon(
                order.isSecurity
                    ? Icons.shield_outlined
                    : Icons.cleaning_services_outlined,
                size: 16,
                color: InstallationStyle.primary),
            label: Text(order.serviceLabel),
            side: BorderSide.none,
            backgroundColor: InstallationStyle.primarySoft,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, color: InstallationStyle.primary)),
      ]);
    }
    return FormField<String>(
        key: _field('department', 0).key,
        initialValue: departments.contains(order.departmentId)
            ? order.departmentId
            : null,
        autovalidateMode: _mode(0),
        validator: (value) => value == null || !departments.contains(value)
            ? 'Choisir une prestation.'
            : null,
        builder: (field) =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Prestation *', style: InstallationStyle.caption),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                  showSelectedIcon: false,
                  emptySelectionAllowed: true,
                  segments: [
                    for (final id in departments)
                      ButtonSegment(
                          value: id,
                          label:
                              Text(id == 'security' ? 'Sécurité' : 'Nettoyage'),
                          icon: Icon(
                              id == 'security'
                                  ? Icons.shield_outlined
                                  : Icons.cleaning_services_outlined,
                              size: 17)),
                  ],
                  selected: {if (field.value != null) field.value!},
                  onSelectionChanged: widget.enabled
                      ? (selection) {
                          if (selection.isEmpty) return;
                          final value = selection.single;
                          field.didChange(value);
                          _change(() {
                            order.departmentId = value;
                            order.supervisor = null;
                            order.supervisor2 = null;
                            // Keep descriptions and quantities, but require
                            // a catalog entry in the selected department.
                            for (final item in order.equipment) {
                              item.catalogId = null;
                            }
                          });
                        }
                      : null),
              if (field.hasError)
                Padding(
                    padding: const EdgeInsets.only(top: 6, left: 12),
                    child: Text(field.errorText!,
                        style: const TextStyle(
                            color: InstallationStyle.danger, fontSize: 12))),
            ]));
  }

  List<Widget> _agentsStep() => [
        if (order.agents.isEmpty)
          _empty(Icons.people_outline, 'Aucun agent pour le moment',
              'Ajoutez au moins un agent avec son type et son contact.'),
        for (var i = 0; i < order.agents.length; i++) _agentCard(i),
        if (widget.enabled)
          Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _addAgent,
                icon: const Icon(Icons.person_add_alt, size: 19),
                label: const Text('Ajouter un agent'),
              )),
      ];

  void _addAgent() {
    final agent = InstallationAgent();
    _change(() => order.agents.add(agent));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final field = _fields['agent:${agent.id}:name'];
      final context = field?.key.currentContext;
      if (!mounted || context == null) return;
      Scrollable.ensureVisible(context,
          alignment: .2, duration: const Duration(milliseconds: 200));
      field!.focus?.requestFocus();
    });
  }

  Widget _agentCard(int index) {
    final agent = order.agents[index];
    final prefix = 'agent:${agent.id}:';
    return Container(
        key: ValueKey(agent.id),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(14, 8, 6, 14),
        decoration: BoxDecoration(
            color: InstallationStyle.background,
            borderRadius: BorderRadius.circular(12)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text('Agent ${index + 1}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: InstallationStyle.ink)),
            const Spacer(),
            if (widget.enabled)
              IconButton(
                  tooltip: 'Supprimer cet agent',
                  onPressed: () => _removeAgent(index),
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: InstallationStyle.muted)),
          ]),
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _grid([
                _text('${prefix}name', 1, 'Nom et prénoms', agent.name,
                    (value) => agent.name = value,
                    capitalization: TextCapitalization.words),
                _text('${prefix}type', 1, 'Type d’agent', agent.type,
                    (value) => agent.type = value,
                    capitalization: TextCapitalization.sentences),
                _text('${prefix}phone', 1, 'Contact', agent.phone,
                    (value) => agent.phone = value,
                    keyboard: TextInputType.phone,
                    action: TextInputAction.done),
              ], minWidth: 200)),
        ]));
  }

  void _removeAgent(int index) {
    final agent = order.agents[index];
    _change(() => order.agents.removeAt(index));
    _forget('agent:${agent.id}:');
    _undo('Agent supprimé', () {
      _change(() =>
          order.agents.insert(index.clamp(0, order.agents.length), agent));
    });
  }

  void _undo(String message, VoidCallback restore) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
              label: 'Annuler',
              onPressed: () {
                if (mounted) restore();
              })));
  }

  List<Widget> _equipmentStep() => [
        if (widget.catalog.isEmpty)
          const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: InstallationNotice(
                  message:
                      'Catalogue indisponible pour cette prestation. Saisissez une désignation et une quantité.')),
        if (order.equipment.isEmpty)
          _empty(Icons.inventory_2_outlined, 'Aucun équipement pour le moment',
              'Ajoutez les articles du catalogue et leurs quantités.'),
        for (var i = 0; i < order.equipment.length; i++) _equipmentRow(i),
        if (widget.enabled)
          Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () =>
                    _change(() => order.equipment.add(InstallationEquipment())),
                icon: const Icon(Icons.add, size: 19),
                label: const Text('Ajouter un équipement'),
              )),
      ];

  TextEditingController _quantity(InstallationEquipment item) =>
      _quantities.putIfAbsent(
          item.id, () => TextEditingController(text: '${item.quantity}'));

  void _stepQuantity(InstallationEquipment item, int delta) {
    final next = (item.quantity + delta).clamp(1, 99999);
    if (next == item.quantity && item.quantity > 0) return;
    item.quantity = next;
    _quantity(item).text = '$next';
    widget.onChanged?.call();
  }

  Widget _equipmentRow(int index) {
    final item = order.equipment[index];
    final catalog = _catalogOptions;
    var options = catalog;
    if (item.catalogId != null &&
        !catalog.any((option) => option.id == item.catalogId)) {
      options = [
        ...catalog,
        InstallationOption(item.catalogId!, item.designation)
      ];
    }
    final prefix = 'equipment:${item.id}:';
    final free = item.needsCatalogEntry &&
        (_freeEntry.contains(item.id) || item.designation.isNotEmpty);
    final quantity = _quantity(item);
    final quantityField = TextFormField(
      key: _field('${prefix}quantity', 2, focusable: true).key,
      focusNode: _fields['${prefix}quantity']!.focus,
      controller: quantity,
      enabled: widget.enabled,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _decoration('Quantité').copyWith(
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: IconButton(
              tooltip: 'Diminuer la quantité',
              onPressed: widget.enabled ? () => _stepQuantity(item, -1) : null,
              icon: const Icon(Icons.remove, size: 18)),
          suffixIcon: IconButton(
              tooltip: 'Augmenter la quantité',
              onPressed: widget.enabled ? () => _stepQuantity(item, 1) : null,
              icon: const Icon(Icons.add, size: 18))),
      autovalidateMode: _mode(2),
      validator: _positive,
      onChanged: (value) =>
          _typed((value) => item.quantity = int.tryParse(value) ?? 0, value),
    );
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
          color: InstallationStyle.background,
          borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: LayoutBuilder(
                  builder: (context, c) => c.maxWidth >= 460
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Expanded(child: _picker(item, options, prefix)),
                              const SizedBox(width: 12),
                              SizedBox(width: 168, child: quantityField),
                            ])
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                              _picker(item, options, prefix),
                              const SizedBox(height: 12),
                              SizedBox(width: 168, child: quantityField),
                            ]))),
          if (widget.enabled)
            IconButton(
                tooltip: 'Supprimer cet équipement',
                onPressed: () => _removeEquipment(index),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: InstallationStyle.muted)),
        ]),
        if (free) ...[
          const SizedBox(height: 12),
          Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _text('${prefix}designation', 2, 'Désignation',
                  item.designation, (value) => item.designation = value,
                  capitalization: TextCapitalization.sentences,
                  action: TextInputAction.done)),
          const SizedBox(height: 8),
          const Padding(
              padding: EdgeInsets.only(right: 8),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline,
                    size: 16, color: InstallationStyle.warning),
                SizedBox(width: 6),
                Expanded(
                    child: Text(
                        'Équipement absent du catalogue : pensez à le créer pour les prochains bons.',
                        style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: InstallationStyle.warning))),
              ])),
          if (widget.enabled && widget.createEquipment != null)
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _adding.contains(item.id)
                      ? null
                      : () => _createEquipment(item),
                  icon: _adding.contains(item.id)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.playlist_add),
                  label: Text(_adding.contains(item.id)
                      ? 'Création…'
                      : 'Créer dans le catalogue'),
                )),
        ],
      ]),
    );
  }

  Widget _picker(InstallationEquipment item, List<InstallationOption> options,
          String prefix) =>
      InstallationEquipmentPicker(
        formFieldKey: _field(
                '${prefix}catalog:${item.catalogId}:${order.departmentId}', 2)
            .key,
        value: item.catalogId ??
            (_freeEntry.contains(item.id) || item.designation.isNotEmpty
                ? ''
                : null),
        enabled: widget.enabled,
        catalog: options,
        autovalidateMode: _mode(2),
        onChanged: widget.enabled
            ? (value) => _change(() {
                  _forget('${prefix}catalog:');
                  item.catalogId = value!.isEmpty ? null : value;
                  if (value.isEmpty) {
                    _freeEntry.add(item.id);
                  } else {
                    _freeEntry.remove(item.id);
                    item.designation = options
                        .firstWhere((option) => option.id == value)
                        .label;
                  }
                })
            : null,
      );

  void _removeEquipment(int index) {
    final item = order.equipment[index];
    _change(() => order.equipment.removeAt(index));
    _forget('equipment:${item.id}:');
    _quantities.remove(item.id)?.dispose();
    _undo('Équipement supprimé', () {
      _change(() =>
          order.equipment.insert(index.clamp(0, order.equipment.length), item));
    });
  }

  Future<void> _createEquipment(InstallationEquipment item) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (item.designation.trim().isEmpty) {
      messenger?.showSnackBar(
          const SnackBar(content: Text('Saisissez d’abord la désignation.')));
      return;
    }
    setState(() => _adding.add(item.id));
    try {
      final option = await widget.createEquipment!(
          item.designation.trim(), order.departmentId);
      if (!mounted) return;
      setState(() {
        _newCatalog.add(option);
        item.catalogId = option.id;
        item.designation = option.label;
      });
      widget.onChanged?.call();
      messenger?.showSnackBar(
          SnackBar(content: Text('« ${option.label} » ajouté au catalogue.')));
    } catch (error) {
      messenger?.showSnackBar(
          SnackBar(content: Text(installationReadableError(error))));
    } finally {
      if (mounted) setState(() => _adding.remove(item.id));
    }
  }

  List<Widget> _organisationStep() => [
        _grid([
          _choice(
              'zone',
              'Zone',
              widget.zones,
              order.zone?['codeZone'] as String?,
              order.zone?['name'] as String? ?? '',
              (value) => order.zone = value?.data),
          _choice(
              'supervisor:${order.departmentId}',
              'Superviseur 1',
              _supervisors,
              order.supervisor?['UID'] as String?,
              installationPersonName(order.supervisor),
              (value) => order.supervisor = value?.data),
          _choice(
              'supervisor2:${order.departmentId}',
              'Superviseur 2 (facultatif)',
              _supervisors,
              order.supervisor2?['UID'] as String?,
              installationPersonName(order.supervisor2),
              (value) => order.supervisor2 = value?.data,
              optional: true),
          TextFormField(
            key: _field('contractDate', 3).key,
            controller: _date,
            readOnly: true,
            enabled: widget.enabled,
            decoration: _decoration('Date du contrat').copyWith(
                suffixIcon:
                    const Icon(Icons.calendar_today_outlined, size: 18)),
            autovalidateMode: _mode(3),
            validator: (_) => order.contractDate == null
                ? 'Renseigner la date du contrat.'
                : null,
            onTap: widget.enabled ? _pickDate : null,
          ),
        ]),
        const SizedBox(height: 14),
        _grid([
          _text(
              'agentCount',
              3,
              'Effectif prévu',
              order.agentCount == 0 ? '' : '${order.agentCount}',
              (value) => order.agentCount = int.tryParse(value) ?? 0,
              keyboard: TextInputType.number,
              validator: _positive,
              digits: true),
          _text('roundCount', 3, 'Rondes prévues', '${order.roundCount}',
              (value) => order.roundCount = int.tryParse(value) ?? 0,
              keyboard: TextInputType.number,
              validator: _positive,
              digits: true,
              action: TextInputAction.done),
        ], minWidth: 120),
        const SizedBox(height: 16),
        const Text('Type de pointage *', style: InstallationStyle.caption),
        const SizedBox(height: 6),
        SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
                showSelectedIcon: false,
                emptySelectionAllowed: true,
                style: SegmentedButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 13),
                    padding: const EdgeInsets.symmetric(horizontal: 6)),
                segments: const [
                  ButtonSegment(value: 'jour', label: Text('Jour')),
                  ButtonSegment(value: 'nuit', label: Text('Nuit')),
                  ButtonSegment(
                      value: 'jour_nuit', label: Text('Jour et nuit')),
                ],
                selected: {
                  if (['jour', 'nuit', 'jour_nuit']
                      .contains(order.pointageType))
                    order.pointageType
                },
                onSelectionChanged: widget.enabled
                    ? (selection) {
                        if (selection.isEmpty) return;
                        _change(() => order.pointageType = selection.single);
                      }
                    : null)),
        const SizedBox(height: 18),
        const Text('Position GPS (facultatif)',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: InstallationStyle.ink)),
        const SizedBox(height: 4),
        const Text('Renseignez les deux coordonnées ou laissez-les vides.',
            style: InstallationStyle.caption),
        const SizedBox(height: 10),
        _grid([
          _text(
              'latitude',
              3,
              'Latitude',
              order.latitude?.toString() ?? '',
              (value) =>
                  order.latitude = double.tryParse(value.replaceAll(',', '.')),
              keyboard: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              validator: (value) => _coordinate(value, 90),
              required: false),
          _text(
              'longitude',
              3,
              'Longitude',
              order.longitude?.toString() ?? '',
              (value) =>
                  order.longitude = double.tryParse(value.replaceAll(',', '.')),
              keyboard: const TextInputType.numberWithOptions(
                  decimal: true, signed: true),
              validator: (value) => _coordinate(value, 180),
              required: false,
              action: TextInputAction.done),
        ], minWidth: 120),
      ];

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final date = await showDatePicker(
        context: context,
        helpText: 'Date du contrat',
        cancelText: 'Annuler',
        confirmText: 'Valider',
        initialDate: order.contractDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date != null && mounted) {
      _date.text = _formatDate(date);
      _change(() => order.contractDate = date);
      _fields['contractDate']?.key.currentState?.didChange(_date.text);
    }
  }

  static String? _positive(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Champ obligatoire.';
    return (int.tryParse(text) ?? 0) <= 0 ? 'Saisir un entier positif.' : null;
  }

  static String? _coordinate(String? value, double limit) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final coordinate = double.tryParse(text.replaceAll(',', '.'));
    return coordinate == null ||
            !coordinate.isFinite ||
            coordinate.abs() > limit
        ? 'Coordonnée invalide.'
        : null;
  }

  Widget _empty(IconData icon, String title, String subtitle) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
          border: Border.all(color: InstallationStyle.line),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: InstallationStyle.primary, size: 28),
        const SizedBox(height: 10),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: InstallationStyle.ink)),
        const SizedBox(height: 6),
        Text(subtitle,
            textAlign: TextAlign.center, style: InstallationStyle.caption),
      ]));

  Widget _choice(
      String id,
      String label,
      List<InstallationOption> options,
      String? value,
      String currentLabel,
      ValueChanged<InstallationOption?> changed,
      {bool optional = false}) {
    var choices = options;
    if (value != null && !choices.any((option) => option.id == value)) {
      choices = [...options, InstallationOption(value, currentLabel)];
    }
    return DropdownButtonFormField<String>(
      key: _field(id, 3).key,
      initialValue: value,
      isExpanded: true,
      decoration: _decoration(label),
      autovalidateMode: _mode(3),
      validator: (value) => !optional && (value == null || value.isEmpty)
          ? 'Choisir une valeur.'
          : null,
      items: [
        if (optional) const DropdownMenuItem(value: '', child: Text('Aucun')),
        ...choices.map((option) => DropdownMenuItem(
            value: option.id,
            child: Text(option.label, overflow: TextOverflow.ellipsis))),
      ],
      onChanged: widget.enabled
          ? (value) => _change(() => changed(value == ''
              ? null
              : choices.firstWhere((option) => option.id == value)))
          : null,
    );
  }

  Widget _text(String id, int step, String label, String value,
      ValueChanged<String> changed,
      {TextInputType? keyboard,
      TextInputAction action = TextInputAction.next,
      TextCapitalization capitalization = TextCapitalization.none,
      FormFieldValidator<String>? validator,
      bool required = true,
      bool digits = false}) {
    final field = _field(id, step, focusable: true);
    return TextFormField(
      key: field.key,
      focusNode: field.focus,
      initialValue: value,
      enabled: widget.enabled,
      keyboardType: keyboard,
      textInputAction: action,
      textCapitalization: capitalization,
      inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: _decoration(label, required: required),
      autovalidateMode: _mode(step),
      validator: validator ??
          (value) => (value ?? '').trim().isEmpty ? 'Champ obligatoire.' : null,
      onChanged: (value) => _typed(changed, value),
    );
  }

  Widget _grid(List<Widget> children, {double minWidth = 240}) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns =
            ((constraints.maxWidth + 14) / (minWidth + 14)).floor().clamp(1, 3);
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: children
                .map((child) => SizedBox(width: width, child: child))
                .toList());
      });

  InputDecoration _decoration(String label, {bool required = true}) =>
      InputDecoration(
          labelText:
              required && !label.contains('facultatif') ? '$label *' : label,
          helperText:
              required || label.contains('facultatif') ? null : 'Facultatif');

  static String _formatDate(DateTime? value) => value == null
      ? ''
      : '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
