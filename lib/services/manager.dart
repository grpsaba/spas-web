import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../model.dart';
import 'authentication.dart';
import 'tenant_scope.dart';

class ManagerService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Managers");
  Future<User?> add(Manager manager, password) async {
    if (TenantScope.shouldFilterTenant) {
      manager.tenantId = TenantScope.currentTenantId;
      manager.hasTenantId = true;
    }
    var user = await AuthService().createUserWithEmail(manager.email, password);
    if (user != null) {
      manager.UID = user.uid;
      _collectionReference.doc(manager.UID).set(_toFirestore(manager));

      //database.child(user.uid).set(supervisor.toJson());
    }
    return user;
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'ManagerService.all',
      TenantScope.applyToQuery(_collectionReference),
    );
  }

  Future<List<Manager>> allFuture() async {
    var snpshot = await TenantScope.getQuery(
      'ManagerService.allFuture',
      TenantScope.applyToQuery(_collectionReference),
    );
    List<Manager> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Manager.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<void> init() async {
    var snpshot = await _collectionReference.get();
    List<Manager> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Manager.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList()
        .where((element) => element.email == "manager@spas.com")
        .toList();
    if (data.isEmpty) {
      add(
          Manager(
              poste: "",
              UID: "",
              email: "manager@spas.com",
              phone: "",
              firstName: "",
              lastName: "",
              token: "",
              profil: Profil(name: "Administrateur", modules: [
                Module(
                    moduleName: ModuleName.MANAGER,
                    add: true,
                    delete: true,
                    validation: true,
                    view: true,
                    print: true,
                    generBadge: true)
              ])),
          "managerSpas@2023");
      AuthService().logOut();
    }
  }

  Future<Manager?> one(uid) async {
    try {
      var dataSnapshot = await _collectionReference.doc(uid).get();
      final rawData = dataSnapshot.data();
      if (rawData == null) return null;

      final data = jsonDecode(jsonEncode(rawData)) as Map<String, dynamic>;
      return Manager.fromJson(data);
    } catch (error) {
      return null;
    }
  }

  Future<bool> hasAssignedTenant(Manager manager) async {
    try {
      final dataSnapshot = await _collectionReference.doc(manager.UID).get();
      final rawData = dataSnapshot.data();
      if (rawData == null) return false;

      final data = jsonDecode(jsonEncode(rawData)) as Map<String, dynamic>;
      final storedTenantId = data['tenantId'];
      final hasTenantId =
          storedTenantId is String && storedTenantId.trim().isNotEmpty;
      manager.hasTenantId = hasTenantId;
      if (hasTenantId) {
        manager.tenantId = storedTenantId.trim();
      }
      return hasTenantId;
    } catch (error) {
      return false;
    }
  }

  Future<void> update(Manager manager) {
    if (TenantScope.shouldFilterTenant) {
      manager.tenantId = TenantScope.currentTenantId;
      manager.hasTenantId = true;
    }
    return _collectionReference.doc(manager.UID).update(_toFirestore(manager));
  }

  Future<void> saveToken(String? token, String UID) {
    return _collectionReference.doc(UID).update({'token': token});
  }

  Future<void> delete(Manager manager) async {
    return _collectionReference.doc(manager.UID).delete();
  }

  Map<String, dynamic> _toFirestore(Manager manager) {
    final data = manager.toJson();
    if (canBypassTenantForProfile(manager.profil) &&
        !manager.hasTenantId) {
      data.remove('tenantId');
    }
    return data;
  }
}
