import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class CategorieToolService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("categorieTools");

  Future<void> add(CategorieTool tool) async {
    _collectionReference.doc(tool.label).set(tool.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<void> delete(CategorieTool tool) async {
    return _collectionReference.doc(tool.label).delete();
  }

  Future<CategorieTool> one(label) async {
    var dataSnapshot = await _collectionReference.doc(label).get();
    var data = jsonEncode(dataSnapshot.data());
    return CategorieTool.fromJson(jsonDecode(data));
  }

  Future<void> update(CategorieTool tool) {
    return _collectionReference.doc(tool.label).update(tool.toJson());
  }
}
