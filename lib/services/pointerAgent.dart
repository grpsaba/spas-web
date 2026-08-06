import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'department_scope.dart';
import 'tenant_scope.dart';

class PointingAgentService {
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("agentPointings");

  Query get _scopedQuery => DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_collectionReference),
      );

  Future<void> add(PointingAgent point) async {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.agent?.code} ${point.date.year}-${point.date.month}-${point.date.day}";
    return _collectionReference.doc(child).set(point.toJson());
  }

  Stream<QuerySnapshot> all() {
    return TenantScope.watchQuery(
      'PointingAgentService.all',
      _scopedQuery,
    );
  }

  Stream<QuerySnapshot> allByDay() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return TenantScope.watchQuery(
      'PointingAgentService.allByDay',
      _scopedQuery
          .where("date", isGreaterThanOrEqualTo: startOfDay)
          .where("date", isLessThan: endOfDay),
    );
  }

  Future<DocumentSnapshot<Object?>> one(child) {
    return _collectionReference.doc(child).get();
  }

  Future<void> update(PointingAgent point) {
    TenantScope.applyTenantIdForWrite(point);
    String child =
        "${point.agent?.code}${point.date.year}${point.date.month}${point.date.day}";
    return _collectionReference.doc(child).update(point.toJson());
  }
}
