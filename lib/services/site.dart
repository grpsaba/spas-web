import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/pointage_weighted_engine.dart';

import 'authentication.dart';

class SiteService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Sites");

  Future<User?> add(Site site, password) async {
    site.pointingType =
        PointageWeightedEngine.normalizePointingType(site.pointingType);

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

  Stream<QuerySnapshot> allSos() {
    return _collectionReference
        .where(Filter.and(
            Filter('sos', isEqualTo: true), Filter('actif', isEqualTo: true)))
        .snapshots();
  }
  //  await _collectionReference.where('actif', isEqualTo: true,)
  //       .where(Filter.(Filter('supervisor.UID', isEqualTo: supervisor.UID),
  //        Filter('supervisor_2.UID', isEqualTo: supervisor.UID))).count().get();

  Stream<QuerySnapshot> allActifSite() {
    return _collectionReference.where("actif", isEqualTo: true).snapshots();
  }

  Future<List<Site>> allAsModel() async {
  try{
      var snapshot =
        await _collectionReference.where("actif", isEqualTo: true).get();
    var collection = snapshot.docs.map((snap) {
      return Site.fromJson(snap.data() as Map<String, dynamic>);
    }).toList();

    return collection;
  }catch(e){
    print("Erreur lors de la récupération des sites : $e");
    return [];
  }}

  Future<List<Site>> allActifAsModel() async {
    var snapshot =
        await _collectionReference.where("actif", isEqualTo: true).get();
    var collection = snapshot.docs.map((snap) {
      return Site.fromJson(snap.data() as Map<String, dynamic>);
    }).toList();

    return collection;
  }

  Future<List<Site>> allSitesByZone(Zone zone) async {
    var s1 = await _collectionReference
        .where("zone.codeZone", isEqualTo: zone.codeZone)
        .where("actif", isEqualTo: true)
        .get();

    var s1Future = s1.docs.map((snap) {
      return Site.fromJson(snap.data() as Map<String, dynamic>);
    });

    return s1Future.toList();
  }

  Future<int?> allSitesCountByZone(Zone zone) async {
    var s1 = await _collectionReference
        .where("zone.codeZone", isEqualTo: zone.codeZone)
        .where("actif", isEqualTo: true)
        .count()
        .get();

    return s1.count;
  }

  Future<int?> allSitesCountBySupervisor(Supervisor supervisor) async {
    if (supervisor.isSpecial && supervisor.zone != null) {
      return await allSitesCountByZone(supervisor.zone!);
    }
    var snapshot = await _collectionReference
        .where(
          'actif',
          isEqualTo: true,
        )
        .where(Filter.or(Filter('supervisor.UID', isEqualTo: supervisor.UID),
            Filter('supervisor_2.UID', isEqualTo: supervisor.UID)))
        .count()
        .get();

    return snapshot.count;
  }

  Future<List<Site>> allBySupervisor(Supervisor supervisor) async {
    if (supervisor.isSpecial && supervisor.zone != null) {
      return await allSitesByZone(supervisor.zone!);
    }
    var snapshot =
        await _collectionReference.where('actif', isEqualTo: true).get();
    var collection = snapshot.docs
        .map((snap) {
          return Site.fromJson(snap.data() as Map<String, dynamic>);
        })
        .toList()
        .where((element) {
          return (element.supervisor?.UID == supervisor.UID ||
              element.supervisor_2?.UID == supervisor.UID);
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
      return Site.fromJson(snap.data() as Map<String, dynamic>);
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

  Future<void> update(Site site) async {
    site.pointingType =
        PointageWeightedEngine.normalizePointingType(site.pointingType);

    try {
      await _collectionReference.doc(site.UID).update(site.toJson());
    } catch (e) {
      print("Erreur lors de la mise à jour du site : $e");
    }
  }

  Future<void> saveToken(String? token, String UID) async {
    await _collectionReference.doc(UID).update({'token': token});
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
