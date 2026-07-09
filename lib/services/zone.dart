import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'tenant_scope.dart';

class ZoneService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Zones");

  Future<void> add(Zone zone) async {
    TenantScope.applyTenantIdForWrite(zone);
    await _collectionReference.doc(zone.codeZone).set(zone.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'ZoneService.all',
      TenantScope.applyToQuery(_collectionReference),
    );
  }

  Future<List<Zone>> allAsModel() async {
    var snapshot = await TenantScope.getQuery(
      'ZoneService.allAsModel',
      TenantScope.applyToQuery(_collectionReference),
    );
    var collection = snapshot.docs.map((snap) {
      return Zone.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();

    return collection;
  }

  Future<void> delete(Zone zone) async {
    return _collectionReference.doc(zone.codeZone).delete();
  }

  Future<Zone?> one(code) async {
    var dataSnapshot = await _collectionReference.doc(code).get();
    var data = jsonEncode(dataSnapshot.data());
    return Zone.fromJson(jsonDecode(data));
  }

  Future<void> update(Zone zone) {
    TenantScope.applyTenantIdForWrite(zone);
    return _collectionReference.doc(zone.codeZone).update(zone.toJson());
  }
}
