import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../model.dart';
import 'access_control.dart';

class TenantScope {
  static String? selectedTenantId;

  static String get currentTenantId {
    final tenantId = AccessControl.currentTenantId.trim();
    return tenantId.isEmpty ? TenantDefaults.defaultTenantId : tenantId;
  }

  static bool get shouldFilterTenant => !AccessControl.canBypassTenantFilter;

  static String? get activeTenantFilterId {
    final selected = selectedTenantId?.trim();
    if (AccessControl.canBypassTenantFilter &&
        selected != null &&
        selected.isNotEmpty) {
      return selected;
    }

    if (shouldFilterTenant) return currentTenantId;
    return null;
  }

  static String? get tenantIdForWrite {
    final selected = selectedTenantId?.trim();
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
    if (tenantId == null || tenantId.isEmpty) return;

    target.tenantId = tenantId;
    try {
      target.hasTenantId = true;
    } catch (_) {
      // Some domain models have tenantId but no hasTenantId flag.
    }
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
    return _normalizedTenantId(tenantId) == filterTenantId;
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
    final id = tenantId?.trim();
    if (id == null || id.isEmpty) return TenantDefaults.defaultTenantId;
    return id;
  }
}
