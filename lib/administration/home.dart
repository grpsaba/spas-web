import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/sos_wiget.dart';
import 'package:spas_web/generated/assets.dart';

import '../const.dart';
import '../services/authentication.dart';

class PageModel extends StatefulWidget {
  PageModel(
      {super.key,
      required this.child,
      required this.pageIdex,
      required this.titile});

  Widget child;
  int pageIdex;
  String titile;
  @override
  _PageModelState createState() => _PageModelState();
}

class _PageModelState extends State<PageModel> {
  //final SiteService _siteServicef = SiteService();

  bool _howDrawer = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor:
            widget.pageIdex == 0 ? AppConstants.bgColor : Colors.white,
        appBar: AppBar(
          leading: const Image(
            image: AssetImage("assets/logo.png"),
          ),
          backgroundColor: AppConstants.primaryColor,
          actions: [
            Sos(),
            Text(
              "${AuthService.currentManager!.firstName} ${AuthService.currentManager!.lastName}",
              style: const TextStyle(color: Colors.white),
            ),
            IconButton(
                onPressed: () {
                  AuthService().logOut().then((value) {
                    context.go('/login');
                  });
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                )),
          ],
          title: StreamBuilder(
            stream:
                Stream<String>.periodic(const Duration(seconds: 1), (value) {
              return "${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}";
            }),
            builder: (context, AsyncSnapshot<String> snapshot) {
              return Text(
                "${widget.titile} ${snapshot.data ?? ""}",
                style: const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Menu
            drawer(),
            //contant
            Expanded(
              child: widget.child,
            )
          ],
        ));
  }

  Widget drawer() {
    return Drawer(
      width: _howDrawer ? null : 80,
      backgroundColor: AppConstants.bgColor,
      elevation: 0.0,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Menu",
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
                IconButton(
                    onPressed: () {
                      setState(() {
                        _howDrawer = _howDrawer ? false : true;
                      });
                    },
                    icon: _howDrawer
                        ? const Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                          )),
              ],
            ),
            Column(
              children: [
                ListTile(
                  selected: widget.pageIdex == 0,
                  onTap: () {
                    context.go("/home");
                    if (_howDrawer) {
                      Navigator.of(context).pop();
                    }
                  },
                  leading: CircleAvatar(
                      radius: 18,
                      child: Icon(
                        Icons.home,
                        color: Theme.of(context).primaryColor,
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Home",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                ),
                ListTile(
                  onTap: () {
                    context.go("/users");
                    if (_howDrawer) {
                      Navigator.of(context).pop();
                    }
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconManager),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "PC",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 1,
                ),
                ListTile(
                  onTap: () {
                    context.go("/sites");
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconSite),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Sites",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 2,
                ),
                ListTile(
                  onTap: () {
                    context.go("/agents");
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconAgent),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Agents",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 3,
                ),
                ListTile(
                  onTap: () {
                    context.go('/superviseurs');
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsAgent),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Superviseurs",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 4,
                ),
                ListTile(
                  onTap: () {
                    context.go("/tools");
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconTools),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Matériaux",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 5,
                ),
                ListTile(
                  onTap: () {
                    context.go(
                      '/pointages',
                    );
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconScansite),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Pointage Sites",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 6,
                ),
                ListTile(
                  onTap: () {
                    context.go("/pointageagents");
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconScanAgent),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Pointage Agents",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 7,
                ),
                ListTile(
                  onTap: () {
                    context.go("/checklist");
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconScanTools),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Pointages matériel",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 8,
                ),
                ListTile(
                  onTap: () {
                    context.go("/notes");
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconNote2),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Observations",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 9,
                ),
                ListTile(
                  onTap: () {
                    context.go("/sites/maps");
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconMap),
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Sites maps",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 10,
                ),
                ListTile(
                  onTap: () {
                    context.go("/equipements");
                  },
                  leading: CircleAvatar(
                      radius: 18,
                      child: Icon(
                        Icons.category_rounded,
                        color: Theme.of(context).primaryColor,
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Equipements",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 11,
                ),
                ListTile(
                  onTap: () {
                    context.go("/departements");
                  },
                  leading: CircleAvatar(
                      radius: 18,
                      child: Icon(
                        Icons.apartment,
                        color: Theme.of(context).primaryColor,
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Département",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 12,
                ),
                ListTile(
                  onTap: () {
                    context.go("/typesagent");
                  },
                  leading: CircleAvatar(
                      radius: 18,
                      child: Icon(
                        Icons.supervised_user_circle,
                        color: Theme.of(context).primaryColor,
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Type Agent",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 13,
                ),
                ListTile(
                  onTap: () {
                    context.go("/zones");
                  },
                  leading: CircleAvatar(
                      radius: 18,
                      child: Icon(
                        Icons.map_sharp,
                        color: Theme.of(context).primaryColor,
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Zones",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 14,
                ),
                ListTile(
                  onTap: () {
                    context.go("/pointagezones");
                  },
                  leading: CircleAvatar(
                      radius: 18,
                      child: Icon(
                        Icons.qr_code_scanner,
                        color: Theme.of(context).primaryColor,
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Pointages Zone",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 15,
                ),
                ListTile(
                  onTap: () {
                    context.go("/chefszone");
                  },
                  leading: CircleAvatar(
                      radius: 18,
                      child: Icon(
                        Icons.perm_contact_cal,
                        color: Theme.of(context).primaryColor,
                      )),
                  title: !_howDrawer
                      ? null
                      : const Text(
                          "Chef de zone",
                          style: TextStyle(color: AppConstants.textColor),
                        ),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: widget.pageIdex == 16,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
