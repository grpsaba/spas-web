import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/site_installation/installation_transactions.dart';

void main() {
  test('real web Firestore preserves the original transaction callback error',
      () async {
    final app = await Firebase.initializeApp(
        name: 'installation-errors-test',
        options: const FirebaseOptions(
            apiKey: 'demo-key',
            appId: '1:123:web:demo',
            messagingSenderId: '123',
            projectId: 'demo-spas-installation'));
    final db = FirebaseFirestore.instanceFor(app: app);
    db.useFirestoreEmulator('127.0.0.1', 8188);
    final cause = StateError('Numérotation non initialisée');
    // No read or write is issued: the failure happens in the callback itself.
    await expectLater(
        installationTransaction<void>(
            (handler) => db.runTransaction<void>(handler), (_) async {
          throw cause;
        }),
        throwsA(same(cause)));
    await db.terminate();
    await app.delete();
  }, skip: !kIsWeb);
}
