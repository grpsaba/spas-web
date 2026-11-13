import 'package:flutter/material.dart';

import 'installation_order.dart';
import 'installation_ui.dart';
import 'installation_catalog.dart';

/// Same fields and wire schema in the web and mobile applications.
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
    this.validationKey,
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
  final int validationAttempt;
  final GlobalKey<FormState>? validationKey;

  @override
  State<InstallationForm> createState() => _InstallationFormState();
}

class _InstallationFormState extends State<InstallationForm> {
  InstallationOrder get order => widget.order;
  final Set<String> _adding = {};
  final List<InstallationOption> _newCatalog = [];
  int _step = 0;
  final Set<String> _freeEntry = {};
  final _formKey = GlobalKey<FormState>();

  @override
  void didUpdateWidget(covariant InstallationForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.validationAttempt != oldWidget.validationAttempt &&
        widget.guided) {
      if ([order.siteName, order.clientName, order.address, order.phone]
          .any((v) => v.trim().isEmpty)) {
        _step = 0;
      } else if (order.agents.isEmpty ||
          order.agents.any(
              (a) => [a.name, a.type, a.phone].any((v) => v.trim().isEmpty))) {
        _step = 1;
      } else if (order.equipment.isEmpty ||
          order.equipment
              .any((e) => e.designation.trim().isEmpty || e.quantity <= 0)) {
        _step = 2;
      } else {
        _step = 3;
      }
    }
  }

  void _change(VoidCallback action) {
    setState(action);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _section('Client et site', [
        _grid([
          _text(
              'Nom du site', order.siteName, (value) => order.siteName = value),
          _text(
              'Client', order.clientName, (value) => order.clientName = value),
          _text('Adresse', order.address, (value) => order.address = value),
          _text('Téléphone du contact', order.phone,
              (value) => order.phone = value,
              keyboard: TextInputType.phone),
          DropdownButtonFormField<String>(
            initialValue: widget.departments.contains(order.departmentId)
                ? order.departmentId
                : null,
            decoration: _decoration('Prestation'),
            validator: (value) =>
                value == null ? 'Choisir une prestation.' : null,
            items: widget.departments
                .map((id) => DropdownMenuItem(
                      value: id,
                      child: Text(id == 'security' ? 'Sécurité' : 'Nettoyage'),
                    ))
                .toList(),
            onChanged: widget.enabled
                ? (value) => _change(() {
                      order.departmentId = value!;
                      order.supervisor = null;
                      order.supervisor2 = null;
                      // Keep descriptions and quantities, but require a catalog entry
                      // in the newly selected department.
                      for (final item in order.equipment) {
                        item.catalogId = null;
                      }
                    })
                : null,
          ),
        ]),
        const SizedBox(height: 12),
        InstallationNotice(
            icon: Icons.numbers,
            message: order.bonNumber.isEmpty
                ? 'Le numéro du bon sera attribué automatiquement lors de la validation par le responsable.'
                : 'Bon n° ${order.bonNumber} · Ce numéro est définitif.'),
      ]),
      _section('Agents prévus', [
        const InstallationNotice(
            message:
                'Au moins un agent est obligatoire. Renseignez son nom, son type et son contact.'),
        if (widget.validationAttempt > 0 && order.agents.isEmpty)
          const InstallationNotice(
              warning: true,
              message: 'Ajouter au moins un agent avant de transmettre.'),
        if (order.agents.isEmpty)
          _empty(Icons.people_outline, 'Qui interviendra sur ce site ?',
              'Ajoutez au moins un agent avec son type et son contact.'),
        for (final agent in order.agents)
          Padding(
            key: ValueKey(agent.id),
            padding: const EdgeInsets.only(top: 12),
            child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: InstallationStyle.background,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Text(
                            'AGENT ${(order.agents.indexOf(agent) + 1).toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w700,
                                color: InstallationStyle.muted)),
                        const Spacer(),
                        if (widget.enabled)
                          IconButton(
                              tooltip: 'Supprimer cet agent',
                              onPressed: () =>
                                  _change(() => order.agents.remove(agent)),
                              icon: const Icon(Icons.delete_outline, size: 18)),
                      ]),
                      const SizedBox(height: 10),
                      _grid([
                        _text('Nom et prénoms', agent.name,
                            (value) => agent.name = value),
                        _text('Type d’agent', agent.type,
                            (value) => agent.type = value),
                        _text('Contact', agent.phone,
                            (value) => agent.phone = value,
                            keyboard: TextInputType.phone),
                      ]),
                    ])),
          ),
        if (widget.enabled)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    _change(() => order.agents.add(InstallationAgent())),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Ajouter un agent'),
              )),
      ]),
      _section('Équipements', [
        if (widget.catalog.isEmpty)
          const InstallationNotice(
              message:
                  'Aucun équipement du catalogue disponible pour cette prestation. Vous pouvez saisir une désignation et une quantité.'),
        if (widget.validationAttempt > 0 && order.equipment.isEmpty)
          const InstallationNotice(
              warning: true,
              message: 'Ajouter au moins un équipement avant de transmettre.'),
        for (final item in order.equipment) _equipmentRow(item),
        if (order.equipment.isEmpty)
          _empty(Icons.inventory_2_outlined, 'Préparez les équipements',
              'Sélectionnez les articles du catalogue et ajustez leurs quantités.'),
        if (widget.enabled)
          Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    _change(() => order.equipment.add(InstallationEquipment())),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un équipement'),
              )),
      ]),
      _section('Préparation du site', [
        const InstallationNotice(
            message:
                'Ces informations sont obligatoires dès la transmission. Le deuxième superviseur et les coordonnées GPS sont facultatifs.'),
        const SizedBox(height: 22),
        _grid([
          _choice(
              'Zone',
              widget.zones,
              order.zone?['codeZone'] as String?,
              order.zone?['name'] as String? ?? '',
              (value) => order.zone = value?.data),
          _choice(
              'Superviseur 1',
              _supervisors,
              order.supervisor?['UID'] as String?,
              _supervisorName(order.supervisor),
              (value) => order.supervisor = value?.data),
          _choice(
              'Superviseur 2 (facultatif)',
              _supervisors,
              order.supervisor2?['UID'] as String?,
              _supervisorName(order.supervisor2),
              (value) => order.supervisor2 = value?.data,
              optional: true),
          _text(
              'Effectif prévu',
              order.agentCount == 0 ? '' : '${order.agentCount}',
              (value) => order.agentCount = int.tryParse(value) ?? 0,
              keyboard: TextInputType.number),
          _text('Rondes prévues', '${order.roundCount}',
              (value) => order.roundCount = int.tryParse(value) ?? 0,
              keyboard: TextInputType.number),
          TextFormField(
            key: ValueKey('date_${order.id}_${order.contractDate}'),
            readOnly: true,
            initialValue:
                order.contractDate == null ? '' : _date(order.contractDate!),
            decoration: _decoration('Date du contrat'),
            validator: (_) => order.contractDate == null
                ? 'Renseigner la date du contrat.'
                : null,
            onTap: widget.enabled
                ? () async {
                    final date = await showDatePicker(
                        context: context,
                        initialDate: order.contractDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (date != null && mounted) {
                      _change(() => order.contractDate = date);
                    }
                  }
                : null,
          ),
          _text(
              'Latitude',
              order.latitude?.toString() ?? '',
              (value) =>
                  order.latitude = double.tryParse(value.replaceAll(',', '.')),
              keyboard: const TextInputType.numberWithOptions(
                  decimal: true, signed: true)),
          _text(
              'Longitude',
              order.longitude?.toString() ?? '',
              (value) =>
                  order.longitude = double.tryParse(value.replaceAll(',', '.')),
              keyboard: const TextInputType.numberWithOptions(
                  decimal: true, signed: true)),
          DropdownButtonFormField<String>(
            initialValue:
                ['jour', 'nuit', 'jour_nuit'].contains(order.pointageType)
                    ? order.pointageType
                    : 'jour',
            decoration: _decoration('Pointage'),
            items: const [
              DropdownMenuItem(value: 'jour', child: Text('Jour')),
              DropdownMenuItem(value: 'nuit', child: Text('Nuit')),
              DropdownMenuItem(value: 'jour_nuit', child: Text('Jour et nuit')),
            ],
            onChanged: widget.enabled
                ? (value) => _change(() => order.pointageType = value!)
                : null,
          ),
        ]),
      ]),
    ];
    return Form(
        key: widget.validationKey ?? _formKey,
        autovalidateMode: widget.validationAttempt > 0
            ? AutovalidateMode.always
            : AutovalidateMode.disabled,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                  'Les champs marqués * sont obligatoires pour transmettre la demande. Le brouillon peut être enregistré à tout moment.',
                  style:
                      TextStyle(fontSize: 12, color: InstallationStyle.muted))),
          if (widget.guided) ...[
            LayoutBuilder(
                builder: (context, c) => c.maxWidth < 560
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            Row(children: [
                              Text('ÉTAPE ${_step + 1} SUR 4',
                                  style: const TextStyle(
                                      color: InstallationStyle.primary,
                                      fontSize: 10,
                                      letterSpacing: 1.3,
                                      fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text('${((_step + 1) / 4 * 100).round()} %',
                                  style: const TextStyle(
                                      color: InstallationStyle.muted,
                                      fontSize: 11))
                            ]),
                            const SizedBox(height: 10),
                            ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                    value: (_step + 1) / 4,
                                    minHeight: 4,
                                    color: InstallationStyle.primary,
                                    backgroundColor: InstallationStyle.line)),
                            const SizedBox(height: 14),
                            SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                    children: List.generate(4, _stepButton))),
                          ])
                    : Row(
                        children: List.generate(
                            4, (i) => Expanded(child: _stepButton(i))))),
            const SizedBox(height: 18),
          ],
          for (var i = 0; i < sections.length; i++)
            Visibility(
                visible: !widget.guided || _step == i,
                maintainState: true,
                child: sections[i]),
          if (widget.guided)
            Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(children: [
                  if (_step > 0)
                    TextButton.icon(
                        onPressed: () => setState(() => _step--),
                        icon: const Icon(Icons.arrow_back, size: 17),
                        label: const Text('Précédent')),
                  const Spacer(),
                  if (_step < 3)
                    OutlinedButton.icon(
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() => _step++);
                        },
                        icon: const Icon(Icons.arrow_forward, size: 17),
                        label: const Text('Continuer')),
                  if (_step == 3)
                    const Flexible(
                        child: Text(
                            'Vous pouvez transmettre la demande au bureau.',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                fontSize: 12, color: InstallationStyle.muted))),
                ])),
        ]));
  }

  Widget _stepButton(int index) => Padding(
      padding: const EdgeInsets.only(right: 8),
      child: TextButton(
        style: TextButton.styleFrom(
            backgroundColor:
                _step == index ? const Color(0xFFEEECFC) : Colors.transparent,
            foregroundColor: _step == index
                ? InstallationStyle.primary
                : InstallationStyle.muted,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        onPressed: () {
          FocusScope.of(context).unfocus();
          setState(() => _step = index);
        },
        child: Text(
            '${index + 1}. ${const [
              'Site & client',
              'Agents',
              'Équipements',
              'Organisation'
            ][index]}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ));

  Widget _empty(IconData icon, String title, String subtitle) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Column(children: [
        Icon(icon, color: InstallationStyle.primary, size: 30),
        const SizedBox(height: 12),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: InstallationStyle.ink)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, height: 1.5, color: InstallationStyle.muted)),
      ]));

  List<InstallationOption> get _supervisors =>
      widget.supervisors.where((option) {
        final data = option.data;
        final dept =
            data['departmentId'] ?? installationMap(data['department'])['id'];
        return dept == order.departmentId &&
            data['actif'] != false &&
            data['isPortal'] != true;
      }).toList();

  Widget _equipmentRow(InstallationEquipment item) {
    final catalog = installationCatalogOptions({
      for (final option in [...widget.catalog, ..._newCatalog])
        option.id: {...option.data, 'label': option.label}
    }, [
      order.departmentId
    ]);
    if (item.catalogId != null &&
        !catalog.any((option) => option.id == item.catalogId)) {
      catalog.add(InstallationOption(item.catalogId!, item.designation));
    }
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: InstallationStyle.background,
          borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: _grid([
            DropdownButtonFormField<String>(
              key: ValueKey(
                  'catalog_${item.id}_${item.catalogId}_${order.departmentId}'),
              initialValue: item.catalogId ??
                  (_freeEntry.contains(item.id) || item.designation.isNotEmpty
                      ? ''
                      : null),
              isExpanded: true,
              decoration: _decoration('Équipement du catalogue'),
              validator: (value) => value == null
                  ? 'Choisir un équipement ou la saisie libre.'
                  : null,
              items: [
                const DropdownMenuItem(
                    value: '', child: Text('Autre équipement (saisie libre)')),
                ...catalog.map((option) => DropdownMenuItem(
                    value: option.id,
                    child:
                        Text(option.label, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: widget.enabled
                  ? (value) => _change(() {
                        item.catalogId = value!.isEmpty ? null : value;
                        if (value.isEmpty) {
                          _freeEntry.add(item.id);
                        } else {
                          _freeEntry.remove(item.id);
                        }
                        if (value.isNotEmpty) {
                          item.designation = catalog
                              .firstWhere((option) => option.id == value)
                              .label;
                        }
                      })
                  : null,
            ),
            _text('Quantité', '${item.quantity}',
                (value) => item.quantity = int.tryParse(value) ?? 0,
                keyboard: TextInputType.number),
          ])),
          if (widget.enabled)
            IconButton(
                tooltip: 'Supprimer cet équipement',
                onPressed: () => _change(() => order.equipment.remove(item)),
                icon: const Icon(Icons.close)),
        ]),
        if (item.needsCatalogEntry &&
            (_freeEntry.contains(item.id) || item.designation.isNotEmpty)) ...[
          const SizedBox(height: 12),
          _text('Désignation', item.designation,
              (value) => item.designation = value),
          const SizedBox(height: 6),
          const Text(
              'Équipement absent du catalogue : pensez à le créer pour les prochains bons.',
              style: TextStyle(color: Color(0xff8A5600))),
          if (widget.enabled && widget.createEquipment != null)
            Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _adding.contains(item.id)
                      ? null
                      : () => _createEquipment(item),
                  icon: const Icon(Icons.playlist_add),
                  label: Text(_adding.contains(item.id)
                      ? 'Création…'
                      : 'Créer dans le catalogue'),
                )),
        ],
      ]),
    );
  }

  Future<void> _createEquipment(InstallationEquipment item) async {
    if (item.designation.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saisir la désignation.')));
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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _adding.remove(item.id));
    }
  }

  Widget _choice(String label, List<InstallationOption> options, String? id,
      String currentLabel, ValueChanged<InstallationOption?> changed,
      {bool optional = false}) {
    final choices = [...options];
    if (id != null && !choices.any((option) => option.id == id)) {
      choices.add(InstallationOption(id, currentLabel));
    }
    return DropdownButtonFormField<String>(
      key: ValueKey('$label:$id:${order.departmentId}'),
      initialValue: id,
      isExpanded: true,
      decoration: _decoration(label),
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

  Widget _text(String label, String value, ValueChanged<String> changed,
          {TextInputType? keyboard, bool? enabled}) =>
      TextFormField(
        initialValue: value,
        enabled: enabled ?? widget.enabled,
        keyboardType: keyboard,
        decoration: _decoration(label),
        validator: (value) {
          final text = (value ?? '').trim();
          if (label == 'Latitude' || label == 'Longitude') {
            if (text.isEmpty) return null;
            final coordinate = double.tryParse(text.replaceAll(',', '.'));
            return coordinate == null ||
                    !coordinate.isFinite ||
                    coordinate.abs() > (label == 'Latitude' ? 90 : 180)
                ? 'Coordonnée invalide.'
                : null;
          }
          if (text.isEmpty) return 'Champ obligatoire.';
          if (['Effectif prévu', 'Rondes prévues', 'Quantité']
                  .contains(label) &&
              (int.tryParse(text) ?? 0) <= 0) {
            return 'Saisir un entier positif.';
          }
          return null;
        },
        onChanged: (value) {
          changed(value);
          widget.onChanged?.call();
        },
      );

  Widget _grid(List<Widget> children) =>
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 540 ? 2 : 1;
        final width = (constraints.maxWidth - (columns - 1) * 14) / columns;
        return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: children
                .map((child) => SizedBox(width: width, child: child))
                .toList());
      });

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InstallationPanel(
            padding: const EdgeInsets.all(22),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      title == 'Préparation du site'
                          ? 'Organisation du site'
                          : title,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: InstallationStyle.ink)),
                  const SizedBox(height: 7),
                  Text(
                      const {
                        'Client et site':
                            'Identifiez le client et le lieu de la prestation.',
                        'Agents prévus':
                            'Indiquez les personnes qui figureront sur le bon.',
                        'Équipements':
                            'Le catalogue est privilégié. Une saisie libre reste possible.',
                        'Préparation du site':
                            'Préparez les informations nécessaires à l’ouverture du site.',
                      }[title]!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: InstallationStyle.muted,
                          height: 1.5)),
                  const SizedBox(height: 24),
                  ...children,
                ])),
      );

  InputDecoration _decoration(String label) => InputDecoration(
      labelText: label,
      suffixText: ['Latitude', 'Longitude', 'Superviseur 2 (facultatif)']
              .contains(label)
          ? null
          : '*',
      helperText:
          ['Latitude', 'Longitude'].contains(label) ? 'Facultatif' : null,
      hintText: label == 'Équipement du catalogue'
          ? 'Sélectionner un équipement'
          : null);
  String _supervisorName(Map<String, dynamic>? data) =>
      '${data?['firstName'] ?? ''} ${data?['lastName'] ?? ''}'.trim();
  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}
