import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model.dart';
import 'authentication.dart';

class ManagerService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Managers");
  Future<User?> add(Manager manager, password) async {
    var user = await AuthService().createUserWithEmail(manager.email, password);
    if (user != null) {
      manager.UID = user.uid;
      _collectionReference.doc(manager.UID).set(manager.toJson());

      //database.child(user.uid).set(supervisor.toJson());
    }
    return user;
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<List<Manager>> allFuture() async {
    var snpshot = await _collectionReference.get();
    List<Manager> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Manager.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<void> init() async {
    var snpshot = await _collectionReference.get();
    List<Manager> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Manager.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList()
        .where((element) => element.email == "manager@spas.com")
        .toList();
    if (data.isEmpty) {
      add(
          Manager(
              poste: "",
              UID: "",
              email: "manager@spas.com",
              phone: "",
              firstName: "",
              lastName: "",
              token: "",
              role: ''),
          "managerSpas@2023");
      AuthService().logOut();
    }
  }

  Future<Manager?> one(uid) async {
    try {
      var dataSnapshot = await _collectionReference.doc(uid).get();
      var data = jsonEncode(dataSnapshot.data());
      return Manager.fromJson(jsonDecode(data));
    } catch (error) {
      return null;
    }
  }

  Future<void> update(Manager manager) {
    return _collectionReference.doc(manager.UID).update(manager.toJson());
  }

  Future<void> saveToken(String? token, String UID) {
    return _collectionReference.doc(UID).update({'token': token});
  }

  Future<void> delete(Manager manager) async {
    return _collectionReference.doc(manager.UID).delete();
  }
}
