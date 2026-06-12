import 'package:flutter/material.dart';
import 'package:spas_web/generated/assets.dart';
import 'package:spas_web/model.dart';

class MenuItemModel {
  final IconData? icon;
  final String? assetIcon;
  final String title;
  final String route;
  final int index;
  final ModuleName moduleName;
  final bool isAssetCached;
  final bool adminOnly;

  const MenuItemModel({
    this.icon,
    this.assetIcon,
    required this.title,
    required this.route,
    required this.index,
    required this.moduleName,
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
      icon: Icons.home_rounded,
      title: "Accueil",
      route: "/home",
      index: 0,
      moduleName: ModuleName.TABLEAU_DE_BORD,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconManager,
      title: "PC",
      route: "/users",
      index: 1,
      moduleName: ModuleName.MANAGER,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconSite,
      title: "Sites",
      route: "/sites",
      index: 2,
      moduleName: ModuleName.SITE,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconAgent,
      title: "Agents",
      route: "/agents",
      index: 3,
      moduleName: ModuleName.AGENT,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsAgent,
      title: "Superviseurs",
      route: "/superviseurs",
      index: 4,
      moduleName: ModuleName.SUPERVISEUR,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconTools,
      title: "Matériaux",
      route: "/tools",
      index: 5,
      moduleName: ModuleName.TOOL,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconScansite,
      title: "Pointage Sites",
      route: "/pointages",
      index: 6,
      moduleName: ModuleName.POINTAGE_SITE,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconScanAgent,
      title: "Pointage Agents",
      route: "/pointageagents",
      index: 7,
      moduleName: ModuleName.POINTAGE_AGENT,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconScanAgent,
      title: "Pointage Rondiers",
      route: "/pointagesrondiers",
      index: 17,
      moduleName: ModuleName.POINTAGE_RONDIER,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconScanTools,
      title: "Pointage Matériel",
      route: "/checklist",
      index: 8,
      moduleName: ModuleName.POINTAGE_TOOL,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconNote2,
      title: "Observations",
      route: "/notes",
      index: 9,
      moduleName: ModuleName.NOTE,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconMap,
      title: "Cartes Sites",
      route: "/sites/maps",
      index: 10,
      moduleName: ModuleName.SITE,
    ),
    MenuItemModel(
      icon: Icons.category_rounded,
      title: "Équipements",
      route: "/equipements",
      index: 11,
      moduleName: ModuleName.CATEGORIE_TOOL,
    ),
    MenuItemModel(
      icon: Icons.apartment_rounded,
      title: "Départements",
      route: "/departements",
      index: 12,
      moduleName: ModuleName.DEPARTMENT,
    ),
    MenuItemModel(
      icon: Icons.supervised_user_circle_rounded,
      title: "Types Agent",
      route: "/typesagent",
      index: 13,
      moduleName: ModuleName.AGENT_TYPE,
    ),
    MenuItemModel(
      icon: Icons.map_rounded,
      title: "Zones",
      route: "/zones",
      index: 14,
      moduleName: ModuleName.ZONE,
    ),
    MenuItemModel(
      icon: Icons.qr_code_scanner_rounded,
      title: "Pointage Zones",
      route: "/pointagezones",
      index: 15,
      moduleName: ModuleName.POINTAGE_ZONE,
    ),
    MenuItemModel(
      icon: Icons.person_pin_circle_rounded,
      title: "Chefs de Zone",
      route: "/chefszone",
      index: 16,
      moduleName: ModuleName.ZONE_MEMBER,
    ),
    MenuItemModel(
      icon: Icons.warning_amber_rounded,
      title: "Erreurs Pointage",
      route: "/errorlogs",
      index: 18,
      moduleName: ModuleName.ERROR_LOG,
    ),
    MenuItemModel(
      icon: Icons.settings_cell_rounded,
      title: "Config Mobile",
      route: "/mobile-config",
      index: 19,
      moduleName: ModuleName.MOBILE_CONFIG,
    ),
    MenuItemModel(
      icon: Icons.public_rounded,
      title: "Pays",
      route: "/tenants",
      index: 20,
      moduleName: ModuleName.MANAGER,
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
