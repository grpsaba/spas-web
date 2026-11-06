import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_storage/firebase_storage.dart';

import '../model.dart';
import 'tenant_scope.dart';

class AgentPhotoService {
  static const maxFileBytes = 5 * 1024 * 1024;

  /// Decode before upload, normalize orientation/format and limit PDF size.
  static Future<Uint8List> prepare(Uint8List bytes) async {
    if (bytes.isEmpty || bytes.length > maxFileBytes) {
      throw const FormatException('La photo doit peser moins de 5 Mo.');
    }
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    // This API obtains intrinsic dimensions on web as well as native platforms.
    // ImageDescriptor.encoded(...).width/height are unsupported on web.
    // instantiateImageCodecWithSize takes ownership of the buffer.
    final codec = await ui.instantiateImageCodecWithSize(
      buffer,
      getTargetSize: (width, height) {
        final longest = width > height ? width : height;
        final scale = longest > 900 ? 900 / longest : 1.0;
        return ui.TargetImageSize(
          width: (width * scale).round().clamp(1, 900),
          height: (height * scale).round().clamp(1, 900),
        );
      },
    );
    try {
      final frame = await codec.getNextFrame();
      try {
        final png =
            await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) throw const FormatException('Photo illisible.');
        return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  static Future<String> upload(Agent agent, Uint8List png) async {
    TenantScope.applyTenantIdForWrite(agent);
    final tenant = Uri.encodeComponent(agent.tenantId);
    final code =
        Uri.encodeComponent(agent.code.isEmpty ? 'nouveau' : agent.code);
    // Versioned files keep the saved photo intact until the form is validated.
    final ref = FirebaseStorage.instance.ref(
      'agent-photos/$tenant/$code/${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await ref.putData(png, SettableMetadata(contentType: 'image/png'));
    return ref.getDownloadURL();
  }
}
