import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class ToolService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Tools");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(Tool tool) async {
    TenantScope.applyTenantIdForWrite(tool);
    _collectionReference.doc(tool.serialNumber).set(tool.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'ToolService.all',
      _scopedQuery,
    );
  }

  Future<void> delete(Tool tool) async {
    return _collectionReference.doc(tool.serialNumber).delete();
  }

  Future<Tool> one(uid) async {
    var dataSnapshot = await _collectionReference.doc(uid).get();
    var data = jsonEncode(dataSnapshot.data());
    final json = jsonDecode(data) as Map<String, dynamic>;
    if (!TenantScope.matchesTenant(tenantIdFromJson(json)) ||
        !DepartmentScope.matchesDepartment(departmentIdFromJson(json))) {
      throw StateError('Tool outside the active tenant or department scope.');
    }
    return Tool.fromJson(json);
  }

  Future<void> update(Tool tool) {
    TenantScope.applyTenantIdForWrite(tool);
    return _collectionReference.doc(tool.serialNumber).update(tool.toJson());
  }

  Future<List<Tool>> allBySite(uid) async {
    var snapshot = await TenantScope.getQuery(
      'ToolService.allBySite',
      _scopedQuery,
    );
    var collection = snapshot.docs
        .map((snap) {
          return Tool.fromJson(jsonDecode(jsonEncode(snap.data())));
        })
        .toList()
        .where((element) {
          if (element.site?.supervisor_2 != null) {
            return element.site?.supervisor?.UID == uid ||
                element.site?.supervisor_2?.UID == uid;
          } else {
            return element.site?.supervisor?.UID == uid;
          }
        })
        .toList();
    return collection;
  }
}
