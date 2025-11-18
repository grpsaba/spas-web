import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class AgentService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Agents");
  Future<void> add(Agent agent) async {
    agent.genererCode();
    _collectionReference.doc(agent.code).set(agent.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }
  
  Stream<QuerySnapshot> allOfficePersonnel() {
    return _collectionReference.where("actif",isEqualTo: true).where("site.UID", isEqualTo: "rXkVVl9AH8MYSPn25FSHS7eESpc2").snapshots();
  }


  Future<List<Agent>> allFuture() async {
    var snpshot = await _collectionReference.get();
    List<Agent> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Agent.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<List<Agent>> allByDomaine(String domaine) async {
    var snpshot = await _collectionReference
        .where("typeAgent.label", isEqualTo: domaine)
        .where("site", isNotEqualTo: null)
        .where("actif", isEqualTo: true)
        .get();
    List<Agent> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
            Agent.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<List<Agent>> allBySupervisor(uid) async {
    var snapshot = await _collectionReference.get();
    var collection = snapshot.docs
        .map((snap) {
          return Agent.fromJson(jsonDecode(jsonEncode(snap.data())));
        })
        .toList()
        .where((element) {
          return element.actif == true &&
              element.site?.actif == true &&
              (element.site?.supervisor?.UID == uid ||
                  element.site?.supervisor_2?.UID == uid);
        })
        .toList();
    return collection;
  }

  Future<List<Agent>> allBySite(uid) async {
    var snapshot =
        await _collectionReference.where("site.UID", isEqualTo: uid).get();
    var collection = snapshot.docs.map((snap) {
      return Agent.fromJson(jsonDecode(jsonEncode(snap.data())));
    }).toList();
    /* .where((element) => element.site?.UID == uid)
        .toList();*/
    return collection;
  }

  Future<Agent> one(code) async {
    var snapshot = await _collectionReference.doc(code).get();
    var data = jsonDecode(jsonEncode(snapshot.data()));
    var agent = Agent.fromJson(data);
    return agent;
  }

  Future<void> delete(Agent agent) async {
    return _collectionReference.doc(agent.code).delete();
  }

  Future<void> update(Agent agent) {
    return _collectionReference.doc(agent.code).update(agent.toJson());
  }
}
