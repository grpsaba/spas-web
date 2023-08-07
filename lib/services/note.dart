import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class NoteService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Notes");

  Future<void> add(Note note) async {
    var reference =
        '${note.date.hour}${note.date.minute}${note.date.second}${note.date.microsecond}';
    note.id = reference;
    _collectionReference.doc(reference).set(note.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<void> delete(Note note) async {
    return _collectionReference.doc(note.id).delete();
  }

  Future<Note?> one(uid) async {
    var dataSnapshot = await _collectionReference.doc(uid).get();
    var data = jsonEncode(dataSnapshot.data());
    return Note.fromJson(jsonDecode(data));
  }

  Future<void> update(Note note) {
    return _collectionReference.doc(note.id).update(note.toJson());
  }
}
