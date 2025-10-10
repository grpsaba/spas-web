// lib/utils/download_helper.dart
export 'download_helper_io.dart' // fallback for non-web
  if (dart.library.html) 'download_helper_web.dart';
