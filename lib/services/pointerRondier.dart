import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';


class PointingRondierService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("rondierPointings");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(PointingRondier point) async {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.date.hour} ${point.date.minute}-${point.date.second}-${point.date.millisecond}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'PointingRondierService.all',
      _scopedQuery,
    );
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingRondier point) {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.date.hour} ${point.date.minute}-${point.date.second}-${point.date.millisecond}";
    return _collectionReference.doc(child).update(point.toJson());
  }
}
