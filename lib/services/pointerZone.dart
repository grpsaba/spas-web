import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class PointingZoneService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("zonePointings");
  Future<void> add(PointingZone point) async {
    String child =
        "${point.site.UID} ${point.date.year}-${point.date.month}-${point.date.day}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }
  Stream<QuerySnapshot> allByZoneMember(ZoneMember zoneMember) {
    return _collectionReference.where('zoneMember.UID',isEqualTo: zoneMember.UID).snapshots();
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingZone point) {
    String child =
        "${point.site.UID}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(point.toJson());
  }

  Future<List<PointingZone>> allFuture() async {
    var snpshot = await _collectionReference.get();
    List<PointingZone> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            PointingZone.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<List<Map<String, dynamic>>> nbSiteCheckedToDAyByZone(Zone zone) async {
    //DateTime _debut = DateTime.now().subtract(const Duration(days: 1));
    // DateTime _fin = DateTime.now().add(const Duration(days: 1));
    var snapshot = await _collectionReference.get();
    var collection = snapshot.docs.map((snap) {
      return PointingZone.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();
    collection = collection.where((element) => element.isToday()).toList();
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

      return site.zone == zone;
    }).toList();
    return pointages;
  }
}
