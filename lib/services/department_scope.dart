import 'package:cloud_firestore/cloud_firestore.dart';

import '../model.dart';
import 'access_control.dart';

class DepartmentScope {
  static Manager? get _manager => AccessControl.currentManager;

  static bool get isLimited {
    return _manager?.departmentScope == DepartmentScopeValue.limited;
  }

  static List<String> get activeDepartmentIds {
    final manager = _manager;
    if (manager == null) return <String>[];

    return manager.departmentIds
        .map(normalizeDepartmentId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
  }

  static bool get hasGlobalDepartmentAccess {
    return activeDepartmentIds.contains('direction');
  }

  static bool shouldFilterDepartment({String? tenantId}) {
    if (!isLimited) return false;
    if (hasGlobalDepartmentAccess) return false;
    return true;
  }

  static Query<T> applyToDepartmentQuery<T extends Object?>(
    Query<T> query, {
    String? tenantId,
  }) {
    if (!shouldFilterDepartment(tenantId: tenantId)) return query;

    final ids = activeDepartmentIds;
    if (ids.isEmpty) {
      return query.where('departmentId', isEqualTo: '__no_department__');
    }
    if (ids.length == 1) {
      return query.where('departmentId', isEqualTo: ids.first);
    }

    return query.where('departmentId', whereIn: ids.take(10).toList());
  }

  static Query<T> applyToSiteQuery<T extends Object?>(
    Query<T> query, {
    String? tenantId,
  }) {
    if (!shouldFilterDepartment(tenantId: tenantId)) return query;

    final ids = activeDepartmentIds;
    if (ids.isEmpty) {
      return query.where('departmentIds', arrayContains: '__no_department__');
    }
    if (ids.length == 1) {
      return query.where('departmentIds', arrayContains: ids.first);
    }

    return query.where('departmentIds', arrayContainsAny: ids.take(10).toList());
  }

  static Query<T> applyToDepartmentCatalogQuery<T extends Object?>(
    Query<T> query,
  ) {
    if (!isLimited || hasGlobalDepartmentAccess) return query;

    final ids = activeDepartmentIds;
    if (ids.isEmpty) {
      return query.where('id', isEqualTo: '__no_department__');
    }
    if (ids.length == 1) {
      return query.where('id', isEqualTo: ids.first);
    }

    return query.where('id', whereIn: ids.take(10).toList());
  }

  static bool matchesDepartment(String? departmentId, {String? tenantId}) {
    if (!shouldFilterDepartment(tenantId: tenantId)) return true;
    return activeDepartmentIds.contains(normalizeDepartmentId(departmentId));
  }

  static bool matchesSite(Site site, {String? tenantId}) {
    if (!shouldFilterDepartment(tenantId: tenantId)) return true;

    final ids = <String>{
      ...site.departmentIds.map(normalizeDepartmentId),
      normalizeDepartmentId(site.supervisor?.departmentId),
      normalizeDepartmentId(site.supervisor?.department?.id),
      normalizeDepartmentId(site.supervisor_2?.departmentId),
      normalizeDepartmentId(site.supervisor_2?.department?.id),
    }..removeWhere((id) => id.isEmpty);

    return ids.any(activeDepartmentIds.contains);
  }
}
