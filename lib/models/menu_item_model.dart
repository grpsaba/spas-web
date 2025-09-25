import 'package:flutter/material.dart';
import 'package:spas_web/generated/assets.dart';

class MenuItemModel {
  final IconData? icon;
  final String? assetIcon;
  final String title;
  final String route;
  final int index;
  final bool isAssetCached;

  const MenuItemModel({
    this.icon,
    this.assetIcon,
    required this.title,
    required this.route,
    required this.index,
    this.isAssetCached = false,
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
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconManager,
      title: "PC",
      route: "/users",
      index: 1,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconSite,
      title: "Sites",
      route: "/sites",
      index: 2,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconAgent,
      title: "Agents",
      route: "/agents",
      index: 3,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsAgent,
      title: "Superviseurs",
      route: "/superviseurs",
      index: 4,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconTools,
      title: "Matériaux",
      route: "/tools",
      index: 5,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconScansite,
      title: "Pointage Sites",
      route: "/pointages",
      index: 6,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconScanAgent,
      title: "Pointage Agents",
      route: "/pointageagents",
      index: 7,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconScanAgent,
      title: "Pointage Rondiers",
      route: "/pointagesrondiers",
      index: 17,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconScanTools,
      title: "Pointage Matériel",
      route: "/checklist",
      index: 8,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconNote2,
      title: "Observations",
      route: "/notes",
      index: 9,
    ),
    MenuItemModel(
      assetIcon: Assets.assetsIconMap,
      title: "Cartes Sites",
      route: "/sites/maps",
      index: 10,
    ),
    MenuItemModel(
      icon: Icons.category_rounded,
      title: "Équipements",
      route: "/equipements",
      index: 11,
    ),
    MenuItemModel(
      icon: Icons.apartment_rounded,
      title: "Départements",
      route: "/departements",
      index: 12,
    ),
    MenuItemModel(
      icon: Icons.supervised_user_circle_rounded,
      title: "Types Agent",
      route: "/typesagent",
      index: 13,
    ),
    MenuItemModel(
      icon: Icons.map_rounded,
      title: "Zones",
      route: "/zones",
      index: 14,
    ),
    MenuItemModel(
      icon: Icons.qr_code_scanner_rounded,
      title: "Pointage Zones",
      route: "/pointagezones",
      index: 15,
    ),
    MenuItemModel(
      icon: Icons.person_pin_circle_rounded,
      title: "Chefs de Zone",
      route: "/chefszone",
      index: 16,
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