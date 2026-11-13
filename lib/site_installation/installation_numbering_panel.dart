import 'package:flutter/material.dart';

import 'installation_numbering.dart';
import 'installation_ui.dart';

class InstallationNumberingPanel extends StatelessWidget {
  const InstallationNumberingPanel({
    super.key,
    required this.stream,
    required this.canInitialize,
    required this.onInitialize,
  });

  final Stream<InstallationNumbering?> stream;
  final bool canInitialize;
  final Future<void> Function(String) onInitialize;

  @override
  Widget build(BuildContext context) => StreamBuilder<InstallationNumbering?>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return InstallationNotice(
              warning: true,
              message:
                  'Impossible de lire le compteur des bons. ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InstallationNotice(
              message: 'Chargement de la numérotation…');
        }
        final numbering = snapshot.data;
        return Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 10,
            children: [
              Text(
                  numbering == null
                      ? 'Numérotation à initialiser avant la première validation.'
                      : 'Numérotation commune · Dernier numéro utilisé : ${numbering.lastNumber}',
                  style: const TextStyle(
                      fontSize: 13, color: InstallationStyle.muted)),
              if (numbering == null && canInitialize)
                OutlinedButton.icon(
                    onPressed: () => _initialize(context),
                    icon: const Icon(Icons.numbers, size: 18),
                    label: const Text('Initialiser le compteur')),
              if (numbering == null && !canInitialize)
                const Text(
                    'Un administrateur doit renseigner le dernier numéro utilisé.',
                    style: TextStyle(
                        fontSize: 12, color: InstallationStyle.muted)),
            ]);
      });

  Future<void> _initialize(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          _NumberingInitializationDialog(onInitialize: onInitialize));
}

class _NumberingInitializationDialog extends StatefulWidget {
  const _NumberingInitializationDialog({required this.onInitialize});
  final Future<void> Function(String) onInitialize;

  @override
  State<_NumberingInitializationDialog> createState() =>
      _NumberingInitializationDialogState();
}

class _NumberingInitializationDialogState
    extends State<_NumberingInitializationDialog> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      InstallationNumbering.parseLastNumber(_controller.text);
      await widget.onInitialize(_controller.text.trim());
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: AlertDialog(
          scrollable: true,
          title: const Text('Initialiser la numérotation'),
          content: SizedBox(
              width: 420,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                        'Renseignez le dernier numéro réellement utilisé, toutes sociétés et prestations confondues. Cette initialisation est unique.'),
                    const SizedBox(height: 20),
                    TextField(
                        controller: _controller,
                        enabled: !_busy,
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Dernier numéro déjà utilisé'),
                        onChanged: (_) => setState(() => _error = null)),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, value, _) {
                          int? last;
                          try {
                            last = InstallationNumbering.parseLastNumber(
                                value.text);
                          } on FormatException {
                            /* Wait for a complete number. */
                          }
                          return Text(
                              last == null
                                  ? 'Le prochain numéro sera attribué à la validation d’un bon.'
                                  : 'Le prochain bon validé recevra le numéro ${last + 1}.',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: InstallationStyle.muted));
                        }),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      InstallationNotice(warning: true, message: _error!),
                    ],
                  ])),
          actions: [
            TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Initialisation…' : 'Initialiser')),
          ]));
}
