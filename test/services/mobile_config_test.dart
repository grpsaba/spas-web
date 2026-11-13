import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/services/mobile_config.dart';

// Firestore references are faked only to inspect isolated write payloads.
// ignore: subtype_of_sealed_class
class _Document extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  final _writes = <Map<String, dynamic>>[];
  final _options = <SetOptions?>[];
  Map<String, dynamic> get written => _writes.last;
  SetOptions? get options => _options.last;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _writes.add(data);
    _options.add(options);
  }
}

// ignore: subtype_of_sealed_class
class _Collection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _Collection(this.document);
  final _Document document;
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    expect(path, MobileConfigService.documentId);
    return document;
  }
}

class _Firestore extends Fake implements FirebaseFirestore {
  final document = _Document();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    expect(path, MobileConfigService.collectionName);
    return _Collection(document);
  }
}

void main() {
  test('photo save and reset preserve the global tracking gate', () async {
    final firestore = _Firestore();
    final service = MobileConfigService(firestore: firestore);
    await service.saveConfig(const MobileConfig(
      backgroundTrackingEnabled: true,
      pointingPhotoQuality: 80,
    ));
    expect(firestore.document.written,
        isNot(contains('backgroundTrackingEnabled')));
    expect(firestore.document.written['pointingPhotoQuality'], 80);
    expect(firestore.document.options!.merge, isTrue);

    await service.resetToDefaults();
    expect(firestore.document.written,
        isNot(contains('backgroundTrackingEnabled')));
    expect(firestore.document.options!.merge, isTrue);
  });

  test('tracking toggle writes only the gate and its timestamp', () async {
    final firestore = _Firestore();
    await MobileConfigService(firestore: firestore)
        .setBackgroundTrackingEnabled(false);
    expect(firestore.document.written.keys.toSet(),
        {'backgroundTrackingEnabled', 'updatedAt'});
    expect(firestore.document.written['backgroundTrackingEnabled'], isFalse);
    expect(firestore.document.options!.merge, isTrue);
  });
}
