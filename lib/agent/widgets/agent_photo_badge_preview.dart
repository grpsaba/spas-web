import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../services/agent_photo_badge.dart';

class AgentPhotoBadgePreview extends StatelessWidget {
  const AgentPhotoBadgePreview({super.key, required this.result});

  final AgentPhotoBadgeResult result;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Badges avec photo'),
          leading: IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              tooltip: 'Télécharger le PDF',
              icon: const Icon(Icons.download),
              onPressed: () async {
                try {
                  await Printing.sharePdf(
                      bytes: result.bytes,
                      filename: 'badges-agents-avec-photo.pdf');
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Le téléchargement a échoué. Réessayez.')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: Column(children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
                'Format 85,6 × 54 mm · 8 badges par page A4 · Imprimer à 100 % (taille réelle).'),
          ),
          if (result.missingPhotos.isNotEmpty)
            ExpansionTile(
              leading: const Icon(Icons.photo_outlined, color: Colors.orange),
              title: Text(
                  '${result.missingPhotos.length} photo(s) absente(s) ou indisponible(s)'),
              subtitle: const Text(
                  'Ces badges portent la mention « Photo non fournie ». Vous pouvez compléter les fiches agents et relancer la génération.'),
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 160),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Text(result.missingPhotos.join('\n')),
                  ),
                ),
              ],
            ),
          Expanded(
              child: PdfPreview(
            build: (_) async => result.bytes,
            initialPageFormat: PdfPageFormat.a4,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            allowSharing: false,
            pdfFileName: 'badges-agents-avec-photo.pdf',
            onError: (_, __) => const Center(
              child: Text(
                  'Aperçu indisponible. Utilisez le bouton de téléchargement pour ouvrir le PDF.'),
            ),
          )),
        ]),
      ),
    );
  }
}
