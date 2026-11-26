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
      this.formFieldKey,
      this.autovalidateMode = AutovalidateMode.disabled});

  /// Catalogue identifier, `''` for a free designation, `null` when empty.
  final String? value;
  final bool enabled;
  final List<InstallationOption> catalog;
  final ValueChanged<String?>? onChanged;
  final GlobalKey<FormFieldState>? formFieldKey;
  final AutovalidateMode autovalidateMode;

  @override
  Widget build(BuildContext context) => FormField<String>(
      key: formFieldKey,
      initialValue: value,
      enabled: enabled,
      autovalidateMode: autovalidateMode,
      validator: (selected) => selected == null ? 'Équipement manquant' : null,
      builder: (field) {
        final matches = catalog.where((option) => option.id == value);
        final label = value == ''
            ? 'Autre équipement'
            : matches.isEmpty
                ? 'Choisir'
                : matches.first.label;
        return Semantics(
            button: true,
            enabled: enabled,
            label: 'Équipement',
            value: label,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: !enabled
                  ? null
                  : () async {
                      FocusScope.of(context).unfocus();
                      final compact = MediaQuery.sizeOf(context).width <
                          InstallationStyle.compactWidth;
                      final selected = await showDialog<String>(
                          context: context,
                          builder: (dialogContext) => Theme(
                              data: Theme.of(context),
                              child: InstallationEquipmentDialog(
                                  catalog: catalog,
                                  selected: value,
                                  fullScreen: compact)));
                      if (selected != null && field.mounted) {
                        field.didChange(selected);
                        onChanged?.call(selected);
                      }
                    },
              child: InputDecorator(
                  isEmpty: false,
                  decoration: InputDecoration(
                      labelText: 'Équipement',
                      enabled: enabled,
                      errorText: field.errorText,
                      prefixIcon:
                          const Icon(Icons.inventory_2_outlined, size: 22),
                      suffixIcon: const Icon(Icons.arrow_drop_down, size: 26)),
                  child: Text(label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: value == null
                              ? InstallationStyle.muted
                              : InstallationStyle.ink))),
            ));
      });
}

/// Searchable catalogue. Accent-insensitive; returns the selected identifier,
/// or `''` for another (free) designation.
class InstallationEquipmentDialog extends StatefulWidget {
  const InstallationEquipmentDialog(
      {super.key,
      required this.catalog,
      this.selected,
      this.fullScreen = false});
  final List<InstallationOption> catalog;
  final String? selected;
  final bool fullScreen;
  @override
  State<InstallationEquipmentDialog> createState() =>
      _InstallationEquipmentDialogState();
}

class _InstallationEquipmentDialogState
    extends State<InstallationEquipmentDialog> {
  final _search = TextEditingController();
  String _query = '';
  late final List<String> _keys = widget.catalog
      .map((option) => installationNormalize(option.label))
      .toList();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<InstallationOption> get _matches {
    final query = installationNormalize(_query);
    if (query.isEmpty) return widget.catalog;
    return [
      for (var i = 0; i < widget.catalog.length; i++)
        if (_keys[i].contains(query)) widget.catalog[i]
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final content =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
          child: Row(children: [
            const Icon(Icons.inventory_2_outlined,
                size: 24, color: InstallationStyle.primary),
            const SizedBox(width: 10),
            const Expanded(
                child: Text('Équipements',
                    style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: InstallationStyle.ink))),
            IconButton(
                tooltip: 'Fermer',
                iconSize: 26,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close))
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: (query) => setState(() => _query = query),
              decoration: InputDecoration(
                  hintText: 'Rechercher',
                  prefixIcon: const Icon(Icons.search, size: 22),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Effacer la recherche',
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          })))),
      Expanded(
          child: matches.isEmpty
              ? ListView(padding: const EdgeInsets.all(20), children: const [
                  Icon(Icons.search_off,
                      size: 34, color: InstallationStyle.muted),
                  SizedBox(height: 8),
                  Text('Aucun résultat',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: InstallationStyle.muted)),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: matches.length,
                  itemExtent: 58,
                  itemBuilder: (context, index) {
                    final item = matches[index];
                    final selected = item.id == widget.selected;
                    return ListTile(
                        selected: selected,
                        selectedTileColor: InstallationStyle.primarySoft,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        leading: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.inventory_2_outlined,
                            size: 24,
                            color: InstallationStyle.primary),
                        title: Text(item.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                        onTap: () => Navigator.pop(context, item.id));
                  })),
      const Divider(height: 1),
      SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52)),
                  onPressed: () => Navigator.pop(context, ''),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: const Text('Autre équipement',
                      overflow: TextOverflow.ellipsis)))),
    ]);
    if (widget.fullScreen) {
      return Dialog.fullscreen(
          backgroundColor: Colors.white, child: SafeArea(child: content));
    }
    final availableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        48;
    return Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SizedBox(
            width: 560,
            height: availableHeight.clamp(240.0, 620.0),
            child: content));
  }
}
