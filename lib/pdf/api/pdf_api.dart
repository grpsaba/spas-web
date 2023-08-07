import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart';
import 'package:universal_html/html.dart' as html;

class PdfApi {
  static Future<Uint8List> saveDocument({
    required String name,
    required Document pdf,
  }) async {
    final bytes = await pdf.save();

    return bytes;
  }

  static openFile(Uint8List file) async {
    final blob = html.Blob([file], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, "_blank");
    html.Url.revokeObjectUrl(url);
  }
}
