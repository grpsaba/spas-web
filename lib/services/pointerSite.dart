import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class PointingSiteService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("sitePointings");
  Future<void> add(PointingSite point) async {
    String child =
        "${point.site.UID} ${point.date.year}-${point.date.month}-${point.date.day}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }
  Stream<QuerySnapshot> allBySupervisor({required Supervisor supervisor}) {
    return _collectionReference.where('supervisor.UID',isEqualTo: supervisor.UID).snapshots();
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingSite point) {
    String child =
        "${point.site.UID}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(point.toJson());
  }

  Future<List<PointingSite>> allFuture() async {
    var snpshot = await _collectionReference.get();
    List<PointingSite> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            PointingSite.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<List<Map<String, dynamic>>> nbSiteCheckedToDAyBySupervisor(
      Supervisor supervisor) async {
    DateTime _debut = DateTime.now().subtract(const Duration(days: 1));
    DateTime _fin = DateTime.now().add(const Duration(days: 1));
    var snapshot = await _collectionReference.get();
    var collection = snapshot.docs.map((snap) {
      return PointingSite.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();
    collection = collection
        .where((element) =>
            (element.date.isAfter(_debut.subtract(const Duration(days: 1))) &&
                element.date.isBefore(_fin.add(const Duration(days: 1)))))
        .toList();
    List<Map<String, dynamic>> pointages = [];
    List<Site>? sites = collection.map((e) => e.site).toSet().toList();
    //elimination des doublons
    var temps = [];
    for (Site site in sites ?? []) {
      temps.add(site);
      sites.removeWhere((element) => element.UID == site.UID);
    }
    for (Site site in temps) {
      var Listpointage =
          collection.where((element) => element.site.UID == site.UID).toList();

      pointages.add({"site": site, "pointages": Listpointage ?? []});
    }
    pointages = pointages.where((element) {
      Site site = element["site"];
      if (site.supervisor_2 != null) {
        return site.supervisor?.UID == supervisor.UID ||
            site.supervisor_2?.UID == supervisor.UID;
      } else {
        return site.supervisor?.UID == supervisor.UID;
      }
    }).toList();
    return pointages;
  }
}
