import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';


import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class LocationService {
  final CollectionReference _collectionReference =
  FirebaseFirestore.instance.collection("locationTracker");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );
  Future<void> add(SuperviseurLocaion location) async {
    TenantScope.applyTenantIdForWrite(location);
    String docID = '';
    if(location.supervisor!=null){
      if(location.supervisor!.tracking==true){
        //docID = '${location.supervisor?.UID??''}${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().millisecond}${DateTime.now().microsecond}';
        docID = location.supervisor?.UID??'';
        _collectionReference.doc(docID).set(location.toJson());
      }

    }

  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'LocationService.all',
      _scopedQuery,
    );
  }

  Future<List<SuperviseurLocaion>> allFuture() async {
    var snpshot = await TenantScope.getQuery(
      'LocationService.allFuture',
      _scopedQuery,
    );
    List<SuperviseurLocaion> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
        SuperviseurLocaion.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<List<SuperviseurLocaion>> allBySupervisor(uid) async {
    var snapshot = await TenantScope.getQuery(
      'LocationService.allBySupervisor',
      _scopedQuery,
    );
    var collection = snapshot.docs
        .map((snap) {
      return SuperviseurLocaion.fromJson(jsonDecode(jsonEncode(snap.data())));
    })
        .toList()
        .where((element) {

      return element.supervisor?.UID == uid;

    })
        .toList();
    return collection;
  }



  Future<SuperviseurLocaion> one(code) async {
    var snapshot = await _collectionReference.doc(code).get();
    var data = jsonDecode(jsonEncode(snapshot.data()));
    if (data is! Map<String, dynamic> ||
        !TenantScope.matchesTenant(tenantIdFromJson(data)) ||
        !DepartmentScope.matchesDepartment(departmentIdFromJson(data))) {
      throw StateError(
        'Location outside the active tenant or department scope.',
      );
    }
    var location = SuperviseurLocaion.fromJson(data);
    return location;
  }

  Future<void> delete(SuperviseurLocaion location) async {
    String docID='';
    if(location.supervisor!.tracking == true){
      docID = '${location.supervisor?.UID??''}${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().millisecond}${DateTime.now().microsecond}';
    }else{
      docID = location.supervisor?.UID??'';
    }
    return _collectionReference.doc(docID).delete();
  }

  Future<void> update(SuperviseurLocaion location) {
    TenantScope.applyTenantIdForWrite(location);
    String docID='';
    if(location.supervisor!.tracking == true){
      docID = '${location.supervisor?.UID??''}${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().millisecond}${DateTime.now().microsecond}';
    }else{
      docID = location.supervisor?.UID??'';
    }
    return _collectionReference.doc(docID).update(location.toJson());
  }
}
