import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model.dart';
import 'tenant_scope.dart';

class PointingSiteService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("sitePointings");
  Future<void> add(PointingSite point) async {
    try {
      TenantScope.applyTenantIdForWrite(point);
      // Utiliser un ID unique basé sur le superviseur, site et date
      String child =
          "${point.supervisor?.UID}_${point.site.UID}_${point.date.year}-${point.date.month}-${point.date.day}-${point.date.hour}";
      await _collectionReference.doc(child).set(point.toJson());
      print("Pointage enregistré avec succès");
    } catch (e) {
      print(e);
    }
  }

  Stream<QuerySnapshot> all() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return TenantScope.watchQuery(
      'PointingSiteService.all',
      TenantScope.applyToQuery(_collectionReference)
          .where('datetimestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('datetimestamp', isLessThan: endOfDay),
    );
  }

  Stream<QuerySnapshot> allBySupervisor({required Supervisor supervisor}) {
    return TenantScope.watchQuery(
      'PointingSiteService.allBySupervisor',
      TenantScope.applyToQuery(_collectionReference)
          .where('supervisor.UID', isEqualTo: supervisor.UID),
    );
  }

  //Get For today made By BG
  Stream<QuerySnapshot> allTodayBySupervisor({required Supervisor supervisor}) {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return TenantScope.watchQuery(
      'PointingSiteService.allTodayBySupervisor',
      TenantScope.applyToQuery(_collectionReference)
          .where('supervisor.UID', isEqualTo: supervisor.UID)
          .where('datetimestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('datetimestamp', isLessThan: endOfDay),
    );
  }

  // Nouvelle méthode avec filtre de date personnalisé
  Stream<QuerySnapshot> allBySupervisorWithDateFilter({
    required Supervisor supervisor,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return TenantScope.watchQuery(
      'PointingSiteService.allBySupervisorWithDateFilter',
      TenantScope.applyToQuery(_collectionReference)
          .where('supervisor.UID', isEqualTo: supervisor.UID)
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate)
          .orderBy('datetimestamp', descending: true),
    );
  }

  // Méthode optimisée pour obtenir les statistiques directement depuis Firebase
  Stream<QuerySnapshot> getPointingStatsBySupervisor({
    required Supervisor supervisor,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // if special, get for the month of the current date
    if (supervisor.isSpecial) {
      var now = DateTime.now();
      startDate = DateTime(now.year, now.month, 1);
      endDate = startDate.add(const Duration(days: 31));
    }
    return TenantScope.watchQuery(
      'PointingSiteService.getPointingStatsBySupervisor',
      TenantScope.applyToQuery(_collectionReference)
          .where('supervisor.UID', isEqualTo: supervisor.UID)
          .where('datetimestamp', isGreaterThanOrEqualTo: startDate)
          .where('datetimestamp', isLessThan: endDate),
    );
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingSite point) {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.site.UID}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(point.toJson());
  }

  Future<List<PointingSite>> allFuture() async {
    try {
      var snpshot = await TenantScope.getQuery(
        'PointingSiteService.allFuture',
        TenantScope.applyToQuery(_collectionReference),
      );
      List<PointingSite> data = snpshot.docs
          .map((QueryDocumentSnapshot e) =>
              PointingSite.fromJson(jsonDecode(jsonEncode(e.data()))))
          .toList();
      return data;
    } catch (e) {
      print(e);
      return [];
    }
  }

  /// Count documents for a supervisor on a given day (date = DateTime with any time)
  Future<int?> countForSupervisorOnDate(
      String supervisorUID, DateTime date) async {
    try {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      final query = TenantScope.applyToQuery(_collectionReference)
          .where(Filter.or(Filter('supervisor.UID', isEqualTo: supervisorUID),
              Filter('supervisor_2.UID', isEqualTo: supervisorUID)))
          .where('datetimestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('datetimestamp', isLessThan: Timestamp.fromDate(end));
      // Aggregation count() — server computes the count, returns a single int.
      final agg = await TenantScope.getCount(
        'PointingSiteService.countForSupervisorOnDate',
        query.count(),
      );
      return agg.count;
    } catch (exception) {
      print(exception);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> nbSiteCheckedToDAyBySupervisor(
      Supervisor supervisor) async {
    try {
      DateTime _debut = DateTime.now().subtract(const Duration(days: 1));
      DateTime _fin = DateTime.now().add(const Duration(days: 1));
      var snapshot = await TenantScope.getQuery(
        'PointingSiteService.nbSiteCheckedToDAyBySupervisor',
        TenantScope.applyToQuery(_collectionReference),
      );
      var collection = snapshot.docs.map((snap) {
        return PointingSite.fromJson(jsonDecode(jsonEncode(snap.data())));
      }).toList();
      collection = collection
          .where((element) =>
              (element.date.isAfter(_debut.subtract(const Duration(days: 1))) &&
                  element.date.isBefore(_fin.add(const Duration(days: 1)))))
          .toList();
      List<Map<String, dynamic>> pointages = [];
      List<Site> sites = collection.map((e) => e.site).toSet().toList();
      //elimination des doublons
      var temps = [];
      for (Site site in sites) {
        temps.add(site);
        sites.removeWhere((element) => element.UID == site.UID);
      }
      for (Site site in temps) {
        var Listpointage = collection
            .where((element) => element.site.UID == site.UID)
            .toList();

        pointages.add({"site": site, "pointages": Listpointage});
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
    } catch (e) {
      print("Catch");
      debugPrint("Err == $e");
      return [];
    }
  }
}
