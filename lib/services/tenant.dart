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
    try {
      final snapshot = await _collectionReference
          .where('active', isEqualTo: true)
          .orderBy('label')
          .get();
      List<Tenant> tenants = snapshot.docs.map(_mapSnapshotToTenant).toList();
      return tenants;
    } catch (e) {
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

  Future<void> save(Tenant tenant, {Tenant? previous}) async {
    final id = tenant.id.trim().toLowerCase();
    if (id.isEmpty) {
      throw ArgumentError('Le code pays est obligatoire.');
    }

    final data = tenant.toJson()..['id'] = id;
    if (previous == null) {
      await _collectionReference.doc(id).set(data);
      return;
    }
    final previousData = previous.toJson();
    data.removeWhere((key, value) => previousData[key] == value);
    if (data.isEmpty) return;
    final reference = _collectionReference.doc(id);
    await reference.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final modes = pointageModeChanges(
        current: _asMap(snapshot.data()),
        pointageMode: data['pointageMode'] as String?,
        zoneChiefPointageMode: data['zoneChiefPointageMode'] as String?,
      );
      transaction.update(reference, {
        ...data,
        ...modes,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updatePointageModes({
    required String tenantId,
    String? pointageMode,
    String? zoneChiefPointageMode,
  }) async {
    final id = tenantId.trim().toLowerCase();
    if (id.isEmpty) {
      throw ArgumentError('Le code pays est obligatoire.');
    }

    if (pointageMode == null && zoneChiefPointageMode == null) return;
    final reference = _collectionReference.doc(id);
    await reference.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      transaction.update(reference, {
        ...pointageModeChanges(
          current: _asMap(snapshot.data()),
          pointageMode: pointageMode,
          zoneChiefPointageMode: zoneChiefPointageMode,
        ),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Only changed roles are written, preserving concurrent edits to other roles.
  static Map<String, dynamic> pointageModeChanges({
    Map<String, dynamic>? current,
    String? pointageMode,
    String? zoneChiefPointageMode,
  }) =>
      {
        if (pointageMode != null)
          'pointageMode': TenantPointageMode.normalize(pointageMode),
        if (zoneChiefPointageMode != null)
          'zoneChiefPointageMode':
              TenantPointageMode.normalize(zoneChiefPointageMode),
        // Freeze the old inherited value before changing the supervisor mode.
        // Otherwise legacy countries without an explicit chief field change both.
        if (pointageMode != null &&
            zoneChiefPointageMode == null &&
            current != null &&
            current['zoneChiefPointageMode'] == null)
          'zoneChiefPointageMode':
              Tenant.fromJson(current).zoneChiefPointageMode,
      };

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
