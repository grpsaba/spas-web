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

  Stream<QuerySnapshot> allByDay() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return _collectionReference
        .where("date", isGreaterThanOrEqualTo: startOfDay)
        .where("date", isLessThan: endOfDay)
        .snapshots();
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
