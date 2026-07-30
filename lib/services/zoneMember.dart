import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model.dart';
import 'authentication.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class ZoneMemberService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("ZoneMembers");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<User?> add(ZoneMember zoneMember, password) async {
    TenantScope.applyTenantIdForWrite(zoneMember);
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
    return TenantScope.watchQuery(
      'ZoneMemberService.all',
      _scopedQuery,
    );
  }

  Future<List<ZoneMember>> allAsModel() async {
    var snapshot = await TenantScope.getQuery(
      'ZoneMemberService.allAsModel',
      _scopedQuery,
    );
    var collection = snapshot.docs.map((snap) {
      return ZoneMember.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();

    return collection;
  }
  Future<List<ZoneMember>> allActifAsModel() async {
    var snapshot = await TenantScope.getQuery(
      'ZoneMemberService.allActifAsModel',
      _scopedQuery.where('actif', isEqualTo: true),
    );
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
    final json = jsonDecode(data) as Map<String, dynamic>;
    if (!TenantScope.matchesTenant(tenantIdFromJson(json)) ||
        !DepartmentScope.matchesDepartment(departmentIdFromJson(json))) {
      return null;
    }
    return ZoneMember.fromJson(json);
  }

  Future<void> update(ZoneMember zoneMember) {
    TenantScope.applyTenantIdForWrite(zoneMember);
    return _collectionReference.doc(zoneMember.UID).update(zoneMember.toJson());
  }

  Future<void> saveToken(String? token, String UID) {
    return _collectionReference.doc(UID).update({'token': token});
  }
}
