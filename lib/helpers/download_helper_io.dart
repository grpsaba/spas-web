// lib/utils/download_helper_io.dart
import 'dart:typed_data';

Future<void> saveAndOpenFile(
    Uint8List bytes, String filename, String mime) async {
  throw UnsupportedError(
    'saveAndOpenFile is only supported on web in this project.',
  );
}

/// Helper class for download operations
class DownloadHelper {
  /// Download text content as a file
  static void downloadText(String content, String filename) {
    throw UnsupportedError(
      'DownloadHelper.downloadText is only supported on web in this project.',
    );
  }
}
