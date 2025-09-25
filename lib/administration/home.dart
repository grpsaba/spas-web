import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/sos_wiget.dart';
import 'package:spas_web/models/menu_item_model.dart';
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

class _PageModelState extends State<PageModel> with SingleTickerProviderStateMixin {
  bool _showDrawer = false;
  // late AnimationController _animationController;
  // late Animation<double> _drawerAnimation;

  @override
  void initState() {
    super.initState();
    // _animationController = AnimationController(
    //   duration: const Duration(milliseconds: 300),
    //   vsync: this,
    // );
    // _drawerAnimation = Tween<double>(
    //   begin: 0.0,
    //   end: 1.0,
    // ).animate(CurvedAnimation(
    //   parent: _animationController,
    //   curve: Curves.easeInOut,
    // ));
  }

  @override
  void dispose() {
    //_animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.pageIndex == 0 ? AppConstants.bgColor : Colors.white,
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
              "${manager.firstName[0]}${manager.lastName[0]}",
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
          await AuthService().logOut();
          if (context.mounted) {
            context.go('/login');
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: _showDrawer ? 250 : 80,
      child: Container(
        decoration: BoxDecoration(
          color: AppConstants.bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildMenuItems(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: _showDrawer 
        ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Menu",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showDrawer = !_showDrawer;
                    });
                  //  _animationController.reverse();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedRotation(
                      turns: _showDrawer ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 100),
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
                  });
                 // _animationController.forward();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: AnimatedRotation(
                    turns: _showDrawer ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 100),
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

  Widget _buildMenuItems() {
    return Column(
      children: MenuItemModel.menuItems.map((item) => _buildMenuItem(item)).toList(),
    );
  }

  Widget _buildMenuItem(MenuItemModel item) {
    final isSelected = widget.pageIndex == item.index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppConstants.primaryColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppConstants.primaryColor
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: item.assetIcon != null
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: item.cachedAssetImage != null
                              ? Image(
                                  image: item.cachedAssetImage!,
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fit: BoxFit.contain,
                                  width: 24,
                                  height: 24,
                                )
                              : Image.asset(
                                  item.assetIcon!,
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fit: BoxFit.contain,
                                  width: 24,
                                  height: 24,
                                ),
                        )
                      : Icon(
                          item.icon,
                          color: isSelected ? Colors.white : Colors.white70,
                          size: 20,
                        ),
                ),
                // Utiliser ClipRect pour éviter l'overflow pendant l'animation
                ClipRect(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: _showDrawer ? null : 0,
                    child: _showDrawer ? Row(
                      children: [
                        const SizedBox(width: 10),
                        Flexible(
                          child: AnimatedOpacity(
                            opacity: _showDrawer ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              item.title,
                              style: TextStyle(
                                color: Colors.white,//isSelected ? Colors.white : Colors.white70,
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                overflow: TextOverflow.ellipsis
                              ),
                            ),
                          ),
                        ),
                      ],
                    ) : const SizedBox.shrink(),
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


