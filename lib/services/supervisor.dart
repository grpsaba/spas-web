import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import '../model.dart';
import 'authentication.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class SupervisorService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Supervisors");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<User?> add(Supervisor supervisor, password) async {
    TenantScope.applyTenantIdForWrite(supervisor);
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
    return TenantScope.watchQuery(
      'SupervisorService.all',
      _scopedQuery,
    );
  }

  Future<List<Supervisor>> allActifFuture(String filter) async {
    try {
      var snpshot = await TenantScope.getQuery(
        'SupervisorService.allActifFuture',
        _scopedQuery.where('actif', isEqualTo: true),
      );
      List<Supervisor> data = snpshot.docs
          .map((QueryDocumentSnapshot e) =>
              Supervisor.fromJson(jsonDecode(jsonEncode(e.data()))))
          .toList();
      return data.where((e) => e.firstName.contains(filter)).toList();
    } catch (e) {
      print("Catched");
      debugPrint("Error == $e");
      return [];
    }
  }

  Future<List<Supervisor>> allFuture() async {
    try {
      var snpshot = await TenantScope.getQuery(
        'SupervisorService.allFuture',
        _scopedQuery.where("actif", isEqualTo: true),
      );
      List<Supervisor> data = snpshot.docs
          .map((QueryDocumentSnapshot e) =>
              Supervisor.fromJson(e.data() as dynamic))
          .toList();
      return data; //.sublist(1,2);
    } catch (e) {
      print("Catch");
      debugPrint("Err == $e");
      return [];
    }
  }

  Future<Supervisor?> one(uid) async {
    try {
      var dataSnapshot = await _collectionReference.doc(uid).get();
      var data = jsonEncode(dataSnapshot.data());
      final json = jsonDecode(data) as Map<String, dynamic>;
      if (!TenantScope.matchesTenant(tenantIdFromJson(json)) ||
          !DepartmentScope.matchesDepartment(departmentIdFromJson(json))) {
        return null;
      }
      return Supervisor.fromJson(json);
    } catch (error) {
      return null;
    }
  }

  Future<void> update(Supervisor supervisor) {
    TenantScope.applyTenantIdForWrite(supervisor);
    return _collectionReference.doc(supervisor.UID).update(supervisor.toJson());
  }

  Future<void> saveToken(String? token, String UID) {
    return _collectionReference.doc(UID).update({'token': token});
  }

  Future<void> delete(Supervisor supervisor) async {
    return _collectionReference.doc(supervisor.UID).delete();
  }
}
