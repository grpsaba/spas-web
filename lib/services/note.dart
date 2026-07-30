import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class NoteService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Notes");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(Note note) async {
    TenantScope.applyTenantIdForWrite(note);
    var reference =
        '${note.date.hour}${note.date.minute}${note.date.second}${note.date.microsecond}';
    note.id = reference;
    _collectionReference.doc(reference).set(note.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'NoteService.all',
      _scopedQuery.orderBy('date', descending: true),
    );
  }
  Stream<QuerySnapshot> allNoViewedNote() {
    return TenantScope.watchQuery(
      'NoteService.allNoViewedNote',
      _scopedQuery
          .where("viewed", isEqualTo: false)
          .orderBy('date', descending: true),
    );
  }

  Future<void> delete(Note note) async {

    return _collectionReference.doc(note.id).delete();
  }

  Future<Note?> one(uid) async {
    var dataSnapshot = await _collectionReference.doc(uid).get();
    var data = jsonEncode(dataSnapshot.data());
    final json = jsonDecode(data) as Map<String, dynamic>;
    if (!TenantScope.matchesTenant(tenantIdFromJson(json)) ||
        !DepartmentScope.matchesDepartment(departmentIdFromJson(json))) {
      return null;
    }
    return Note.fromJson(json);
  }

  Future<void> update(Note note) {
    TenantScope.applyTenantIdForWrite(note);
    return _collectionReference.doc(note.id).update(note.toJson());
  }

  Future<List<Note>> allFuture() async {
    var snpshot = await TenantScope.getQuery(
      'NoteService.allFuture',
      _scopedQuery.orderBy('date', descending: true),
    );
    List<Note> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Note.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<List<Note>> allBySource(String source) async {
    var query = _scopedQuery
        .where("source", isEqualTo: source)
        .orderBy('date', descending: true);
    var snpshot = await TenantScope.getQuery(
      'NoteService.allBySource',
      query,
    );
    List<Note> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Note.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }
}
