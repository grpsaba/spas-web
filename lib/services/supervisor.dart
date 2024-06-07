import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model.dart';
import 'authentication.dart';

class SupervisorService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Supervisors");
  Future<User?> add(Supervisor supervisor, password) async {
    var user =
        await AuthService().createUserWithEmail(supervisor.email, password);
    if (user != null) {
      supervisor.UID = user.uid;
      _collectionReference.doc(supervisor.UID).set(supervisor.toJson());

      //database.child(user.uid).set(supervisor.toJson());
    }
    return user;
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }
  Future<List<Supervisor>> allActifFuture(String filter) async {
    var snpshot = await _collectionReference.where('actif',isEqualTo: true).get();
    List<Supervisor> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
        Supervisor.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data.where((e) => e.firstName.contains(filter)).toList();
  }
  Future<List<Supervisor>> allFuture() async {
    var snpshot = await _collectionReference.get();
    List<Supervisor> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Supervisor.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<Supervisor?> one(uid) async {
    try {
      var dataSnapshot = await _collectionReference.doc(uid).get();
      var data = jsonEncode(dataSnapshot.data());
      return Supervisor.fromJson(jsonDecode(data));
    } catch (error) {
      return null;
    }
  }

  Future<void> update(Supervisor supervisor) {
    return _collectionReference.doc(supervisor.UID).update(supervisor.toJson());
  }

  Future<void> saveToken(String? token, String UID) {
    return _collectionReference.doc(UID).update({'token': token});
  }

  Future<void> delete(Supervisor supervisor) async {
    return _collectionReference.doc(supervisor.UID).delete();
  }
}
