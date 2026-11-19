import 'package:flutter/material.dart';

import 'installation_order.dart';
import 'installation_ui.dart';

class InstallationEquipmentPicker extends StatelessWidget {
  const InstallationEquipmentPicker(
      {super.key,
      required this.value,
      required this.enabled,
      required this.catalog,
      required this.onChanged,
      this.autovalidateMode = AutovalidateMode.disabled});
  final String? value;
  final bool enabled;
  final List<InstallationOption> catalog;
  final ValueChanged<String?>? onChanged;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) => FormField<String>(
      initialValue: value,
      enabled: enabled,
      autovalidateMode: autovalidateMode,
      validator: (selected) =>
          selected == null ? 'Choisir un équipement ou la saisie libre.' : null,
      builder: (field) {
        final matches = catalog.where((option) => option.id == value);
        final label = value == ''
            ? 'Saisie libre'
            : matches.isEmpty
                ? 'Choisir dans le catalogue'
                : matches.first.label;
        return Semantics(
            button: true,
            enabled: enabled,
            label: 'Équipement du catalogue',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: !enabled
                  ? null
                  : () async {
                      FocusScope.of(context).unfocus();
                      final selected = await showDialog<String>(
                          context: context,
                          builder: (dialogContext) => Theme(
                              data: Theme.of(context),
                              child: _EquipmentDialog(
                                  catalog: catalog, selected: value)));
                      if (selected != null && field.mounted) {
                        field.didChange(selected);
                        onChanged?.call(selected);
                      }
                    },
              child: InputDecorator(
                  isEmpty: false,
                  decoration: InputDecoration(
                      labelText: 'Équipement du catalogue *',
                      enabled: enabled,
                      errorText: field.errorText,
                      prefixIcon:
                          const Icon(Icons.inventory_2_outlined, size: 19),
                      suffixIcon: const Icon(Icons.unfold_more, size: 20)),
                  child: Text(label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 14,
                          color: value == null
                              ? InstallationStyle.muted
                              : InstallationStyle.ink))),
            ));
      });
}

class _EquipmentDialog extends StatefulWidget {
  const _EquipmentDialog({required this.catalog, this.selected});
  final List<InstallationOption> catalog;
  final String? selected;
  @override
  State<_EquipmentDialog> createState() => _EquipmentDialogState();
}

class _EquipmentDialogState extends State<_EquipmentDialog> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String text) => text
      .trim()
      .toLowerCase()
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final matches = widget.catalog
        .where(
            (option) => _normalize(option.label).contains(_normalize(_query)))
        .toList();
    final availableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        48;
    return Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
            width: 560,
            height: availableHeight.clamp(200.0, 600.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(children: [
                        const Expanded(
                            child: Text('Choisir un équipement',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: InstallationStyle.ink))),
                        IconButton(
                            tooltip: 'Fermer',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 20))
                      ])),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                          '${widget.catalog.length} équipements dans le catalogue',
                          style: const TextStyle(
                              fontSize: 12, color: InstallationStyle.muted))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: TextField(
                          controller: _search,
                          onChanged: (query) => setState(() => _query = query),
                          decoration: InputDecoration(
                              hintText: 'Rechercher un équipement…',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Effacer la recherche',
                                      icon: const Icon(Icons.close, size: 18),
                                      onPressed: () {
                                        _search.clear();
                                        setState(() => _query = '');
                                      })))),
                  Expanded(
                      child: matches.isEmpty
                          ? const Center(
                              child: Padding(
                                  padding: EdgeInsets.all(20),
                                  child: Text(
                                      'Aucun équipement trouvé.\nVous pouvez utiliser la saisie libre.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          color: InstallationStyle.muted,
                                          height: 1.6))))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              itemCount: matches.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final item = matches[index];
                                final selected = item.id == widget.selected;
                                return ListTile(
                                    selected: selected,
                                    selectedTileColor: const Color(0xFFEEECFC),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    leading: Container(
                                        padding: const EdgeInsets.all(9),
                                        decoration: BoxDecoration(
                                            color: InstallationStyle.background,
                                            borderRadius:
                                                BorderRadius.circular(9)),
                                        child: const Icon(
                                            Icons.inventory_2_outlined,
                                            size: 19,
                                            color: InstallationStyle.primary)),
                                    title: Text(item.label,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                    trailing: selected
                                        ? const Icon(Icons.check_circle,
                                            color: InstallationStyle.primary,
                                            size: 21)
                                        : null,
                                    onTap: () =>
                                        Navigator.pop(context, item.id));
                              })),
                  const Divider(height: 1),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Équipement absent du catalogue ?',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: InstallationStyle.muted)),
                            const SizedBox(height: 6),
                            OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context, ''),
                                icon: const Icon(Icons.edit_outlined, size: 17),
                                label: const Text('Saisir une désignation'))
                          ])),
                ])));
  }
}
