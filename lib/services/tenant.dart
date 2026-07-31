import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model.dart';

class TenantService {
  TenantService({FirebaseFirestore? firestore})
      : _collectionReference =
            (firestore ?? FirebaseFirestore.instance).collection('tenants');

  final CollectionReference _collectionReference;

  Stream<QuerySnapshot> all() {
    return _collectionReference.orderBy('label').snapshots();
  }

  Stream<List<Tenant>> watchPointageModeTenants({
    required bool includeAll,
    required String tenantId,
  }) {
    if (includeAll) {
      return _collectionReference.orderBy('label').snapshots().map(
            (snapshot) => snapshot.docs.map(_mapSnapshotToTenant).toList(),
          );
    }

    final id = tenantId.trim().toLowerCase();
    if (id.isEmpty) return Stream.value(<Tenant>[]);

    return _collectionReference.doc(id).snapshots().map((snapshot) {
      final tenant = _mapDocumentToTenant(snapshot);
      return tenant == null ? <Tenant>[] : <Tenant>[tenant];
    });
  }

  Future<List<Tenant>> allActive() async {
try{    final snapshot = await _collectionReference
        .where('active', isEqualTo: true)
        .orderBy('label')
        .get();
    List<Tenant> tenants = snapshot.docs.map(_mapSnapshotToTenant).toList();
    return tenants;}
    catch(e){
      debugPrint('Error fetching active tenants: $e');
      return [];
    }
  }

  Future<Tenant?> one(String tenantId) async {
    final snapshot = await _collectionReference.doc(tenantId).get();
    final data = _asMap(snapshot.data());
    if (data == null) return null;
    return Tenant.fromJson(data);
  }

  Future<void> save(Tenant tenant) async {
    final id = tenant.id.trim().toLowerCase();
    if (id.isEmpty) {
      throw ArgumentError('Le code pays est obligatoire.');
    }

    await _collectionReference.doc(id).set({
      ...tenant.toJson(),
      'id': id,
    });
  }

  Future<void> updatePointageModes({
    required String tenantId,
    required String pointageMode,
    required String zoneChiefPointageMode,
  }) async {
    final id = tenantId.trim().toLowerCase();
    if (id.isEmpty) {
      throw ArgumentError('Le code pays est obligatoire.');
    }

    await _collectionReference.doc(id).update({
      'pointageMode': TenantPointageMode.normalize(pointageMode),
      'zoneChiefPointageMode':
          TenantPointageMode.normalize(zoneChiefPointageMode),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setActive(Tenant tenant, bool active) async {
    final id = tenant.id.trim().toLowerCase();
    if (id.isEmpty) {
      throw ArgumentError('Le code pays est obligatoire.');
    }

    if (!active) {
      final usage = await usageCount(id);
      if (usage.total > 0) {
        throw StateError(
          'Impossible de desactiver ce pays: ${usage.managers} manager(s) et ${usage.supervisors} superviseur(s) y sont rattaches.',
        );
      }
    }

    await _collectionReference.doc(id).update({'active': active});
  }

  Future<TenantUsageCount> usageCount(String tenantId) async {
    final id = tenantId.trim().toLowerCase();
    if (id.isEmpty) return const TenantUsageCount();

    final firestore = _collectionReference.firestore;
    final managers = await firestore
        .collection('Managers')
        .where('tenantId', isEqualTo: id)
        .count()
        .get();
    final supervisors = await firestore
        .collection('Supervisors')
        .where('tenantId', isEqualTo: id)
        .count()
        .get();

    return TenantUsageCount(
      managers: managers.count ?? 0,
      supervisors: supervisors.count ?? 0,
    );
  }

  Tenant _mapSnapshotToTenant(QueryDocumentSnapshot snapshot) {
    final data = _asMap(snapshot.data()) ?? <String, dynamic>{};
    return Tenant.fromJson({
      'id': snapshot.id,
      ...data,
    });
  }

  Tenant? _mapDocumentToTenant(DocumentSnapshot snapshot) {
    final data = _asMap(snapshot.data());
    if (data == null) return null;
    return Tenant.fromJson({
      'id': snapshot.id,
      ...data,
    });
  }

  Map<String, dynamic>? _asMap(dynamic rawData) {
    if (rawData == null) return null;
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is Map) return Map<String, dynamic>.from(rawData);
    return null;
  }
}

class TenantUsageCount {
  final int managers;
  final int supervisors;

  const TenantUsageCount({
    this.managers = 0,
    this.supervisors = 0,
  });

  int get total => managers + supervisors;
}
