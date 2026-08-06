import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class CategorieToolService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("categorieTools");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(CategorieTool tool) async {
    TenantScope.applyTenantIdForWrite(tool);
    _collectionReference.doc(tool.label).set(tool.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'CategorieToolService.all',
      _scopedQuery,
    );
  }

  Future<void> delete(CategorieTool tool) async {
    return _collectionReference.doc(tool.label).delete();
  }

  Future<CategorieTool> one(label) async {
    var dataSnapshot = await _collectionReference.doc(label).get();
    var data = jsonEncode(dataSnapshot.data());
    final json = jsonDecode(data) as Map<String, dynamic>;
    if (!TenantScope.matchesTenant(tenantIdFromJson(json)) ||
        !DepartmentScope.matchesDepartment(departmentIdFromJson(json))) {
      throw StateError(
        'Tool category outside the active tenant or department scope.',
      );
    }
    return CategorieTool.fromJson(json);
  }

  Future<void> update(CategorieTool tool) {
    TenantScope.applyTenantIdForWrite(tool);
    return _collectionReference.doc(tool.label).update(tool.toJson());
  }
}
