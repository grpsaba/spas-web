import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class PointingToolService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("toolPointings");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(PointingTools point) async {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.tool.serialNumber}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'PointingToolService.all',
      _scopedQuery,
    );
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingTools point) {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.tool.serialNumber}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(point.toJson());
  }
}
