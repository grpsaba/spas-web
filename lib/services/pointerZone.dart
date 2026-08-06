import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class PointingZoneService {
  final CollectionReference<Map<String, dynamic>> _collectionReference =
      FirebaseFirestore.instance.collection("zonePointings");

  Query<Map<String, dynamic>> get _scopedQuery =>
      DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(PointingZone point) async {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.site.UID} ${point.date.year}-${point.date.month}-${point.date.day}";
    dynamic data = point.toJson();
    print(data);
    return _collectionReference.doc(child).set(data);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> all() {
    return TenantScope.watchQuery(
      'PointingZoneService.all',
      _scopedQuery,
    );
  }

  Stream<List<PointingZone>> allByZoneMember(
      {required ZoneMember zoneMember, DateTime? month}) {
    final range = _monthRange(month ?? DateTime.now());
    return TenantScope.watchQuery(
      'PointingZoneService.allByZoneMember',
      _scopedQuery
          .where('zoneMember.UID', isEqualTo: zoneMember.UID)
          .where('datetimestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where('datetimestamp', isLessThan: Timestamp.fromDate(range.end)),
    ).map((snapshot) => snapshot.docs
        .map((e) => PointingZone.fromJson(e.data() as Map<String, dynamic>))
        .toList());
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingZone point) {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.site.UID}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(point.toJson());
  }

  Future<List<PointingZone>> allFuture() async {
    var snpshot = await TenantScope.getQuery(
      'PointingZoneService.allFuture',
      _scopedQuery,
    );
    List<PointingZone> data = snpshot.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> e) =>
            PointingZone.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<List<Map<String, dynamic>>> nbSiteCheckedToDAyByZone(Zone zone) async {
    //DateTime _debut = DateTime.now().subtract(const Duration(days: 1));
    // DateTime _fin = DateTime.now().add(const Duration(days: 1));
    var snapshot = await TenantScope.getQuery(
      'PointingZoneService.nbSiteCheckedToDAyByZone',
      _scopedQuery,
    );
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
