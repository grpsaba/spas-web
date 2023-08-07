import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class PointingToolService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("toolPointings");
  Future<void> add(PointingTools point) async {
    String child =
        "${point.tool.serialNumber}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingTools point) {
    String child =
        "${point.tool.serialNumber}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(point.toJson());
  }
}
