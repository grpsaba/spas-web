// lib/utils/download_helper_web.dart
// web-only implementation (uses dart:html) — this file is only compiled for web
import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveAndOpenFile(Uint8List bytes, String filename, String mime) async {
  final blob = html.Blob([bytes], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  // open in new tab (or trigger download)
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..target = '_blank';
  // clicking anchor starts download / open
  anchor.click();
  // revoke later (delay to ensure browser started download)
  Future.delayed(const Duration(seconds: 2), () {
    html.Url.revokeObjectUrl(url);
  });
}

/// Helper class for download operations
class DownloadHelper {
  /// Download text content as a file
  static void downloadText(String content, String filename) {
    final bytes = Uint8List.fromList(content.codeUnits);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..target = '_blank';
    anchor.click();
    Future.delayed(const Duration(seconds: 2), () {
      html.Url.revokeObjectUrl(url);
    });
  }
}
