import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/services/mobile_config.dart';

void main() {
  group('GeoPointingConfig parsing', () {
    test('absent config shows the recommended values', () {
      for (final raw in [null, 'oops', 12]) {
        final config = GeoPointingConfig.fromJson(raw);
        expect(config.attemptTimeoutSeconds, 25);
        expect(config.attemptsBeforePhoto, 2);
        expect(config.photoFallbackEnabled, isTrue);
        expect(config.accuracyRule, GeoAccuracyRule.normal);
        expect(config.isRecommended, isTrue);
        expect(config.isStored, isFalse);
        expect(config.lastModifiedLabel, isNull);
      }
      expect(MobileConfig.fromJson(const {}).geoPointing.isRecommended, isTrue);
    });

    test('values out of bounds are clamped, missing ones use defaults', () {
      final low = GeoPointingConfig.fromJson({
        'attemptTimeoutSeconds': 3,
        'attemptsBeforePhoto': 0,
      });
      expect(low.attemptTimeoutSeconds, 15);
      expect(low.attemptsBeforePhoto, 1);
      expect(low.photoFallbackEnabled, isTrue);
      expect(low.accuracyRule, 'normal');
      expect(low.isStored, isTrue);

      final high = GeoPointingConfig.fromJson({
        'attemptTimeoutSeconds': 120.7,
        'attemptsBeforePhoto': '9',
        'photoFallbackEnabled': false,
        'accuracyRule': 'STRICT',
      });
      expect(high.attemptTimeoutSeconds, 45);
      expect(high.attemptsBeforePhoto, 3);
      expect(high.photoFallbackEnabled, isFalse);
      expect(high.accuracyRule, 'strict');
    });

    test('invalid types fall back to recommended values', () {
      final config = GeoPointingConfig.fromJson({
        'attemptTimeoutSeconds': 'abc',
        'attemptsBeforePhoto': double.nan,
        'photoFallbackEnabled': 'yes',
        'accuracyRule': 'whatever',
      });
      expect(config.attemptTimeoutSeconds, 25);
      expect(config.attemptsBeforePhoto, 2);
      expect(config.photoFallbackEnabled, isTrue);
      expect(config.accuracyRule, 'normal');
    });

    test('copyWith can never leave the bounds', () {
      const config = GeoPointingConfig.recommended();
      expect(
          config.copyWith(attemptTimeoutSeconds: 50).attemptTimeoutSeconds, 45);
      expect(config.copyWith(attemptsBeforePhoto: -1).attemptsBeforePhoto, 1);
      final changed =
          config.copyWith(attemptTimeoutSeconds: 40, accuracyRule: 'strict');
      expect(changed.isRecommended, isFalse);
      expect(changed.withRecommendedValues().isRecommended, isTrue);
    });

    test('audit fields are read for "Modifié le … par …"', () {
      final config = GeoPointingConfig.fromJson({
        'attemptTimeoutSeconds': 30,
        'updatedAt': Timestamp.fromDate(DateTime(2026, 11, 26, 14, 5)),
        'updatedBy': {'uid': 'u1', 'name': 'Awa Diallo', 'email': 'a@x.ml'},
      });
      expect(config.lastModifiedLabel,
          'Modifié le 26/11/2026 à 14:05 par Awa Diallo');
      final byEmail = GeoPointingConfig.fromJson({
        'updatedBy': {'email': 'a@x.ml'},
      });
      expect(byEmail.lastModifiedLabel, 'Modifié par a@x.ml');
    });
  });

  group('summary sentence', () {
    test('recommended values', () {
      expect(
        const GeoPointingConfig.recommended().summary,
        'Le superviseur attend au plus 25 s, 2 fois (50 s au total), '
        'puis peut pointer avec une photo.',
      );
    });

    test('follows the edited values live', () {
      final config = const GeoPointingConfig.recommended()
          .copyWith(attemptTimeoutSeconds: 40, attemptsBeforePhoto: 3);
      expect(config.summary, contains('au plus 40 s, 3 fois (120 s au total)'));
      expect(config.maxTotalWaitSeconds, 120);
      final single = config.copyWith(attemptsBeforePhoto: 1);
      expect(single.summary,
          'Le superviseur attend au plus 40 s, 1 seul essai, puis peut pointer avec une photo.');
    });

    test('clear variant when the photo fallback is off', () {
      final config = const GeoPointingConfig.recommended()
          .copyWith(photoFallbackEnabled: false);
      expect(
          config.summary, isNot(contains('puis peut pointer avec une photo')));
      expect(config.summary, contains('il ne peut pas pointer'));
      expect(config.summary, contains('aucune photo n\'est proposée'));
    });

    test('accuracy explanation', () {
      expect(const GeoPointingConfig.recommended().accuracySummary,
          startsWith('Précision normale'));
      expect(
          const GeoPointingConfig.recommended()
              .copyWith(accuracyRule: 'strict')
              .accuracySummary,
          startsWith('Précision stricte'));
    });
  });

  test('save payload only contains the geoPointing map', () {
    final payload = MobileConfigService.geoPointingWritePayload(
      const GeoPointingConfig.recommended().copyWith(attemptTimeoutSeconds: 35),
      author: const GeoConfigAuthor(uid: 'u1', name: 'Awa Diallo'),
    );
    expect(payload.keys, ['geoPointing']);
    final geo = payload['geoPointing'] as Map<String, dynamic>;
    expect(geo['attemptTimeoutSeconds'], 35);
    expect(geo['attemptsBeforePhoto'], 2);
    expect(geo['photoFallbackEnabled'], isTrue);
    expect(geo['accuracyRule'], 'normal');
    expect(geo['updatedAt'], isA<FieldValue>());
    expect(geo['updatedBy'], {'uid': 'u1', 'name': 'Awa Diallo'});
    final options = MobileConfigService.geoPointingWriteOptions;
    expect(options.merge, isNull);
    expect(options.mergeFields, [
      FieldPath(const ['geoPointing'])
    ]);
  });
}
