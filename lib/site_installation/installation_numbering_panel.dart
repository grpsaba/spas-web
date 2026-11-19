import 'package:flutter/material.dart';

import 'installation_numbering.dart';
import 'installation_errors.dart';
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
              tone: InstallationTone.error,
              message:
                  'Impossible de lire le compteur des bons. ${installationErrorMessage(snapshot.error!)}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Bar(
              icon: Icons.numbers,
              text: 'Chargement de la numérotation…',
              loading: true);
        }
        final numbering = snapshot.data;
        if (numbering != null) {
          return _Bar(
              icon: Icons.numbers,
              text:
                  'Numérotation commune · Dernier numéro utilisé : ${numbering.lastNumber}');
        }
        return InstallationNotice(
            tone: InstallationTone.warning,
            title: 'Numérotation à initialiser',
            message: canInitialize
                ? 'Renseignez le dernier numéro de bon déjà utilisé avant la première validation.'
                : 'Un administrateur doit renseigner le dernier numéro utilisé avant la première validation.',
            action: canInitialize
                ? OutlinedButton.icon(
                    onPressed: () => _initialize(context),
                    icon: const Icon(Icons.numbers, size: 18),
                    label: const Text('Initialiser le compteur'))
                : null);
      });

  Future<void> _initialize(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Theme(
          data: InstallationStyle.theme(dialogContext),
          child: _NumberingInitializationDialog(onInitialize: onInitialize)));
}

class _Bar extends StatelessWidget {
  const _Bar({required this.icon, required this.text, this.loading = false});
  final IconData icon;
  final String text;
  final bool loading;
  @override
  Widget build(BuildContext context) => Row(children: [
        if (loading)
          const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2))
        else
          Icon(icon, size: 16, color: InstallationStyle.muted),
        const SizedBox(width: 8),
        Flexible(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: InstallationStyle.muted))),
      ]);
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
          _error = installationErrorMessage(error);
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
                        onSubmitted: (_) => _busy ? null : _save(),
                        decoration: InputDecoration(
                            labelText: 'Dernier numéro déjà utilisé',
                            errorText: _error),
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
                              style: InstallationStyle.caption);
                        }),
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
