import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spas_web/model.dart';

import 'authentication.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

enum SiteSupervisorSlot {
  primary,
  secondary,
}

extension SiteSupervisorSlotLabel on SiteSupervisorSlot {
  String get label {
    switch (this) {
      case SiteSupervisorSlot.primary:
        return 'Superviseur 1';
      case SiteSupervisorSlot.secondary:
        return 'Superviseur 2';
    }
  }

  String get firestoreField {
    switch (this) {
      case SiteSupervisorSlot.primary:
        return 'supervisor';
      case SiteSupervisorSlot.secondary:
        return 'supervisor_2';
    }
  }
}

class SiteSupervisorMigration {
  const SiteSupervisorMigration({
    required this.site,
    required this.slot,
  });

  final Site site;
  final SiteSupervisorSlot slot;
}

class SiteService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Sites");

  Query get _scopedQuery => DepartmentScope.applyToSiteQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<User?> add(Site site, password) async {
    TenantScope.applyTenantIdForWrite(site);
    _requireSiteWriteAccess(site);
    var user = await AuthService().createUserWithEmail(site.email, password);
    if (user != null) {
      site.UID = user.uid;
      _collectionReference
          .doc(user.uid)
          .set(site.toJson())
          .onError((error, stackTrace) => print(error));
    }
    return user;
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'SiteService.all',
      _scopedQuery,
    );
  }

  Stream<QuerySnapshot> allSos() {
    return TenantScope.watchQuery(
      'SiteService.allSos',
      _scopedQuery.where(Filter.and(
          Filter('sos', isEqualTo: true), Filter('actif', isEqualTo: true))),
    );
  }
  //  await _collectionReference.where('actif', isEqualTo: true,)
  //       .where(Filter.(Filter('supervisor.UID', isEqualTo: supervisor.UID),
  //        Filter('supervisor_2.UID', isEqualTo: supervisor.UID))).count().get();

  Stream<QuerySnapshot> allActifSite() {
    return TenantScope.watchQuery(
      'SiteService.allActifSite',
      _scopedQuery.where("actif", isEqualTo: true),
    );
  }

  Future<List<Site>> allAsModel() async {
    try {
      var snapshot = await TenantScope.getQuery(
        'SiteService.allAsModel',
        _scopedQuery.where("actif", isEqualTo: true),
      );
      var collection = snapshot.docs.map((snap) {
        return Site.fromJson(snap.data() as Map<String, dynamic>);
      }).toList();

      return collection;
    } catch (e) {
      print("Erreur lors de la récupération des sites : $e");
      return [];
    }
  }

  Future<List<Site>> allActifAsModel() async {
    var snapshot = await TenantScope.getQuery(
      'SiteService.allActifAsModel',
      _scopedQuery.where("actif", isEqualTo: true),
    );
    var collection = snapshot.docs.map((snap) {
      return Site.fromJson(snap.data() as Map<String, dynamic>);
    }).toList();

    return collection;
  }

  Future<List<Site>> allSitesByZone(Zone zone) async {
    var s1 = await TenantScope.getQuery(
      'SiteService.allSitesByZone',
      _scopedQuery
          .where("zone.codeZone", isEqualTo: zone.codeZone)
          .where("actif", isEqualTo: true),
    );

    var s1Future = s1.docs.map((snap) {
      return Site.fromJson(jsonDecode(jsonEncode(snap.data())));
    });

    return s1Future.toList();
  }

  Future<int?> allSitesCountByZone(Zone zone) async {
    var s1 = await TenantScope.getCount(
      'SiteService.allSitesCountByZone',
      _scopedQuery
          .where("zone.codeZone", isEqualTo: zone.codeZone)
          .where("actif", isEqualTo: true)
          .count(),
    );

    return s1.count;
  }

  Future<int?> allSitesCountBySupervisor(Supervisor supervisor) async {
    if (supervisor.isSpecial && supervisor.zone != null) {
      return await allSitesCountByZone(supervisor.zone!);
    }
    var snapshot = await TenantScope.getCount(
      'SiteService.allSitesCountBySupervisor',
      _scopedQuery
          .where(
            'actif',
            isEqualTo: true,
          )
          .where(Filter.or(Filter('supervisor.UID', isEqualTo: supervisor.UID),
              Filter('supervisor_2.UID', isEqualTo: supervisor.UID)))
          .count(),
    );

    return snapshot.count;
  }

  Future<List<Site>> allBySupervisor(Supervisor supervisor) async {
    if (supervisor.isSpecial && supervisor.zone != null) {
      return await allSitesByZone(supervisor.zone!);
    }
    var snapshot = await TenantScope.getQuery(
      'SiteService.allBySupervisor',
      _scopedQuery.where('actif', isEqualTo: true),
    );
    var collection = snapshot.docs
        .map((snap) {
          return Site.fromJson(snap.data() as Map<String, dynamic>);
        })
        .toList()
        .where((element) {
          return (element.supervisor?.UID == supervisor.UID ||
              element.supervisor_2?.UID == supervisor.UID);
        })
        .toList();

    return collection;
  }

  Future<List<Site>> allAssignedToSupervisor(Supervisor supervisor) async {
    var snapshot = await TenantScope.getQuery(
      'SiteService.allAssignedToSupervisor',
      _scopedQuery.where('actif', isEqualTo: true),
    );

    return snapshot.docs.map((snap) {
      return Site.fromJson(snap.data() as Map<String, dynamic>);
    }).where((site) {
      return site.supervisor?.UID == supervisor.UID ||
          site.supervisor_2?.UID == supervisor.UID;
    }).toList();
  }

  Future<void> migrateSupervisorSites({
    required Supervisor targetSupervisor,
    required List<SiteSupervisorMigration> migrations,
  }) async {
    if (migrations.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    final supervisorData = targetSupervisor.toJson();
    final updatesBySite = <String, Map<String, dynamic>>{};

    for (final migration in migrations) {
      updatesBySite.putIfAbsent(
        migration.site.UID,
        () => <String, dynamic>{},
      )[migration.slot.firestoreField] = supervisorData;
    }

    for (final entry in updatesBySite.entries) {
      batch.update(_collectionReference.doc(entry.key), entry.value);
    }

    await batch.commit();
  }

  Future<List<Site>> allByZone(Zone zone) async {
    var snapshot = await TenantScope.getQuery(
      'SiteService.allByZone',
      _scopedQuery
          .where('zone.codeZone', isEqualTo: zone.codeZone)
          .where('actif', isEqualTo: true),
    );
    var collection = snapshot.docs.map((snap) {
      return Site.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();

    return collection;
  }

  Future<void> delete(Site site) async {
    return _collectionReference.doc(site.UID).delete();
  }

  Future<Site?> one(uid) async {
    var dataSnapshot = await _collectionReference.doc(uid).get();
    final rawData = dataSnapshot.data();
    if (rawData == null) return null;

    final data = jsonDecode(jsonEncode(rawData)) as Map<String, dynamic>;
    final site = Site.fromJson(data);
    if (!TenantScope.matchesTenant(site.tenantId) ||
        !DepartmentScope.matchesSite(site)) {
      return null;
    }
    return site;
  }

  Future<void> update(Site site) async {
    try {
      TenantScope.applyTenantIdForWrite(site);
      _requireSiteWriteAccess(site);
      await _collectionReference.doc(site.UID).update(site.toJson());
    } catch (e) {
      print("Erreur lors de la mise à jour du site : $e");
    }
  }

  Future<void> saveToken(String? token, String UID) async {
    await _collectionReference.doc(UID).update({'token': token});
  }

  Future<void> sos(Site site) {
    _requireSiteWriteAccess(site);
    site.sos = true;
    return _collectionReference.doc(site.UID).update(site.toJson());
  }

  Future<void> stopSos(Site site) {
    _requireSiteWriteAccess(site);
    site.sos = false;
    return _collectionReference.doc(site.UID).update(site.toJson());
  }

  void _requireSiteWriteAccess(Site site) {
    if (!DepartmentScope.matchesSite(site)) {
      throw StateError('Write outside the active site department scope.');
    }
  }
}
