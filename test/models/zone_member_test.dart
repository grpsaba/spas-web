import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/model.dart';

void main() {
  group('ZoneMember.fromJson', () {
    test('conserve une zone renseignée et les périmètres d’accès', () {
      final member = ZoneMember.fromJson(_memberJson('assigned'));

      expect(member.zone?.codeZone, 'zone-a');
      expect(member.zone?.name, 'Zone A');
      expect(member.zone?.tenantId, 'tenant-a');
      expect(member.tenantId, 'tenant-a');
      expect(member.departmentId, 'security');
    });

    test('accepte une zone explicitement nulle', () {
      final member =
          ZoneMember.fromJson(_memberJson('unassigned')..['zone'] = null);

      expect(member.UID, 'unassigned');
      expect(member.actif, isTrue);
      expect(member.zone, isNull);
    });

    test('accepte une fiche sans champ zone', () {
      final member = ZoneMember.fromJson(_memberJson('legacy')..remove('zone'));

      expect(member.UID, 'legacy');
      expect(member.zone, isNull);
    });

    test('relit une fiche sans zone produite par toJson', () {
      final original = ZoneMember(
        UID: 'unassigned',
        code: 'CZ-1',
        firstName: 'Chef',
        lastName: 'Test',
        phone: '',
        email: 'chef@example.com',
        actif: true,
        poste: 'Chef de zone',
        zone: null,
        tenantId: 'tenant-a',
        departmentId: 'security',
      );

      final member = ZoneMember.fromJson(original.toJson());

      expect(member.toJson(), original.toJson());
    });

    test('une fiche sans zone ne bloque pas les autres chefs du lot', () {
      final documents = [
        _memberJson('assigned-before'),
        _memberJson('unassigned')..['zone'] = null,
        _memberJson('assigned-after'),
      ];

      final members = documents.map(ZoneMember.fromJson).toList();

      expect(members.map((member) => member.UID), [
        'assigned-before',
        'unassigned',
        'assigned-after',
      ]);
      expect(members[0].zone?.codeZone, 'zone-a');
      expect(members[1].zone, isNull);
      expect(members[2].zone?.codeZone, 'zone-a');
    });

    test('relit aussi un pointage dont le chef n’a pas de zone', () {
      final pointing = PointingZone.fromJson({
        'date': '2026-10-29T10:00:00.000',
        'latlng': {'lat': 12.6, 'lng': -8.0},
        'site': {'UID': 'site-a', 'name': 'Site A'},
        'zoneMember': _memberJson('unassigned')..['zone'] = null,
        'distance': 0.0,
      });

      expect(pointing.site.UID, 'site-a');
      expect(pointing.zoneMember?.UID, 'unassigned');
      expect(pointing.zoneMember?.zone, isNull);
      expect(pointing.date, DateTime(2026, 10, 29, 10));
    });
  });
}

Map<String, dynamic> _memberJson(String uid) => {
      'UID': uid,
      'code': 'CZ-1',
      'firstName': 'Chef',
      'lastName': 'Test',
      'phone': '',
      'email': 'chef@example.com',
      'token': '',
      'actif': true,
      'poste': 'Chef de zone',
      'tenantId': 'tenant-a',
      'departmentId': 'security',
      'zone': {
        'codeZone': 'zone-a',
        'name': 'Zone A',
        'tenantId': 'tenant-a',
      },
    };
