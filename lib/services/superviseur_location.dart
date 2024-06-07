import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';


import '../model.dart';

class LocationService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("locationTracker");
  Future<void> add(SuperviseurLocaion location) async {
    if(location.supervisor!=null){
      _collectionReference.doc('${location.supervisor?.UID??''}${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().microsecond}').set(location.toJson());
    }

  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<List<SuperviseurLocaion>> allFuture() async {
    var snpshot = await _collectionReference.get();
    List<SuperviseurLocaion> data = snpshot.docs
        .map((QueryDocumentSnapshot e) =>
        SuperviseurLocaion.fromJson(jsonDecode(jsonEncode(e.data()))))
        .toList();
    return data;
  }

  Future<List<SuperviseurLocaion>> allBySupervisor({required Supervisor supervisor}) async {
    var snapshot = await _collectionReference.where('supervisor.UID',isEqualTo: supervisor.UID).get();
    var collection = snapshot.docs
        .map((snap) {
          return SuperviseurLocaion.fromJson(jsonDecode(jsonEncode(snap.data())));
        })
        .toList();

    return collection;
  }


  Future<SuperviseurLocaion> one(code) async {
    var snapshot = await _collectionReference.doc(code).get();
    var data = jsonDecode(jsonEncode(snapshot.data()));
    var location = SuperviseurLocaion.fromJson(data);
    return location;
  }

  Future<void> delete(SuperviseurLocaion location) async {
    return _collectionReference.doc('${location.supervisor?.UID??''}${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().microsecond}').delete();
  }

  Future<void> update(SuperviseurLocaion location) {
    return _collectionReference.doc('${location.supervisor?.UID??''}${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().microsecond}').update(location.toJson());
  }
}
