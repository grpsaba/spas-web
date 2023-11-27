import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';

class CheckListService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("CheckLists");
  Future<void> add(CheckList tp) async {
    String child = "${tp.cattool.label}${tp.site.UID}";
    return _collectionReference.doc(child).set(tp.toJson());
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(CheckList tp) {
    String child = "${tp.cattool.label}${tp.site.UID}";
    return _collectionReference.doc(child).update(tp.toJson());
  }
}
