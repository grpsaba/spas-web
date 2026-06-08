import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'tenant_scope.dart';

class PointingToolService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("toolPointings");
  Future<void> add(PointingTools point) async {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.tool.serialNumber}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'PointingToolService.all',
      TenantScope.applyToQuery(_collectionReference),
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
