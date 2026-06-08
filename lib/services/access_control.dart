import 'package:spas_web/model.dart';
import 'package:spas_web/services/authentication.dart';

/// Centralise les regles de visibilite UI selon le profil du manager connecte.
///
/// Cette classe ne remplace pas les regles de securite backend/Firestore :
/// elle sert uniquement a masquer ou afficher les elements de l'interface.
class AccessControl {
  static const String administratorProfileName = 'Administrateur';
  static const String generalDirectorProfileName = 'Directeur General';

  static Manager? get _manager => AuthService.currentManager;

  static String get _normalizedProfileName =>
      normalizeProfileNameForAccess(_manager?.profil?.name);

  static bool get isAdministrator {
    return _normalizedProfileName ==
        normalizeProfileNameForAccess(administratorProfileName);
  }

  static bool get isGeneralDirector {
    return _normalizedProfileName ==
        normalizeProfileNameForAccess(generalDirectorProfileName);
  }

  static bool get canBypassTenantFilter {
    return isAdministrator || isGeneralDirector;
  }

  static String get currentTenantId {
    return _manager?.tenantId ?? TenantDefaults.defaultTenantId;
  }

  static bool canView(ModuleName moduleName) {
    if (isAdministrator) return true;
    return _manager?.profil?.getModule(moduleName)?.view ?? false;
  }

  static bool canAdd(ModuleName moduleName) {
    if (isAdministrator) return true;
    return _manager?.profil?.getModule(moduleName)?.add ?? false;
  }

  static bool canDelete(ModuleName moduleName) {
    if (isAdministrator) return true;
    return _manager?.profil?.getModule(moduleName)?.delete ?? false;
  }

  static bool canValidate(ModuleName moduleName) {
    if (isAdministrator) return true;
    return _manager?.profil?.getModule(moduleName)?.validation ?? false;
  }

  static bool canPrint(ModuleName moduleName) {
    if (isAdministrator) return true;
    return _manager?.profil?.getModule(moduleName)?.print ?? false;
  }

  static bool canGenerateBadge(ModuleName moduleName) {
    if (isAdministrator) return true;
    return _manager?.profil?.getModule(moduleName)?.generBadge ?? false;
  }
}
