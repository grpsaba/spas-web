import 'package:flutter/material.dart';
import 'package:spas_web/administration/pointage_agent_list.dart';
import 'package:spas_web/administration/pointage_site_list.dart';
import 'package:spas_web/administration/pointage_tool_list.dart';
import 'package:spas_web/administration/sos_wiget.dart';
import 'package:spas_web/administration/start_page.dart';
import 'package:spas_web/agent/agent_list.dart';
import 'package:spas_web/generated/assets.dart';
import 'package:spas_web/manager/manager_list.dart';
import 'package:spas_web/site/site_list.dart';
import 'package:spas_web/supervisor/supervisor_list.dart';
import 'package:spas_web/tools/tool_list.dart';

import '../accueil/home_page.dart';
import '../accueil/maps.dart';
import '../const.dart';
import '../model.dart';
import '../services/authentication.dart';
import '../services/site.dart';
import 'note_list.dart';

class AdminHome extends StatefulWidget {
  AdminHome({super.key, required this.manager});
  Manager manager;
  @override
  _AdminHomeState createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  final SiteService _siteService = SiteService();

  int _menuIdex = 0;
  bool _howDrawer = false;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  void navigeTo(int index) {
    setState(() {
      _menuIdex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppConstants.bacgroundColors,
        appBar: AppBar(
          leading: const Image(
            image: AssetImage("assets/logo.png"),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            const Sos(),
            Text(
              "${widget.manager.firstName} ${widget.manager.lastName}",
              style: const TextStyle(color: Colors.white),
            ),
            IconButton(
                onPressed: () {
                  AuthService().logOut().then((value) => {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (_) => const Starter()))
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
                "SPAS GROUPE SABA ${snapshot.data ?? ""}",
                style: TextStyle(color: Colors.white),
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
              child: switchPage(),
            )
          ],
        ));
  }

  Widget drawer() {
    return Drawer(
      width: _howDrawer ? null : 80,
      backgroundColor: AppConstants.bacgroundColors,
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
                  style: TextStyle(fontSize: 15),
                ),
                IconButton(
                    onPressed: () {
                      setState(() {
                        _howDrawer = _howDrawer ? false : true;
                      });
                    },
                    icon: _howDrawer
                        ? const Icon(Icons.arrow_back_ios)
                        : const Icon(Icons.arrow_forward_ios)),
              ],
            ),
            Column(
              children: [
                ListTile(
                  selected: _menuIdex == 0,
                  onTap: () {
                    navigeTo(0);
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
                  title: !_howDrawer ? null : const Text("Home"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(1);
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
                  title: !_howDrawer ? null : const Text("PC"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 1,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(2);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconSite),
                      )),
                  title: !_howDrawer ? null : const Text("Sites"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 2,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(3);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconAgent),
                      )),
                  title: !_howDrawer ? null : const Text("Agents"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 3,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(4);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsAgent),
                      )),
                  title: !_howDrawer ? null : const Text("Superviseurs"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 4,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(5);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconTools),
                      )),
                  title: !_howDrawer ? null : const Text("Matériaux"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 5,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(6);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconScansite),
                      )),
                  title: !_howDrawer ? null : const Text("Pointage Sites"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 6,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(7);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconScanAgent),
                      )),
                  title: !_howDrawer ? null : const Text("Pointage Agents"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 7,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(8);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconScanTools),
                      )),
                  title: !_howDrawer ? null : const Text("Pointages matériel"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 8,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(9);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconNote2),
                      )),
                  title: !_howDrawer ? null : const Text("Observations"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 9,
                ),
                ListTile(
                  onTap: () {
                    navigeTo(10);
                  },
                  leading: const CircleAvatar(
                      radius: 18,
                      child: Image(
                        fit: BoxFit.contain,
                        image: AssetImage(Assets.assetsIconMap),
                      )),
                  title: !_howDrawer ? null : const Text("Sites maps"),
                  hoverColor: Colors.grey.withOpacity(0.1),
                  selectedTileColor: Colors.blueGrey,
                  selectedColor: Colors.white,
                  style: ListTileStyle.drawer,
                  selected: _menuIdex == 10,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget switchPage() {
    switch (_menuIdex) {
      case 0:
        return const HomePage();
      case 1:
        return const ManagerList();
      case 2:
        return const SiteList();
      case 3:
        return const AgentList();
      case 4:
        return const SupervisorList();
      case 5:
        return const ToolList();
      case 6:
        return const PointageSiteList();
      case 7:
        return const PointageAgentList();
      case 8:
        return const PointageToolList();
      case 9:
        return const NoteList();
      case 10:
        return const Maps();
      default:
        return const Center(
          child: Text("Page non disponible"),
        );
    }
  }
}
