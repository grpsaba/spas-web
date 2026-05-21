import 'package:spas_web/model.dart';
import 'package:spas_web/services/authentication.dart';

/// Centralise les règles de visibilité UI selon le profil du manager connecté.
///
/// Cette classe ne remplace pas des règles de sécurité backend/Firestore :
/// elle sert uniquement à masquer ou afficher les éléments de l'interface.
class AccessControl {
  static const String administratorProfileName = 'Administrateur';

  static Manager? get _manager => AuthService.currentManager;

  static bool get isAdministrator {
    final profileName = _manager?.profil?.name.trim().toLowerCase();
    return profileName == administratorProfileName.toLowerCase();
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
