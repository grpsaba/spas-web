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
        setState(() => _error =
            'Impossible de préparer le document : ${installationReadableError(error)}');
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
            final compact = MediaQuery.sizeOf(context).width <
                InstallationStyle.compactWidth;
            final actions = official && widget.canPrint
                ? [
                    FilledButton.icon(
                        onPressed: exportable
                            ? () => _export(state.data!, print: true)
                            : null,
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: const Text('Imprimer')),
                    OutlinedButton.icon(
                        onPressed: exportable
                            ? () => _export(state.data!, print: false)
                            : null,
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Télécharger le PDF')),
                  ]
                : const <Widget>[];
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    const Expanded(
                        child: Text('Aperçu du bon',
                            style: InstallationStyle.sectionTitle)),
                    if (official)
                      Text('Bon n° ${_snapshot.bonNumber}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: InstallationStyle.ink))
                    else
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                              color: InstallationStyle.warningSoft,
                              borderRadius: BorderRadius.circular(20)),
                          child: const Text('Brouillon',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: InstallationStyle.warning))),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                      !official
                          ? 'Aperçu du brouillon. Le document définitif sera disponible après validation du bon.'
                          : widget.hasUnsavedChanges
                              ? 'Enregistrez les modifications avant de télécharger le document.'
                              : widget.canPrint
                                  ? 'Format A4 · Le téléchargement et l’impression utilisent le document affiché.'
                                  : 'Format A4 · Bon n° ${_snapshot.bonNumber}',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: official && widget.hasUnsavedChanges
                              ? InstallationStyle.warning
                              : InstallationStyle.muted)),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    if (compact)
                      Row(children: [
                        Expanded(child: actions[0]),
                        const SizedBox(width: 8),
                        Expanded(child: actions[1]),
                      ])
                    else
                      Wrap(spacing: 10, runSpacing: 10, children: actions),
                  ],
                  const SizedBox(height: 14),
                  if (_exporting) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    const SizedBox(height: 8),
                  ],
                  if (_error != null) ...[
                    InstallationNotice(
                        tone: InstallationTone.error, message: _error!),
                    const SizedBox(height: 8),
                  ],
                  if (state.hasError)
                    InstallationNotice(
                        tone: InstallationTone.error,
                        message:
                            'Impossible de générer l’aperçu : ${installationReadableError(state.error!)}',
                        action: TextButton(
                            onPressed: () => setState(_buildPdf),
                            child: const Text('Réessayer')))
                  else if (!ready)
                    const SizedBox(
                        height: 320,
                        child: InstallationStateMessage(
                            loading: true,
                            title: 'Préparation de l’aperçu…',
                            message:
                                'Le document A4 est généré sur cet appareil.'))
                  else
                    SizedBox(
                        height: MediaQuery.sizeOf(context)
                                .height
                                .clamp(420.0, 800.0) *
                            .8,
                        child: RepaintBoundary(
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
                                      tone: InstallationTone.error,
                                      message:
                                          'Le lecteur PDF n’a pas pu afficher le document. ${installationReadableError(error)}'),
                                )))),
                ]);
          }));
}
