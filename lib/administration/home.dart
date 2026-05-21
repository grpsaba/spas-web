import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/sos_wiget.dart';
import 'package:spas_web/models/menu_item_model.dart';
import 'package:spas_web/services/access_control.dart';
import '../const.dart';
import '../services/authentication.dart';

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
  bool _showDrawer = false;
  late AnimationController _animationController;
  late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _drawerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
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
        const Text("V21/05/2026"),
        Sos(),
        const SizedBox(width: 16),
        _buildUserInfo(),
        const SizedBox(width: 8),
        _buildLogoutButton(context),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildUserInfo() {
    final manager = AuthService.currentManager;
    if (manager == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white.withOpacity(0.2),
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
            Icons.logout_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 768 && screenWidth <= 1200;
    final isLarge = isDesktop || isTablet;

    final visibleMenuItems = MenuItemModel.menuItems
        .where((item) => AccessControl.canView(item.moduleName))
        .toList();

    return AnimatedBuilder(
      animation: _drawerAnimation,
      builder: (context, child) {
        final double drawerWidth =
            isLarge ? 80 + (_drawerAnimation.value * 170) : 80;
        return Container(
          width: drawerWidth,
          decoration: BoxDecoration(
            color: AppConstants.bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(2, 0),
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
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: visibleMenuItems.length,
                        itemBuilder: (context, index) => _buildMenuItem(
                          visibleMenuItems[index],
                          isLarge,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerHeader(bool isLarge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: isLarge
          ? Row(
              mainAxisSize:
                  MainAxisSize.min, // Prevent Row from expanding unnecessarily
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: AnimatedOpacity(
                    opacity: _drawerAnimation.value,
                    duration: const Duration(milliseconds: 300),
                    child: const Text(
                      "Menu",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_showDrawer) {
                        setState(() async {
                          _showDrawer = false;
                          await Future.delayed(const Duration(milliseconds: 3));
                          _animationController.reverse();
                        });
                      } else {
                        setState(() async {
                          _animationController.forward();
                          await Future.delayed(const Duration(milliseconds: 5));

                          _showDrawer = true;
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: AnimatedRotation(
                        turns: _drawerAnimation.value * 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showDrawer = !_showDrawer;
                      _showDrawer
                          ? _animationController.forward()
                          : _animationController.reverse();
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedRotation(
                      turns: _drawerAnimation.value * 0.5,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMenuItem(MenuItemModel item, bool isLarge) {
    final isSelected = widget.pageIndex == item.index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          splashColor: Colors.transparent,
          radius: 0.0,
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: isLarge ? 250 : 80,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConstants.primaryColor.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3))
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppConstants.primaryColor
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: item.assetIcon != null
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: item.cachedAssetImage != null
                              ? Image(
                                  image: item.cachedAssetImage!,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fit: BoxFit.contain,
                                  width: 24,
                                  height: 24,
                                )
                              : Image.asset(
                                  item.assetIcon!,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white70,
                                  fit: BoxFit.contain,
                                  width: 24,
                                  height: 24,
                                ),
                        )
                      : Icon(
                          item.icon ?? Icons.error,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 20,
                        ),
                ),
                if (isLarge && _showDrawer)
                  AnimatedOpacity(
                    opacity: _drawerAnimation.value,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      width: 130, // Increased to accommodate longer titles
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
