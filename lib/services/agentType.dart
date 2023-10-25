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
