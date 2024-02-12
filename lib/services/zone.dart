import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class ZoneService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Zones");

  Future<void> add(Zone zone) async {
    _collectionReference
        .doc(zone.codeZone)
        .set(zone.toJson())
        .onError((error, stackTrace) => print(error));
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<List<Zone>> allAsModel() async {
    var snapshot = await _collectionReference.get();
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
    return _collectionReference.doc(zone.codeZone).update(zone.toJson());
  }
}
