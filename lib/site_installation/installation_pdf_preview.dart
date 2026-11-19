import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import 'installation_order.dart';
import 'installation_pdf.dart';
import 'installation_ui.dart';

/// Preview and exports share one immutable snapshot and the exact same bytes.
class InstallationPdfPreview extends StatefulWidget {
  const InstallationPdfPreview(
      {super.key,
      required this.order,
      required this.canPrint,
      this.hasUnsavedChanges = false,
      this.active = true});
  final InstallationOrder order;
  final bool canPrint;
  final bool hasUnsavedChanges;
  final bool active;
  @override
  State<InstallationPdfPreview> createState() => _InstallationPdfPreviewState();
}

class _InstallationPdfPreviewState extends State<InstallationPdfPreview> {
  late String _fingerprint;
  late InstallationOrder _snapshot;
  late Future<Uint8List> _pdf;
  late LayoutCallback _layout;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _buildPdf();
  }

  @override
  void didUpdateWidget(covariant InstallationPdfPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && _fingerprint != _fingerprintOf(widget.order)) {
      _buildPdf();
    }
  }

  void _buildPdf() {
    _snapshot = widget.order.copy();
    _fingerprint = _fingerprintOf(_snapshot);
    _pdf = InstallationPdf.build(_snapshot, preview: true);
    _layout = (_) => _pdf;
    _error = null;
  }

  // Only changes visible on the document require a new PDF. Synchronisation
  // metadata, comments and attachments must not restart its generation.
  String _fingerprintOf(InstallationOrder order) => jsonEncode({
        'official': InstallationPdf.isPrintable(order),
        'number': order.bonNumber,
        'department': order.departmentId,
        'date': (order.contractDate ?? order.createdAt)?.toIso8601String(),
        'site': order.siteName,
        'client': order.clientName,
        'address': order.address,
        'phone': order.phone,
        'agents': [
          for (final agent in order.agents)
            [agent.name, agent.type, agent.phone]
        ],
        'equipment': [
          for (final item in order.equipment) [item.designation, item.quantity]
        ],
      });

  Future<void> _export(Uint8List bytes, {required bool print}) async {
    setState(() {
      _exporting = true;
      _error = null;
    });
    try {
      final name = 'Bon-${_snapshot.bonNumber}.pdf';
      if (print) {
        await Printing.layoutPdf(name: name, onLayout: (_) async => bytes);
      } else {
        await Printing.sharePdf(bytes: bytes, filename: name);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Impossible de préparer le document : $error');
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => InstallationPanel(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<Uint8List>(
          future: _pdf,
          builder: (context, state) {
            final official = InstallationPdf.isPrintable(_snapshot);
            final ready =
                state.connectionState == ConnectionState.done && state.hasData;
            final exportable = official &&
                widget.canPrint &&
                !widget.hasUnsavedChanges &&
                !_exporting &&
                ready;
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Aperçu du bon',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: InstallationStyle.ink)),
                        if (official && widget.canPrint) ...[
                          OutlinedButton.icon(
                              onPressed: exportable
                                  ? () => _export(state.data!, print: false)
                                  : null,
                              icon:
                                  const Icon(Icons.download_outlined, size: 18),
                              label: const Text('Télécharger le PDF')),
                          OutlinedButton.icon(
                              onPressed: exportable
                                  ? () => _export(state.data!, print: true)
                                  : null,
                              icon: const Icon(Icons.print_outlined, size: 18),
                              label: const Text('Imprimer')),
                        ],
                      ]),
                  const SizedBox(height: 12),
                  Text(
                      !official
                          ? 'Aperçu du brouillon. Le document définitif sera disponible après validation du bon.'
                          : widget.hasUnsavedChanges
                              ? 'Enregistrez les modifications avant de télécharger le document.'
                              : widget.canPrint
                                  ? 'Format A4 · Le téléchargement et l’impression utilisent le document affiché.'
                                  : 'Format A4 · Bon n° ${_snapshot.bonNumber}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: InstallationStyle.muted,
                          height: 1.5)),
                  const SizedBox(height: 16),
                  if (_exporting) const LinearProgressIndicator(minHeight: 2),
                  if (_error != null)
                    InstallationNotice(warning: true, message: _error!),
                  if (state.hasError)
                    InstallationNotice(
                        warning: true,
                        message:
                            'Impossible de générer l’aperçu : ${state.error}',
                        action: TextButton(
                            onPressed: () => setState(_buildPdf),
                            child: const Text('Réessayer')))
                  else if (!ready)
                    const SizedBox(
                        height: 360,
                        child: Center(child: CircularProgressIndicator()))
                  else
                    SizedBox(
                        height: MediaQuery.sizeOf(context)
                                .height
                                .clamp(420.0, 800.0) *
                            .8,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: PdfPreview(
                              key: ValueKey(_fingerprint),
                              build: _layout,
                              initialPageFormat: PdfPageFormat.a4,
                              canChangeOrientation: false,
                              canChangePageFormat: false,
                              canDebug: false,
                              useActions: false,
                              allowPrinting: false,
                              allowSharing: false,
                              maxPageWidth: 720,
                              pdfFileName: 'Bon-${_snapshot.bonNumber}.pdf',
                              scrollViewDecoration: const BoxDecoration(
                                  color: InstallationStyle.background),
                              onError: (_, error) => InstallationNotice(
                                  warning: true,
                                  message:
                                      'Le lecteur PDF n’a pas pu afficher le document. $error'),
                            ))),
                ]);
          }));
}
