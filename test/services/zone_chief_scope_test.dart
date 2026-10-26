import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/zone_chief_scope.dart';

ZoneMember member(
        {String scope = ZoneMemberScope.assigned,
        String? department = 'security'}) =>
    ZoneMember(
      UID: 'chief',
      code: 'CH1',
      firstName: 'Test',
      lastName: 'Chef',
      phone: '',
      email: '',
      actif: true,
      poste: 'Chef de zone',
      zone: Zone(codeZone: 'A', name: 'Zone A'),
      tenantId: 'ml',
      hasTenantId: true,
      departmentId: department,
      zoneScope: scope,
    );

Site site(
        {String tenant = 'ml',
        List<String> departments = const ['security'],
        String? zone = 'A',
        bool active = true}) =>
    Site(
      UID: 'site',
      codeSite: 'S1',
      name: 'Site test',
      adresse: '',
      email: '',
      phone: '',
      latLng: LatLngModel(lat: 0, lng: 0),
      token: '',
      nbAgent: 0,
      supervisor: null,
      supervisor_2: null,
      actif: active,
      nbRonde: 0,
      dateContrat: DateTime(2024, 1, 1),
      zone: zone == null ? null : Zone(codeZone: zone, name: zone),
      tenantId: tenant,
      departmentIds: departments,
    );

void main() {
  test('Existing profiles retain their assigned zone without zoneScope', () {
    final json = member().toJson()..remove('zoneScope');
    final restored = ZoneMember.fromJson(json);
    expect(restored.zoneScope, ZoneMemberScope.assigned);
    expect(restored.hasSiteScope, isTrue);
    expect(restored.hasGlobalZoneAccess, isFalse);
    expect(ZoneChiefScope.includesSite(restored, site(zone: 'B')), isFalse);
  });

  test('Global security profile round trips with no assigned zone', () {
    final global = member(scope: ZoneMemberScope.global)..zone = null;
    final restored = ZoneMember.fromJson(global.toJson());
    expect(restored.hasSiteScope, isTrue);
    expect(restored.hasGlobalZoneAccess, isTrue);
    expect(restored.zone, isNull);
    expect(restored.zoneScopeLabel, 'Toutes les zones · Sécurité');
  });

  test('Missing or unknown scope never grants global access', () {
    for (final value in [null, '', 'all', 'GLOBAL', 1]) {
      final restored =
          ZoneMember.fromJson(member().toJson()..['zoneScope'] = value);
      expect(restored.hasGlobalZoneAccess, isFalse);
      expect(ZoneChiefScope.includesSite(restored, site(zone: 'B')), isFalse);
    }
  });

  test('Global scope cannot be used outside Security even with a zone', () {
    for (final department in ['cleaning', 'direction', '', null]) {
      final invalid =
          member(scope: ZoneMemberScope.global, department: department);
      expect(invalid.hasGlobalZoneAccess, isFalse);
      expect(invalid.hasSiteScope, isFalse);
      expect(ZoneChiefScope.includesSite(invalid, site()), isFalse);
    }
  });

  test(
      'Global Security sees Security and shared sites across zones in its country',
      () {
    final global = member(scope: ZoneMemberScope.global)..zone = null;
    for (final zone in ['A', 'B', null]) {
      expect(
          ZoneChiefScope.includesActiveSite(global, site(zone: zone)), isTrue);
    }
    expect(
        ZoneChiefScope.includesSite(
            global, site(departments: ['security', 'cleaning'])),
        isTrue);
    expect(ZoneChiefScope.includesSite(global, site(departments: ['cleaning'])),
        isFalse);
    expect(ZoneChiefScope.includesSite(global, site(departments: [])), isFalse);
    expect(ZoneChiefScope.includesSite(global, site(tenant: 'ci')), isFalse);
    expect(ZoneChiefScope.includesActiveSite(global, site(active: false)),
        isFalse);
  });

  test('Assigned chief still requires matching country, department and zone',
      () {
    final assigned = member();
    expect(ZoneChiefScope.includesSite(assigned, site()), isTrue);
    expect(ZoneChiefScope.includesSite(assigned, site(zone: 'B')), isFalse);
    expect(ZoneChiefScope.includesSite(assigned, site(zone: null)), isFalse);
    expect(ZoneChiefScope.includesSite(assigned, site(tenant: 'ci')), isFalse);
    expect(
        ZoneChiefScope.includesSite(assigned, site(departments: ['cleaning'])),
        isFalse);
    assigned.zone = null;
    expect(assigned.hasSiteScope, isFalse);
  });

  test('An explicit country and department are required', () {
    final json = member(scope: ZoneMemberScope.global).toJson()
      ..remove('tenantId');
    final restored = ZoneMember.fromJson(json);
    expect(restored.hasSiteScope, isFalse);
    expect(ZoneChiefScope.includesSite(restored, site()), isFalse);
    expect((member()..tenantId = '').hasSiteScope, isFalse);
    expect(member(department: null).hasSiteScope, isFalse);
  });

  test('Legacy site snapshots keep their Security membership', () {
    final legacy = site(departments: [])
      ..supervisor = Supervisor.fromJson({
        'UID': 'sup', 'code': 'S', 'firstName': 'Test', 'lastName': 'Supervisor',
        'phone': '', 'email': '', 'token': '', 'tracking': false,
        'tenantId': 'ml', 'departmentId': 'security',
      });
    final global = member(scope: ZoneMemberScope.global)..zone = null;
    expect(ZoneChiefScope.includesSite(global, legacy), isTrue);
    legacy.supervisor!.departmentId = 'cleaning';
    expect(ZoneChiefScope.includesSite(global, legacy), isFalse);
  });

  test('Cached sites without a supervisor or zone can be read by a global chief', () {
    final global = member(scope: ZoneMemberScope.global)..zone = null;
    final restored = Site.fromJson(site(zone: null).toJson());
    expect(restored.supervisor, isNull);
    expect(restored.zone, isNull);
    expect(ZoneChiefScope.includesActiveSite(global, restored), isTrue);
  });

  test('Changing scope, country, zone or department cannot reuse cached sites',
      () {
    final assigned = member();
    final keys = <String>{ZoneChiefScope.cacheScope(assigned)};
    assigned.zone = Zone(codeZone: 'B', name: 'Zone B');
    keys.add(ZoneChiefScope.cacheScope(assigned));
    assigned.zoneScope = ZoneMemberScope.global;
    keys.add(ZoneChiefScope.cacheScope(assigned));
    assigned.tenantId = 'ci';
    keys.add(ZoneChiefScope.cacheScope(assigned));
    assigned.departmentId = 'cleaning';
    keys.add(ZoneChiefScope.cacheScope(assigned));
    expect(keys, hasLength(5));
    final security = member(scope: ZoneMemberScope.global);
    final globalKey = ZoneChiefScope.cacheScope(security);
    security.zone = null;
    expect(ZoneChiefScope.cacheScope(security), globalKey);
    expect(ZoneChiefScope.includesSite(member(), site(zone: 'B')), isFalse);
  });
}
