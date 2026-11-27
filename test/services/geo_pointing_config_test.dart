import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/error_logs/models/geo_diagnostic.dart';
import 'package:spas_web/services/mobile_config.dart';

Object? _valueAt(Map<String, dynamic> data, List<String> path) {
  Object? current = data;
  for (final key in path) {
    if (current is! Map) return null;
    current = current[key];
  }
  return current;
}

/// What Firestore does for `set(payload, SetOptions(mergeFields: mask))`:
/// only the masked paths are replaced (intermediate maps are created), every
/// other field of the stored document stays as it is.
Map<String, dynamic> _applyFieldMask(Map<String, dynamic> stored,
    Map<String, dynamic> payload, List<FieldPath> mask) {
  Map<String, dynamic> copy(Map source) => {
        for (final entry in source.entries)
          entry.key as String:
              entry.value is Map ? copy(entry.value as Map) : entry.value,
      };
  final result = copy(stored);
  for (final path in mask) {
    final keys = path.components;
    var target = result;
    for (final key in keys.take(keys.length - 1)) {
      final existing = target[key];
      final Map<String, dynamic> next =
          existing is Map<String, dynamic> ? existing : <String, dynamic>{};
      target[key] = next;
      target = next;
    }
    target[keys.last] = _valueAt(payload, keys);
  }
  return result;
}

void main() {
  group('GeoPointingConfig parsing', () {
    test('absent config shows the recommended values', () {
      for (final raw in [null, 'oops', 12]) {
        final config = GeoPointingConfig.fromJson(raw);
        expect(config.photoOfferAfterSeconds, 45);
        expect(config.photoFallbackEnabled, isTrue);
        expect(config.accuracyRule, GeoAccuracyRule.normal);
        expect(config.isRecommended, isTrue);
        expect(config.isStored, isFalse);
        expect(config.hasLegacySettings, isFalse);
        expect(config.lastModifiedLabel, isNull);
      }
      expect(MobileConfig.fromJson(const {}).geoPointing.isRecommended, isTrue);
    });

    test('new field is read and clamped to 15–120 s', () {
      expect(
          GeoPointingConfig.fromJson({'photoOfferAfterSeconds': 60})
              .photoOfferAfterSeconds,
          60);
      expect(
          GeoPointingConfig.fromJson({'photoOfferAfterSeconds': 3})
              .photoOfferAfterSeconds,
          15);
      expect(
          GeoPointingConfig.fromJson({'photoOfferAfterSeconds': '400'})
              .photoOfferAfterSeconds,
          120);
      expect(
          GeoPointingConfig.fromJson({'photoOfferAfterSeconds': 37.6})
              .photoOfferAfterSeconds,
          38);
      final stored = GeoPointingConfig.fromJson({
        'photoOfferAfterSeconds': 30,
        'photoFallbackEnabled': false,
        'accuracyRule': 'STRICT',
      });
      expect(stored.isStored, isTrue);
      expect(stored.photoFallbackEnabled, isFalse);
      expect(stored.accuracyRule, 'strict');
    });

    test('legacy documents load without error and keep their values', () {
      final legacy = GeoPointingConfig.fromJson({
        'attemptTimeoutSeconds': 30,
        'attemptsBeforePhoto': 3,
        'photoFallbackEnabled': true,
        'accuracyRule': 'normal',
      });
      // No new field yet: the phones use the recommended 45 s.
      expect(legacy.photoOfferAfterSeconds, 45);
      expect(legacy.isRecommended, isTrue);
      expect(legacy.isStored, isTrue);
      expect(legacy.legacyAttemptTimeoutSeconds, 30);
      expect(legacy.legacyAttemptsBeforePhoto, 3);
      expect(legacy.legacySummary,
          'Anciennes versions de l\'app : 30 s × 3 essais (conservé pour les '
          'téléphones pas encore mis à jour).');
      // Both kinds of fields in one document.
      final both = GeoPointingConfig.fromJson({
        'attemptTimeoutSeconds': 25,
        'attemptsBeforePhoto': 2,
        'photoOfferAfterSeconds': 60,
      });
      expect(both.photoOfferAfterSeconds, 60);
      expect(both.legacyAttemptsBeforePhoto, 2);
    });

    test('invalid types fall back to recommended values', () {
      final config = GeoPointingConfig.fromJson({
        'photoOfferAfterSeconds': 'abc',
        'attemptTimeoutSeconds': 'x',
        'attemptsBeforePhoto': double.nan,
        'photoFallbackEnabled': 'yes',
        'accuracyRule': 'whatever',
      });
      expect(config.photoOfferAfterSeconds, 45);
      expect(config.hasLegacySettings, isFalse);
      expect(config.photoFallbackEnabled, isTrue);
      expect(config.accuracyRule, 'normal');
      expect(
          GeoPointingConfig.fromJson({'photoOfferAfterSeconds': double.infinity})
              .photoOfferAfterSeconds,
          45);
    });

    test('copyWith can never leave the bounds', () {
      const config = GeoPointingConfig.recommended();
      expect(
          config.copyWith(photoOfferAfterSeconds: 150).photoOfferAfterSeconds,
          120);
      expect(config.copyWith(photoOfferAfterSeconds: 5).photoOfferAfterSeconds,
          15);
      final changed =
          config.copyWith(photoOfferAfterSeconds: 60, accuracyRule: 'strict');
      expect(changed.isRecommended, isFalse);
      expect(changed.withRecommendedValues().isRecommended, isTrue);
    });

    test('audit fields are read for "Modifié le … par …"', () {
      final config = GeoPointingConfig.fromJson({
        'photoOfferAfterSeconds': 30,
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
    test('recommended values explain the continuous search', () {
      expect(
        const GeoPointingConfig.recommended().summary,
        'Le bouton photo apparaît après 45 s de recherche GPS. Le GPS continue '
        'de chercher : s\'il trouve la position avant que la personne '
        'choisisse la photo, le pointage est enregistré par GPS. Après 180 s '
        'sans position, l\'app affiche « GPS introuvable ».',
      );
    });

    test('follows the edited value live', () {
      final config = const GeoPointingConfig.recommended()
          .copyWith(photoOfferAfterSeconds: 90);
      expect(config.summary, startsWith('Le bouton photo apparaît après 90 s'));
    });

    test('clear variant when the photo fallback is off', () {
      final config = const GeoPointingConfig.recommended()
          .copyWith(photoFallbackEnabled: false);
      expect(config.summary, isNot(contains('bouton photo')));
      expect(config.summary, contains('ne peut pas pointer'));
      expect(config.summary, startsWith('Aucune photo n\'est proposée'));
      expect(config.summary, contains('« GPS introuvable »'));
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

  group('save payload', () {
    test('only the edited geoPointing sub-fields, through a field mask', () {
      final payload = MobileConfigService.geoPointingWritePayload(
        const GeoPointingConfig.recommended()
            .copyWith(photoOfferAfterSeconds: 60),
        author: const GeoConfigAuthor(uid: 'u1', name: 'Awa Diallo'),
      );
      expect(payload.keys, ['geoPointing']);
      final geo = payload['geoPointing'] as Map<String, dynamic>;
      expect(geo['photoOfferAfterSeconds'], 60);
      expect(geo['photoFallbackEnabled'], isTrue);
      expect(geo['accuracyRule'], 'normal');
      expect(geo['updatedAt'], isA<FieldValue>());
      expect(geo['updatedBy'], {'uid': 'u1', 'name': 'Awa Diallo'});
      expect(geo.keys.toSet(), GeoPointingConfig.writtenFields.toSet());

      final options = MobileConfigService.geoPointingWriteOptions;
      expect(options.merge, isNull);
      // Never the whole `geoPointing` map: one path per written sub-field,
      // each present in the payload (Firestore rejects a mask field missing
      // from the data).
      expect(options.mergeFields, [
        FieldPath(const ['geoPointing', 'photoOfferAfterSeconds']),
        FieldPath(const ['geoPointing', 'photoFallbackEnabled']),
        FieldPath(const ['geoPointing', 'accuracyRule']),
        FieldPath(const ['geoPointing', 'updatedAt']),
        FieldPath(const ['geoPointing', 'updatedBy']),
      ]);
      for (final path in options.mergeFields!) {
        expect(_valueAt(payload, path.components), isNotNull, reason: '$path');
      }
    });

    test('a save leaves the legacy fields of app 1.8.0+18 untouched', () {
      // Stored document, legacy values included in shapes the web would not
      // write itself (string, double, 0): they must survive byte for byte.
      for (final legacyValues in <Map<String, dynamic>>[
        {'attemptTimeoutSeconds': 30, 'attemptsBeforePhoto': 3},
        {'attemptTimeoutSeconds': '25', 'attemptsBeforePhoto': 2.0},
        {'attemptTimeoutSeconds': 0, 'attemptsBeforePhoto': -1},
      ]) {
        final stored = <String, dynamic>{
          'pointingPhotoQuality': 80,
          'geoPointing': <String, dynamic>{
            ...legacyValues,
            'photoFallbackEnabled': true,
            'accuracyRule': 'normal',
            'updatedBy': {'uid': 'old', 'email': 'old@example.test'},
          },
        };
        final edited =
            GeoPointingConfig.fromJson(stored['geoPointing']).copyWith(
          photoOfferAfterSeconds: 50,
          photoFallbackEnabled: false,
          accuracyRule: 'strict',
        );
        final payload = MobileConfigService.geoPointingWritePayload(edited,
            author: const GeoConfigAuthor(uid: 'u1', name: 'Awa Diallo'));
        final geoPayload = payload['geoPointing'] as Map<String, dynamic>;
        expect(geoPayload.containsKey('attemptTimeoutSeconds'), isFalse);
        expect(geoPayload.containsKey('attemptsBeforePhoto'), isFalse);

        final after = _applyFieldMask(stored, payload,
            MobileConfigService.geoPointingWriteOptions.mergeFields!);
        final geo = after['geoPointing'] as Map<String, dynamic>;
        expect(geo['attemptTimeoutSeconds'],
            legacyValues['attemptTimeoutSeconds']);
        expect(geo['attemptsBeforePhoto'], legacyValues['attemptsBeforePhoto']);
        expect(geo['photoOfferAfterSeconds'], 50);
        expect(geo['photoFallbackEnabled'], isFalse);
        expect(geo['accuracyRule'], 'strict');
        // The author is replaced as a whole (no stale e-mail).
        expect(geo['updatedBy'], {'uid': 'u1', 'name': 'Awa Diallo'});
        expect(after['pointingPhotoQuality'], 80);
      }
    });

    test('saving when geoPointing does not exist yet writes no legacy field',
        () {
      final payload = MobileConfigService.geoPointingWritePayload(
          GeoPointingConfig.fromJson(null),
          author: const GeoConfigAuthor(uid: 'u1'));
      final after = _applyFieldMask(<String, dynamic>{}, payload,
          MobileConfigService.geoPointingWriteOptions.mergeFields!);
      final geo = after['geoPointing'] as Map<String, dynamic>;
      expect(geo.containsKey('attemptTimeoutSeconds'), isFalse);
      expect(geo.containsKey('attemptsBeforePhoto'), isFalse);
      expect(geo['photoOfferAfterSeconds'], 45);
    });
  });

  test('settings snapshot label (error logs): new and legacy shapes', () {
    expect(
        geoSettingsLabel({
          'photoOfferAfterSeconds': 45,
          'photoFallbackEnabled': true,
          'accuracyRule': 'normal',
        }),
        'Photo proposée après 45 s · photo de secours : oui · précision normale');
    expect(
        geoSettingsLabel({
          'attemptTimeoutSeconds': 25,
          'attemptsBeforePhoto': 2,
          'photoFallbackEnabled': false,
          'accuracyRule': 'strict',
        }),
        '25 s × 2 essais · photo de secours : non · précision stricte');
    expect(geoSettingsLabel(const {}), isNull);
  });
}
