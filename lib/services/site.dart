import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model.dart';
import 'authentication.dart';

class SiteService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Sites");

  Future<User?> add(Site site, password) async {
    var user = await AuthService().createUserWithEmail(site.email, password);
    if (user != null) {
      site.UID = user.uid;
      _collectionReference
          .doc(user.uid)
          .set(site.toJson())
          .onError((error, stackTrace) => print(error));
    }
    return user;
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Stream<QuerySnapshot> allActifSite() {
    return _collectionReference.where("actif", isEqualTo: true).snapshots();
  }

  Future<List<Site>> allAsModel() async {
    var snapshot =
        await _collectionReference.where("actif", isEqualTo: true).get();
    var collection = snapshot.docs.map((snap) {
      return Site.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();

    return collection;
  }

  Future<List<Site>> allActifAsModel() async {
    var snapshot =
        await _collectionReference.where("actif", isEqualTo: true).get();
    var collection = snapshot.docs.map((snap) {
      return Site.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();

    return collection;
  }

  Future<List<Site>> allBySupervisor(uid) async {
    var snapshot =
        await _collectionReference.where('actif', isEqualTo: true).get();
    var collection = snapshot.docs
        .map((snap) {
          return Site.fromJson(jsonDecode(jsonEncode(snap.data())));
        })
        .toList()
        .where((element) {
          return (element.supervisor?.UID == uid ||
              element.supervisor_2?.UID == uid);
        })
        .toList();

    return collection;
  }

  Future<List<Site>> allByZone(Zone zone) async {
    var snapshot = await _collectionReference
        .where('zone.codeZone', isEqualTo: zone.codeZone)
        .where('actif', isEqualTo: true)
        .get();
    var collection = snapshot.docs.map((snap) {
      return Site.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();

    return collection;
  }

  Future<void> delete(Site site) async {
    return _collectionReference.doc(site.UID).delete();
  }

  Future<Site?> one(uid) async {
    var dataSnapshot = await _collectionReference.doc(uid).get();
    var data = jsonEncode(dataSnapshot.data());
    return Site.fromJson(jsonDecode(data));
  }

  Future<void> update(Site site) {
    return _collectionReference.doc(site.UID).update(site.toJson());
  }

  Future<void> saveToken(String? token, String UID) {
    return _collectionReference.doc(UID).update({'token': token});
  }

  Future<void> sos(Site site) {
    site.sos = true;
    return _collectionReference.doc(site.UID).update(site.toJson());
  }

  Future<void> stopSos(Site site) {
    site.sos = false;
    return _collectionReference.doc(site.UID).update(site.toJson());
  }
}
