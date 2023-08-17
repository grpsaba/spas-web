import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../const.dart';
import '../model.dart';

class ProfilService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Profils");

  Future<void> add(Profil profil) async {
    profil.modules = AppConstants.moduleList;
    _collectionReference.doc(profil.name).set(profil.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<void> delete(Profil profil) async {
    return _collectionReference.doc(profil.name).delete();
  }

  Future<Profil?> one(name) async {
    var dataSnapshot = await _collectionReference.doc(name).get();
    var data = jsonEncode(dataSnapshot.data());
    return Profil.fromJson(jsonDecode(data));
  }

  Future<void> update(Profil profil) {
    return _collectionReference.doc(profil.name).update(profil.toJson());
  }
}
