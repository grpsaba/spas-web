import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class AgentTypeService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("agentTypes");

  Future<void> add(AgentType agtype) async {
    _collectionReference.doc(agtype.label).set(agtype.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<List<AgentType>> allFuture() async {
    var snpshot = await _collectionReference.get();
    List<AgentType> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            AgentType.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<void> delete(AgentType agtype) async {
    return _collectionReference.doc(agtype.label).delete();
  }

  Future<AgentType> one(label) async {
    var dataSnapshot = await _collectionReference.doc(label).get();
    var data = jsonEncode(dataSnapshot.data());
    return AgentType.fromJson(jsonDecode(data));
  }

  Future<void> update(AgentType agtype) {
    return _collectionReference.doc(agtype.label).update(agtype.toJson());
  }
}
