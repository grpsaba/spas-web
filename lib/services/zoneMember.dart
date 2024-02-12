import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model.dart';
import 'authentication.dart';

class ZoneMemberService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("ZoneMembers");

  Future<User?> add(ZoneMember zoneMember, password) async {
    var user =
        await AuthService().createUserWithEmail(zoneMember.email, password);
    if (user != null) {
      zoneMember.UID = user.uid;
      _collectionReference
          .doc(user.uid)
          .set(zoneMember.toJson())
          .onError((error, stackTrace) => print(error));
    }
    return user;
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<List<ZoneMember>> allAsModel() async {
    var snapshot = await _collectionReference.get();
    var collection = snapshot.docs.map((snap) {
      return ZoneMember.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();

    return collection;
  }

  Future<void> delete(ZoneMember zoneMember) async {
    return _collectionReference.doc(zoneMember.UID).delete();
  }

  Future<ZoneMember?> one(uid) async {
    var dataSnapshot = await _collectionReference.doc(uid).get();
    var data = jsonEncode(dataSnapshot.data());
    return ZoneMember.fromJson(jsonDecode(data));
  }

  Future<void> update(ZoneMember zoneMember) {
    return _collectionReference.doc(zoneMember.UID).update(zoneMember.toJson());
  }

  Future<void> saveToken(String? token, String UID) {
    return _collectionReference.doc(UID).update({'token': token});
  }
}
