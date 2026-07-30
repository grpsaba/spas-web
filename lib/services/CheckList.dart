import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class CheckListService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("CheckLists");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(CheckList tp) async {
    TenantScope.applyTenantIdForWrite(tp);
    String child = "${tp.cattool.label}${tp.site.UID}";
    return _collectionReference.doc(child).set(tp.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'CheckListService.all',
      _scopedQuery,
    );
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(CheckList tp) {
    TenantScope.applyTenantIdForWrite(tp);
    String child = "${tp.cattool.label}${tp.site.UID}";
    return _collectionReference.doc(child).update(tp.toJson());
  }
}
