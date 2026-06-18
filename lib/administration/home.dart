import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:spas_web/administration/sos_wiget.dart';
import 'package:spas_web/models/menu_item_model.dart';
import 'package:spas_web/services/access_control.dart';
import 'package:spas_web/services/drawer_menu_config.dart';
import '../const.dart';
import '../model.dart';
import '../services/authentication.dart';
import '../services/tenant_options.dart';
import '../services/tenant_scope.dart';

class PageModel extends StatefulWidget {
  const PageModel({
    super.key,
    required this.child,
    required this.pageIndex,
    required this.title,
  });

  final Widget child;
  final int pageIndex;
  final String title;

  @override
  State<PageModel> createState() => _PageModelState();
}

class _PageModelState extends State<PageModel>
    with SingleTickerProviderStateMixin {
  static const double _compactDrawerWidth = 76;
  static const double _expandedDrawerWidth = 280;
  static const double _drawerHeaderHeight = 96;
  static const double _webDrawerBreakpoint = 900;
  static const Color _drawerActiveIconColor = Color(0xFFE6ECFF);
  static const Color _drawerInactiveIconColor = Color(0xFFAEB7C8);
  static const Color _drawerActiveIndicatorColor = Color(0xFF9AA7FF);
  static bool _drawerExpandedPreference = true;
  static double _drawerScrollOffset = 0;

  late bool _showDrawer;
  bool _loadingTenants = true;
  List<Tenant> _tenants = TenantOptions.fallback;
  final DrawerMenuConfigService _drawerMenuConfigService =
      DrawerMenuConfigService();
  late AnimationController _animationController;
  late Animation<double> _drawerAnimation;
  late Stream<DrawerMenuConfig> _drawerMenuConfigStream;
  late ScrollController _drawerScrollController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      value: _drawerExpandedPreference ? 1.0 : 0.0,
    );
    _showDrawer = _drawerExpandedPreference;
    _drawerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _drawerMenuConfigStream = _drawerMenuConfigService.watchConfig();
    _drawerScrollController = ScrollController(
      initialScrollOffset: _drawerScrollOffset,
    );
    _drawerScrollController.addListener(_saveDrawerScrollOffset);
    _loadTenants();
  }

  void _saveDrawerScrollOffset() {
    if (!_drawerScrollController.hasClients) return;
    _drawerScrollOffset = _drawerScrollController.offset;
  }

  Future<void> _loadTenants() async {
    final tenants =
        await TenantOptions.load(includeTenantId: TenantScope.selectedTenantId);
    if (!mounted) return;

    setState(() {
      _tenants = tenants;
      _loadingTenants = false;
    });
  }

  @override
  void dispose() {
    _saveDrawerScrollOffset();
    _drawerScrollController.removeListener(_saveDrawerScrollOffset);
    _drawerScrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          widget.pageIndex == 0 ? AppConstants.bgColor : Colors.white,
      appBar: _buildAppBar(context),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDrawer(),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppConstants.primaryColor,
      elevation: 2,
      leading: Container(
        padding: const EdgeInsets.all(8),
        child: const Image(
          image: AssetImage("assets/logo.png"),
          fit: BoxFit.contain,
        ),
      ),
      title: Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      actions: [
        const Text("V18/06/2026 11:59"),
        if (AccessControl.canBypassTenantFilter) ...[
          const SizedBox(width: 12),
          _buildTenantFilter(),
        ],
        Sos(),
        const SizedBox(width: 16),
        _buildUserInfo(),
        const SizedBox(width: 8),
        _buildLogoutButton(context),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildTenantFilter() {
    if (_loadingTenants) {
      return const SizedBox(
        width: 120,
        child: LinearProgressIndicator(color: Colors.white),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: TenantScope.selectedTenantId,
          dropdownColor: AppConstants.primaryColor,
          iconEnabledColor: Colors.white,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Tous pays'),
            ),
            ..._tenants.map(
              (tenant) => DropdownMenuItem<String?>(
                value: tenant.id,
                child: Text(tenant.label),
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              TenantScope.selectedTenantId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    final manager = AuthService.currentManager;
    if (manager == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              "${manager.firstName.isNotEmpty ? manager.firstName[0] : ''}${manager.lastName.isNotEmpty ? manager.lastName[0] : ''}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${manager.firstName} ${manager.lastName}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          try {
            await AuthService().logOut();
            if (context.mounted) {
              context.go('/login');
            } else {
              debugPrint('Warning: Context not mounted, navigation aborted.');
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Logout failed: $e')),
              );
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: const Icon(
            HugeIcons.strokeRoundedLogout03,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth >= _webDrawerBreakpoint;

    return StreamBuilder<DrawerMenuConfig>(
      stream: _drawerMenuConfigStream,
      builder: (context, child) {
        final drawerConfig = child.data ?? const DrawerMenuConfig.defaults();
        final visibleMenuItems = MenuItemModel.menuItems.where((item) {
          if (!drawerConfig.isEnabled(item)) return false;
          if (item.adminOnly) return AccessControl.canBypassTenantFilter;
          return AccessControl.canView(item.moduleName);
        }).toList();

        return AnimatedBuilder(
          animation: _drawerAnimation,
          builder: (context, child) {
            final double drawerWidth = isLarge
                ? _compactDrawerWidth +
                    (_drawerAnimation.value *
                        (_expandedDrawerWidth - _compactDrawerWidth))
                : _compactDrawerWidth;
            final drawerItems = _buildDrawerItems(visibleMenuItems, isLarge);
            return Container(
              width: drawerWidth,
              decoration: BoxDecoration(
                color: const Color(0xFF303236),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(3, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDrawerHeader(isLarge),
                  Expanded(
                    child: visibleMenuItems.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Aucun menu disponible',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ),
                          )
                        : ListView(
                            controller: _drawerScrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            physics: const BouncingScrollPhysics(),
                            children: drawerItems,
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildDrawerItems(
    List<MenuItemModel> visibleMenuItems,
    bool isLarge,
  ) {
    final widgets = <Widget>[];

    for (final section in MenuSection.values) {
      final sectionItems = visibleMenuItems
          .where((item) => item.section == section)
          .toList(growable: false);
      if (sectionItems.isEmpty) continue;

      if (section != MenuSection.main) {
        widgets.add(_buildSectionHeader(section, isLarge));
      }

      for (final item in sectionItems) {
        widgets.add(_buildMenuItem(item, isLarge));
      }
    }

    return widgets;
  }

  Widget _buildSectionHeader(MenuSection section, bool isLarge) {
    if (!isLarge) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Divider(
          height: 1,
          color: Colors.white.withValues(alpha: 0.12),
        ),
      );
    }

    return SizedBox(
      height: 30,
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: _drawerAnimation.value,
          child: Padding(
            padding: const EdgeInsets.only(left: 18, top: 10),
            child: Text(
              section.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.48),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(bool isLarge) {
    final useCompactHeader = !isLarge || _drawerAnimation.value < 0.32;
    if (useCompactHeader) {
      return _buildCompactDrawerHeader(isLarge);
    }

    return SizedBox(
      height: _drawerHeaderHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.13),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.09),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildDrawerLogo(size: 42, padding: 7, radius: 12),
            if (isLarge)
              Expanded(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _drawerAnimation.value,
                    child: AnimatedOpacity(
                      opacity: _drawerAnimation.value,
                      duration: const Duration(milliseconds: 180),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          "SPAS",
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (isLarge && AccessControl.isAdministrator)
              _buildDrawerConfigButton(size: 38, borderRadius: 10),
            if (isLarge) _buildDrawerToggleButton(size: 38, borderRadius: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDrawerHeader(bool canExpand) {
    return SizedBox(
      height: _drawerHeaderHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.13),
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.09),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDrawerLogo(size: 34, padding: 6, radius: 10),
            if (canExpand) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (AccessControl.isAdministrator) ...[
                    _buildDrawerConfigButton(
                      size: 26,
                      borderRadius: 7,
                      iconSize: 18,
                    ),
                    const SizedBox(width: 4),
                  ],
                  _buildDrawerToggleButton(
                    size: 26,
                    borderRadius: 7,
                    iconSize: 20,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerLogo({
    required double size,
    required double padding,
    required double radius,
  }) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Image(
        image: AssetImage("assets/logo.png"),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildDrawerToggleButton({
    required double size,
    required double borderRadius,
    double iconSize = 22,
  }) {
    return Tooltip(
      message: _showDrawer ? 'Reduire le menu' : 'Ouvrir le menu',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleDrawer,
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: AnimatedRotation(
                turns: _drawerAnimation.value * 0.5,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  HugeIcons.strokeRoundedArrowRight01,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerConfigButton({
    required double size,
    required double borderRadius,
    double iconSize = 20,
  }) {
    return Tooltip(
      message: 'Configurer le menu',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openDrawerMenuConfig,
          borderRadius: BorderRadius.circular(borderRadius),
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: Icon(
                HugeIcons.strokeRoundedDashboardSquareSetting,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openDrawerMenuConfig() async {
    if (!AccessControl.isAdministrator) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => _DrawerMenuConfigDialog(
        service: _drawerMenuConfigService,
      ),
    );
  }

  void _toggleDrawer() {
    setState(() {
      _showDrawer = !_showDrawer;
      _drawerExpandedPreference = _showDrawer;
    });

    if (_showDrawer) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  Widget _buildMenuItem(MenuItemModel item, bool isLarge) {
    final isSelected = widget.pageIndex == item.index;
    final isCompactItem = !isLarge || _drawerAnimation.value < 0.36;

    return Tooltip(
      message: item.title,
      waitDuration: const Duration(milliseconds: 450),
      child: Container(
        height: 52,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: Colors.white.withValues(alpha: 0.08),
            hoverColor: Colors.white.withValues(alpha: 0.06),
            onTap: () => context.go(item.route),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: isCompactItem ? 0 : 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppConstants.primaryColor.withValues(alpha: 0.23)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppConstants.primaryColor.withValues(alpha: 0.35)
                      : Colors.transparent,
                ),
              ),
              child: isCompactItem
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isSelected)
                          Positioned(
                            left: 4,
                            child: Container(
                              width: 4,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _drawerActiveIndicatorColor,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        _buildMenuIcon(item, isSelected),
                      ],
                    )
                  : Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 4,
                          height: isSelected ? 28 : 0,
                          decoration: BoxDecoration(
                            color: _drawerActiveIndicatorColor,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildMenuIcon(item, isSelected),
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: _drawerAnimation.value,
                            child: AnimatedOpacity(
                              opacity: _drawerAnimation.value,
                              duration: const Duration(milliseconds: 180),
                              child: Container(
                                width: 180,
                                padding: const EdgeInsets.only(left: 12),
                                child: Text(
                                  item.title,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuIcon(MenuItemModel item, bool isSelected) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isSelected
            ? AppConstants.primaryColor
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: item.assetIcon != null
          ? Padding(
              padding: const EdgeInsets.all(8),
              child: item.cachedAssetImage != null
                  ? Image(
                      image: item.cachedAssetImage!,
                      color: isSelected
                          ? _drawerActiveIconColor
                          : _drawerInactiveIconColor,
                      fit: BoxFit.contain,
                      width: 22,
                      height: 22,
                    )
                  : Image.asset(
                      item.assetIcon!,
                      color: isSelected
                          ? _drawerActiveIconColor
                          : _drawerInactiveIconColor,
                      fit: BoxFit.contain,
                      width: 22,
                      height: 22,
                    ),
            )
          : Icon(
              item.icon ?? HugeIcons.strokeRoundedAlertCircle,
              color: isSelected
                  ? _drawerActiveIconColor
                  : _drawerInactiveIconColor,
              size: 21,
            ),
    );
  }
}

class _DrawerMenuConfigDialog extends StatefulWidget {
  const _DrawerMenuConfigDialog({required this.service});

  final DrawerMenuConfigService service;

  @override
  State<_DrawerMenuConfigDialog> createState() =>
      _DrawerMenuConfigDialogState();
}

class _DrawerMenuConfigDialogState extends State<_DrawerMenuConfigDialog> {
  final Map<String, bool> _enabledByKey = <String, bool>{};

  bool _loading = true;
  bool _saving = false;
  String? _pendingKey;
  String? _statusMessage;
  bool _statusIsError = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await widget.service.getConfig();
      if (!mounted) return;
      setState(() {
        for (final item in MenuItemModel.menuItems) {
          _enabledByKey[item.configKey] = config.isEnabled(item);
        }
        _loading = false;
        _statusMessage = null;
        _statusIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _statusMessage = 'Chargement impossible: $error';
        _statusIsError = true;
      });
    }
  }

  Future<void> _setItemEnabled(MenuItemModel item, bool enabled) async {
    final previousValue = _enabledByKey[item.configKey] ?? true;

    setState(() {
      _enabledByKey[item.configKey] = enabled;
      _saving = true;
      _pendingKey = item.configKey;
      _statusMessage = 'Enregistrement en cours...';
      _statusIsError = false;
    });

    try {
      await widget.service.saveEnabledByKey(_enabledByKey);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _pendingKey = null;
        _statusMessage = 'Configuration enregistree.';
        _statusIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _enabledByKey[item.configKey] = previousValue;
        _saving = false;
        _pendingKey = null;
        _statusMessage = 'Enregistrement refuse par Firestore: $error';
        _statusIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuration du drawer'),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: SizedBox(
        width: 560,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (_loading) {
              return const SizedBox(
                height: 180,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final maxHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : MediaQuery.of(context).size.height * 0.72;

            return SizedBox(
              height: maxHeight,
              child: Column(
                children: [
                  _buildStatus(),
                  Flexible(
                    child: ListView.builder(
                      itemCount: MenuItemModel.menuItems.length,
                      itemBuilder: (context, index) {
                        final item = MenuItemModel.menuItems[index];
                        return _buildMenuSwitch(item);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }

  Widget _buildStatus() {
    if (_statusMessage == null) {
      return const SizedBox.shrink();
    }

    final color = _statusIsError ? Colors.red : AppConstants.primaryColor;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          if (_saving) ...[
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: color,
              ),
            ),
          ] else
            Icon(
              _statusIsError
                  ? HugeIcons.strokeRoundedAlertCircle
                  : HugeIcons.strokeRoundedCheckmarkCircle01,
              size: 18,
              color: color,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSwitch(MenuItemModel item) {
    final enabled = _enabledByKey[item.configKey] ?? true;
    final isPending = _pendingKey == item.configKey;

    return SwitchListTile.adaptive(
      value: enabled,
      onChanged: _saving ? null : (value) => _setItemEnabled(item, value),
      secondary: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            item.icon ?? HugeIcons.strokeRoundedAlertCircle,
            color: enabled ? AppConstants.primaryColor : Colors.black38,
          ),
          if (isPending)
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
      title: Text(item.title),
      subtitle: Text(enabled ? 'Affiche dans le drawer' : 'Masque du drawer'),
      activeThumbColor: AppConstants.primaryColor,
      activeTrackColor: AppConstants.primaryColor.withValues(alpha: 0.26),
      contentPadding: EdgeInsets.zero,
    );
  }
}
