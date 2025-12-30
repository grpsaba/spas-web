// lib/utils/download_helper_io.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> saveAndOpenFile(
    Uint8List bytes, String filename, String mime) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsBytes(bytes);
  // try opening (platform dependent). You can also integrate `share_plus` to share.
  await OpenFile.open(file.path);
}

/// Helper class for download operations
class DownloadHelper {
  /// Download text content as a file
  static void downloadText(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content);
    await OpenFile.open(file.path);
  }
}
