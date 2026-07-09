import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:spas_web/model.dart';

enum MenuSection {
  main,
  management,
  pointage,
  organization,
  configuration,
}

extension MenuSectionLabel on MenuSection {
  String get label {
    switch (this) {
      case MenuSection.main:
        return 'Principal';
      case MenuSection.management:
        return 'Gestion';
      case MenuSection.pointage:
        return 'Pointages';
      case MenuSection.organization:
        return 'Organisation';
      case MenuSection.configuration:
        return 'Configuration';
    }
  }
}

class MenuItemModel {
  final IconData? icon;
  final String? assetIcon;
  final String configKey;
  final String title;
  final String route;
  final int index;
  final ModuleName moduleName;
  final MenuSection section;
  final bool isAssetCached;
  final bool adminOnly;

  const MenuItemModel({
    this.icon,
    this.assetIcon,
    required this.configKey,
    required this.title,
    required this.route,
    required this.index,
    required this.moduleName,
    this.section = MenuSection.management,
    this.isAssetCached = false,
    this.adminOnly = false,
  });

  // Cache statique pour les assets
  static final Map<String, ImageProvider> _assetCache = {};

  ImageProvider? get cachedAssetImage {
    if (assetIcon == null) return null;

    if (!_assetCache.containsKey(assetIcon)) {
      _assetCache[assetIcon!] = AssetImage(assetIcon!);
    }
    return _assetCache[assetIcon!];
  }

  // Configuration centralisée du menu
  static const List<MenuItemModel> menuItems = [
    MenuItemModel(
      icon: HugeIcons.strokeRoundedDashboardSquare01,
      configKey: 'home',
      title: "Accueil",
      route: "/home",
      index: 0,
      moduleName: ModuleName.TABLEAU_DE_BORD,
      section: MenuSection.main,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedComputerUser,
      configKey: 'pc',
      title: "PC",
      route: "/users",
      index: 1,
      moduleName: ModuleName.MANAGER,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedBuilding03,
      configKey: 'sites',
      title: "Sites",
      route: "/sites",
      index: 2,
      moduleName: ModuleName.SITE,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedUserGroup,
      configKey: 'agents',
      title: "Agents",
      route: "/agents",
      index: 3,
      moduleName: ModuleName.AGENT,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedManager,
      configKey: 'superviseurs',
      title: "Superviseurs",
      route: "/superviseurs",
      index: 4,
      moduleName: ModuleName.SUPERVISEUR,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedTools,
      configKey: 'materiaux',
      title: "Matériaux",
      route: "/tools",
      index: 5,
      moduleName: ModuleName.TOOL,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedCheckList,
      configKey: 'pointage_sites',
      title: "Pointage Sites",
      route: "/pointages",
      index: 6,
      moduleName: ModuleName.POINTAGE_SITE,
      section: MenuSection.pointage,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedUserCheck01,
      configKey: 'pointage_agents',
      title: "Pointage Agents",
      route: "/pointageagents",
      index: 7,
      moduleName: ModuleName.POINTAGE_AGENT,
      section: MenuSection.pointage,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedRoute03,
      configKey: 'pointage_rondiers',
      title: "Pointage Rondiers",
      route: "/pointagesrondiers",
      index: 17,
      moduleName: ModuleName.POINTAGE_RONDIER,
      section: MenuSection.pointage,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedPackage,
      configKey: 'pointage_materiel',
      title: "Pointage Matériel",
      route: "/checklist",
      index: 8,
      moduleName: ModuleName.POINTAGE_TOOL,
      section: MenuSection.pointage,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedNoteEdit,
      configKey: 'observations',
      title: "Observations",
      route: "/notes",
      index: 9,
      moduleName: ModuleName.NOTE,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedMapsLocation01,
      configKey: 'cartes_sites',
      title: "Cartes Sites",
      route: "/sites/maps",
      index: 10,
      moduleName: ModuleName.SITE,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedPackageSearch,
      configKey: 'equipements',
      title: "Équipements",
      route: "/equipements",
      index: 11,
      moduleName: ModuleName.CATEGORIE_TOOL,
      section: MenuSection.configuration,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedOffice,
      configKey: 'departements',
      title: "Départements",
      route: "/departements",
      index: 12,
      moduleName: ModuleName.DEPARTMENT,
      section: MenuSection.organization,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedUserIdVerification,
      configKey: 'types_agent',
      title: "Types Agent",
      route: "/typesagent",
      index: 13,
      moduleName: ModuleName.AGENT_TYPE,
      section: MenuSection.organization,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedMapsCircle01,
      configKey: 'zones',
      title: "Zones",
      route: "/zones",
      index: 14,
      moduleName: ModuleName.ZONE,
      section: MenuSection.organization,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedQrCode,
      configKey: 'pointage_zones',
      title: "Pointage Zones",
      route: "/pointagezones",
      index: 15,
      moduleName: ModuleName.POINTAGE_ZONE,
      section: MenuSection.pointage,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedLocationUser01,
      configKey: 'chefs_zone',
      title: "Chefs de Zone",
      route: "/chefszone",
      index: 16,
      moduleName: ModuleName.ZONE_MEMBER,
      section: MenuSection.organization,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedAlertCircle,
      configKey: 'erreurs_pointage',
      title: "Erreurs Pointage",
      route: "/errorlogs",
      index: 18,
      moduleName: ModuleName.ERROR_LOG,
      section: MenuSection.pointage,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedMobileSecurity,
      configKey: 'config_mobile',
      title: "Config Mobile",
      route: "/mobile-config",
      index: 19,
      moduleName: ModuleName.MOBILE_CONFIG,
      section: MenuSection.configuration,
    ),
    MenuItemModel(
      icon: HugeIcons.strokeRoundedGlobal,
      configKey: 'pays',
      title: "Pays",
      route: "/tenants",
      index: 20,
      moduleName: ModuleName.MANAGER,
      section: MenuSection.configuration,
      adminOnly: true,
    ),
  ];

  // Méthode pour précharger tous les assets
  static Future<void> preloadAssets() async {
    for (final item in menuItems) {
      if (item.assetIcon != null) {
        _assetCache[item.assetIcon!] = AssetImage(item.assetIcon!);
      }
    }
  }
}
