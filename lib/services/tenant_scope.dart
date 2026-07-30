import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model.dart';
import 'access_control.dart';
import 'department_scope.dart';

class TenantScope {
  static String? selectedTenantId;

  static String get currentTenantId {
    return _normalizedTenantId(AccessControl.currentTenantId);
  }

  static bool get shouldFilterTenant => !AccessControl.canBypassTenantFilter;

  static String? get activeTenantFilterId {
    final selected = _normalizedOptionalTenantId(selectedTenantId);
    if (AccessControl.canBypassTenantFilter &&
        selected != null &&
        selected.isNotEmpty) {
      return selected;
    }

    if (shouldFilterTenant) return currentTenantId;
    return null;
  }

  static String? get tenantIdForWrite {
    final selected = _normalizedOptionalTenantId(selectedTenantId);
    if (AccessControl.canBypassTenantFilter &&
        selected != null &&
        selected.isNotEmpty) {
      return selected;
    }

    if (shouldFilterTenant) return currentTenantId;
    return null;
  }

  static void applyTenantIdForWrite(dynamic target) {
    final tenantId = tenantIdForWrite;
    if (tenantId != null && tenantId.isNotEmpty) {
      try {
        target.tenantId = tenantId;
        target.hasTenantId = true;
      } catch (_) {
        try {
          target.tenantId = tenantId;
        } catch (_) {
          // Some configuration models do not carry tenantId.
        }
      }
    }

    _applyDepartmentIdForWrite(target);
  }

  static Query<T> applyToQuery<T extends Object?>(
    Query<T> query, {
    String? tenantId,
  }) {
    final filterTenantId = tenantId ?? activeTenantFilterId;
    if (filterTenantId == null) return query;

    final id = _normalizedTenantId(filterTenantId);
    return query.where('tenantId', isEqualTo: id);
  }

  static bool matchesTenant(String? tenantId) {
    final filterTenantId = activeTenantFilterId;
    if (filterTenantId == null) return true;
    return _normalizedTenantId(tenantId) == _normalizedTenantId(filterTenantId);
  }

  static Future<QuerySnapshot<T>> getQuery<T extends Object?>(
    String context,
    Query<T> query,
  ) async {
    try {
      return await query.get();
    } catch (error, stackTrace) {
      logQueryError(context, error, stackTrace);
      rethrow;
    }
  }

  static Future<AggregateQuerySnapshot> getCount(
    String context,
    AggregateQuery query,
  ) async {
    try {
      return await query.get();
    } catch (error, stackTrace) {
      logQueryError(context, error, stackTrace);
      rethrow;
    }
  }

  static Stream<QuerySnapshot<T>> watchQuery<T extends Object?>(
    String context,
    Query<T> query,
  ) {
    return query.snapshots().handleError((Object error, StackTrace stackTrace) {
      logQueryError(context, error, stackTrace);
      throw error;
    });
  }

  static void logQueryError(
    String context,
    Object error,
    StackTrace stackTrace,
  ) {
    debugPrint('Firestore query error [$context]');
    if (error is FirebaseException) {
      debugPrint('code: ${error.code}');
      debugPrint('message: ${error.message}');
      debugPrint('plugin: ${error.plugin}');
    } else {
      debugPrint(error.toString());
    }
    debugPrintStack(stackTrace: stackTrace);
  }

  static String _normalizedTenantId(String? tenantId) {
    final id = tenantId?.trim().toLowerCase();
    if (id == null || id.isEmpty) return TenantDefaults.defaultTenantId;
    return id;
  }

  static String? _normalizedOptionalTenantId(String? tenantId) {
    final id = tenantId?.trim().toLowerCase();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  static void _applyDepartmentIdForWrite(dynamic target) {
    final existingDepartmentId = normalizeDepartmentId(
      _readString(target, (value) => value.departmentId),
    );
    if (existingDepartmentId.isNotEmpty) {
      _requireDepartmentWriteAccess(existingDepartmentId);
      _writeDepartmentId(target, existingDepartmentId);
      return;
    }

    final resolvedDepartmentId = _resolveDepartmentId(target);
    if (resolvedDepartmentId.isEmpty) return;

    _requireDepartmentWriteAccess(resolvedDepartmentId);
    _writeDepartmentId(target, resolvedDepartmentId);
  }

  static void _requireDepartmentWriteAccess(String departmentId) {
    if (!DepartmentScope.matchesDepartment(departmentId)) {
      throw StateError(
        'Write outside the active department scope: $departmentId',
      );
    }
  }

  static String _resolveDepartmentId(dynamic target) {
    final candidates = <String?>[
      _readString(target, (value) => value.department?.id),
      _readString(target, (value) => value.department?.label),
      _readString(target, (value) => value.catTool?.departmentId),
      _readString(target, (value) => value.catTool?.department?.id),
      _readString(target, (value) => value.cattool?.departmentId),
      _readString(target, (value) => value.cattool?.department?.id),
      _readString(target, (value) => value.agent?.departmentId),
      _readString(target, (value) => value.agent?.department?.id),
      _readString(target, (value) => value.supervisor?.departmentId),
      _readString(target, (value) => value.supervisor?.department?.id),
      _readString(target, (value) => value.zoneMember?.departmentId),
      _readString(target, (value) => value.tool?.departmentId),
      _readString(target, (value) => value.tool?.catTool?.departmentId),
    ];

    for (final candidate in candidates) {
      final id = normalizeDepartmentId(candidate);
      if (id.isNotEmpty) return id;
    }

    return '';
  }

  static String? _readString(dynamic target, dynamic Function(dynamic) reader) {
    try {
      final value = reader(target);
      return value is String ? value : null;
    } catch (_) {
      return null;
    }
  }

  static void _writeDepartmentId(dynamic target, String departmentId) {
    try {
      target.departmentId = departmentId;
    } catch (_) {
      // Some configuration models do not carry departmentId.
    }
  }
}
