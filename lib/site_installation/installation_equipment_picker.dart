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
                      labelText: 'Équipement *',
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

/// Searchable catalogue. Accent-insensitive; returns the selected identifier,
/// or `''` for a free designation.
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
          padding: const EdgeInsets.fromLTRB(20, 14, 8, 0),
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
                icon: const Icon(Icons.close, size: 22))
          ])),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
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
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
          child: Text(
              _query.isEmpty
                  ? '${widget.catalog.length} équipement${widget.catalog.length > 1 ? 's' : ''} dans le catalogue'
                  : '${matches.length} résultat${matches.length > 1 ? 's' : ''}',
              style: InstallationStyle.caption)),
      Expanded(
          child: matches.isEmpty
              ? ListView(padding: const EdgeInsets.all(20), children: const [
                  Icon(Icons.search_off_outlined,
                      size: 30, color: InstallationStyle.muted),
                  SizedBox(height: 10),
                  Text(
                      'Aucun équipement trouvé.\nVous pouvez saisir une désignation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: InstallationStyle.muted, height: 1.6)),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: matches.length,
                  itemExtent: 56,
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
                        leading: const Icon(Icons.inventory_2_outlined,
                            size: 20, color: InstallationStyle.primary),
                        title: Text(item.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        trailing: selected
                            ? const Icon(Icons.check_circle,
                                color: InstallationStyle.primary, size: 21)
                            : null,
                        onTap: () => Navigator.pop(context, item.id));
                  })),
      const Divider(height: 1),
      SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Équipement absent du catalogue ?',
                        style: InstallationStyle.caption),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context, ''),
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Saisir une désignation',
                            overflow: TextOverflow.ellipsis)),
                  ]))),
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
