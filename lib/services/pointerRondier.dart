import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'tenant_scope.dart';


class PointingRondierService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("rondierPointings");
  Future<void> add(PointingRondier point) async {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.date.hour} ${point.date.minute}-${point.date.second}-${point.date.millisecond}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'PointingRondierService.all',
      TenantScope.applyToQuery(_collectionReference),
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
