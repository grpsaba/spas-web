import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';

class DepartmentService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("departments");

  Query get _scopedQuery =>
      DepartmentScope.applyToDepartmentCatalogQuery(_collectionReference);

  Future<void> add(Department department) async {
    final id = _documentId(department);
    department.id = id;
    await _collectionReference.doc(id).set(department.toJson());
    await _deleteLegacyDocumentIfNeeded(department, id);
  }

  Stream<QuerySnapshot> all() {
    return _scopedQuery.snapshots();
  }

  Future<List<Department>> allFuture() async {
    var snpshot = await _scopedQuery.get();
    List<Department> data = snpshot.docs.map(fromSnapshot).toList();
    return data;
  }

  Future<void> delete(Department department) async {
    final id = _documentId(department);
    await _collectionReference.doc(id).delete();
    await _deleteLegacyDocumentIfNeeded(department, id);
  }

  Future<Department> one(id) async {
    var dataSnapshot = await _collectionReference.doc(id).get();
    return fromSnapshot(dataSnapshot);
  }

  Future<void> update(Department department) {
    final id = _documentId(department);
    department.id = id;
    return _collectionReference.doc(id).update(department.toJson()).then(
          (_) => _deleteLegacyDocumentIfNeeded(department, id),
        );
  }

  static Department fromSnapshot(DocumentSnapshot snapshot) {
    final rawData = snapshot.data();
    final data = rawData == null
        ? <String, dynamic>{}
        : jsonDecode(jsonEncode(rawData)) as Map<String, dynamic>;
    data['id'] ??= snapshot.id;
    final department = Department.fromJson(data);
    department.documentId = snapshot.id;
    return department;
  }

  String _documentId(Department department) {
    final id = normalizeDepartmentId(department.id);
    if (id.isNotEmpty) return id;
    return normalizeDepartmentId(department.label);
  }

  Future<void> _deleteLegacyDocumentIfNeeded(
    Department department,
    String currentId,
  ) async {
    final legacyId = department.documentId;
    if (legacyId == null || legacyId.isEmpty || legacyId == currentId) return;

    await _collectionReference.doc(legacyId).delete();
    department.documentId = currentId;
  }
}
