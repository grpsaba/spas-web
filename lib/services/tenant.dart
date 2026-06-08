import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class TenantService {
  TenantService({FirebaseFirestore? firestore})
      : _collectionReference =
            (firestore ?? FirebaseFirestore.instance).collection('tenants');

  final CollectionReference _collectionReference;

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<List<Tenant>> allActive() async {
    final snapshot = await _collectionReference
        .where('active', isEqualTo: true)
        .orderBy('label')
        .get();

    return snapshot.docs.map(_mapSnapshotToTenant).toList();
  }

  Future<Tenant?> one(String tenantId) async {
    final snapshot = await _collectionReference.doc(tenantId).get();
    final data = _asMap(snapshot.data());
    if (data == null) return null;
    return Tenant.fromJson(data);
  }

  Tenant _mapSnapshotToTenant(QueryDocumentSnapshot snapshot) {
    final data = _asMap(snapshot.data()) ?? <String, dynamic>{};
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
