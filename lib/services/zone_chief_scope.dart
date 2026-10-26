import 'dart:convert';

import '../model.dart';

/// The same geographic and department scope is used online and in the cache.
class ZoneChiefScope {
  static bool includesSite(ZoneMember member, Site site) {
    if (!member.hasSiteScope || site.tenantId != member.tenantId) {
      return false;
    }
    // Historical notes/pointings may embed sites before departmentIds existed.
    // Match the effective membership used by Site.toJson and TenantScope.
    final siteDepartments = <String>{
      ...site.departmentIds.map(normalizeDepartmentId),
      normalizeDepartmentId(site.supervisor?.departmentId),
      normalizeDepartmentId(site.supervisor?.department?.id),
      normalizeDepartmentId(site.supervisor_2?.departmentId),
      normalizeDepartmentId(site.supervisor_2?.department?.id),
    }..removeWhere((id) => id.isEmpty);
    if (!siteDepartments.contains(normalizeDepartmentId(member.departmentId))) {
      return false;
    }
    return member.hasGlobalZoneAccess ||
        site.zone?.codeZone == member.zone?.codeZone;
  }

  static bool includesActiveSite(ZoneMember member, Site site) =>
      site.actif == true && includesSite(member, site);

  static String cacheScope(ZoneMember member) => jsonEncode([
        'v2',
        member.tenantId,
        normalizeDepartmentId(member.departmentId),
        member.zoneScope,
        if (!member.hasGlobalZoneAccess) member.zone?.codeZone,
      ]);
}
