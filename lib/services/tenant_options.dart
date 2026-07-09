import '../model.dart';
import 'tenant.dart';

class TenantOptions {
  static const List<Tenant> fallback = [
    Tenant(id: TenantDefaults.maliTenantId, label: 'Mali', countryCode: 'ML'),
  ];

  static Future<List<Tenant>> load({String? includeTenantId}) async {
    List<Tenant> tenants;
    try {
      tenants = await TenantService().allActive();
    } catch (_) {
      tenants = fallback;
    }

    if (tenants.isEmpty) tenants = fallback;

    final id = includeTenantId?.trim();
    if (id != null &&
        id.isNotEmpty &&
        !tenants.any((tenant) => tenant.id == id)) {
      tenants = [
        ...tenants,
        Tenant(id: id, label: id.toUpperCase(), countryCode: id.toUpperCase()),
      ];
    }

    return tenants;
  }

  static String labelFor(String? tenantId, List<Tenant> tenants) {
    final id = tenantId?.trim();
    if (id == null || id.isEmpty) return 'Non affecte';

    for (final tenant in tenants) {
      if (tenant.id == id) return tenant.label;
    }

    return id.toUpperCase();
  }
}
