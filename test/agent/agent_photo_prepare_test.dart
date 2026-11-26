import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/services/agent_photo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('JPEG is accepted and its EXIF orientation is preserved', () async {
    // Synthetic 16 x 24 JPEG with EXIF orientation 6 (90 degrees clockwise).
    final jpeg = base64Decode(
      '/9j/4AAQSkZJRgABAQAAAQABAAD/4QAiRXhpZgAATU0AKgAAAAgAAQESAAMAAAABAAYAAAAAAAD/'
      '2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAx'
      'NDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIy'
      'MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAYABADASIAAhEBAxEB/'
      '8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQID'
      'AAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6'
      'Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWm'
      'p6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/'
      '8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC'
      'AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5'
      'OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOk'
      'paanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/'
      '9oADAMBAAIRAxEAPwCCiiivUPLCiiigD//Z',
    );

    await _expectPreparedSize(jpeg, 24, 16);
  });

  test('large landscape PNG is reduced proportionally to 900 pixels', () async {
    await _expectPreparedSize(await _png(1200, 600), 900, 450);
  });

  test('large portrait PNG is reduced proportionally to 900 pixels', () async {
    await _expectPreparedSize(await _png(600, 1200), 450, 900);
  });

  test('small PNG keeps its original dimensions', () async {
    await _expectPreparedSize(await _png(24, 16), 24, 16);
  });
}

Future<Uint8List> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawColor(const ui.Color(0xFF5A82A0), ui.BlendMode.src);
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(width, height);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      image.dispose();
    }
  } finally {
    picture.dispose();
  }
}

Future<void> _expectPreparedSize(
    Uint8List source, int width, int height) async {
  final result = await AgentPhotoService.prepare(source);
  expect(result.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);

  final codec = await ui.instantiateImageCodec(result);
  try {
    final frame = await codec.getNextFrame();
    try {
      expect(frame.image.width, width);
      expect(frame.image.height, height);
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
}
