import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class DepartmentService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("departments");

  Future<void> add(Department department) async {
    _collectionReference.doc(department.label).set(department.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<void> delete(Department department) async {
    return _collectionReference.doc(department.label).delete();
  }

  Future<Department> one(label) async {
    var dataSnapshot = await _collectionReference.doc(label).get();
    var data = jsonEncode(dataSnapshot.data());
    return Department.fromJson(jsonDecode(data));
  }

  Future<void> update(Department department) {
    return _collectionReference
        .doc(department.label)
        .update(department.toJson());
  }
}
