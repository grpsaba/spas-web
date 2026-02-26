import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'pointage_weighted_engine.dart';

class PointingZoneService {
  final CollectionReference<Map<String, dynamic>> _collectionReference =
      FirebaseFirestore.instance.collection("zonePointings");
  Future<void> add(PointingZone point) async {
    final period = PointageWeightedEngine.classifyPeriod(point.date);
    final operationalDay = PointageWeightedEngine.operationalDay(point.date);
    final siteType =
        PointageWeightedEngine.normalizePointingType(point.site.pointingType);

    final data = Map<String, dynamic>.from(point.toJson());
    data['period'] =
        period == PointagePeriod.jour ? SitePointingType.jour : SitePointingType.nuit;
    data['operationalDay'] = operationalDay;
    data['pointingTypeSnapshot'] = siteType;

    return _collectionReference.doc().set(data);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> all() {
    return _collectionReference.snapshots();
  }

  Stream<List<PointingZone>> allByZoneMember(
      {required ZoneMember zoneMember, DateTime? month}) {
    final range = _monthRange(month ?? DateTime.now());
    return _collectionReference
        .where('zoneMember.UID', isEqualTo: zoneMember.UID)
        .where('datetimestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
        .where('datetimestamp', isLessThan: Timestamp.fromDate(range.end))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((e) => PointingZone.fromJson(e.data()))
            .toList());
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingZone point) {
    final period = PointageWeightedEngine.classifyPeriod(point.date);
    final operationalDay = PointageWeightedEngine.operationalDay(point.date);
    final siteType =
        PointageWeightedEngine.normalizePointingType(point.site.pointingType);

    final data = Map<String, dynamic>.from(point.toJson());
    data['period'] =
        period == PointagePeriod.jour ? SitePointingType.jour : SitePointingType.nuit;
    data['operationalDay'] = operationalDay;
    data['pointingTypeSnapshot'] = siteType;

    final child =
        "${point.site.UID}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(data);
  }

  Future<List<PointingZone>> allFuture() async {
    var snpshot = await _collectionReference.get();
    List<PointingZone> data = snpshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> e) =>
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
    List<Site> sites = collection.map((e) => e.site).toSet().toList();
    //elimination des doublons
    var temps = [];
    for (Site site in sites) {
      temps.add(site);
      sites.removeWhere((element) => element.UID == site.UID);
    }
    for (Site site in temps) {
      var Listpointage =
          collection.where((element) => element.site.UID == site.UID).toList();

      pointages.add({"site": site, "pointages": Listpointage});
    }
    pointages = pointages.where((element) {
      Site site = element["site"];

      return site.zone == zone;
    }).toList();
    return pointages;
  }
}

class _MonthRange {
  _MonthRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

_MonthRange _monthRange(DateTime month) {
  final start = DateTime(month.year, month.month, 1);
  final end = month.month == 12
      ? DateTime(month.year + 1, 1, 1)
      : DateTime(month.year, month.month + 1, 1);
  return _MonthRange(start: start, end: end);
}
