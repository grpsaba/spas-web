import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class PointingAgentService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("agentPointings");
  Future<void> add(PointingAgent point) async {
    String child =
        "${point.agent?.code} ${point.date.year}-${point.date.month}-${point.date.day}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingAgent point) {
    String child =
        "${point.agent?.code}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(point.toJson());
  }
}
