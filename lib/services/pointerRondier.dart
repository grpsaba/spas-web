import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';


class PointingRondierService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("rondierPointings");
  Future<void> add(PointingRondier point) async {
    String child =
        "${point.date.hour} ${point.date.minute}-${point.date.second}-${point.date.millisecond}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingRondier point) {
    String child =
        "${point.date.hour} ${point.date.minute}-${point.date.second}-${point.date.millisecond}";
    return _collectionReference.doc(child).update(point.toJson());
  }
}
