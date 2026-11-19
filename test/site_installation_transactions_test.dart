import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/site_installation/installation_transactions.dart';

class _Transaction extends Fake implements Transaction {}

void main() {
  test('business error survives the Firestore JS promise wrapper', () async {
    final cause = StateError('Numérotation non initialisée');
    await expectLater(
        installationTransaction<void>((callback) async {
          try {
            await callback(_Transaction());
          } catch (_) {
            throw StateError('Dart exception thrown from converted Future');
          }
        }, (_) async {
          throw cause;
        }),
        throwsA(same(cause)));
  });
  test('network and permission errors outside the callback keep their type',
      () async {
    final cause =
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    await expectLater(
        installationTransaction<void>((callback) async {
          await callback(_Transaction());
          throw cause;
        }, (_) async {}),
        throwsA(same(cause)));
  });
  test('transaction retries clear any error captured by an earlier attempt',
      () async {
    final commitFailure =
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    var attempt = 0;
    await expectLater(
        installationTransaction<void>((callback) async {
          try {
            await callback(_Transaction());
          } catch (_) {/* SDK retries. */}
          await callback(_Transaction());
          throw commitFailure;
        }, (_) async {
          if (attempt++ == 0) throw StateError('Temporary callback failure');
        }),
        throwsA(same(commitFailure)));
    expect(attempt, 2);
  });
  test('successful transactions return the final callback result', () async {
    expect(
        await installationTransaction<int>(
            (callback) => callback(_Transaction()), (_) async => 31503),
        31503);
  });
}
