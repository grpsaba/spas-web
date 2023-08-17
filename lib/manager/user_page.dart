import 'package:flutter/material.dart';
import 'package:spas_web/manager/manager_list.dart';
import 'package:spas_web/manager/profil_list.dart';
import 'package:spas_web/model.dart';

class UserPage extends StatelessWidget {
  UserPage({super.key, required this.manager});
  Manager manager;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: const TabBar(
            tabs: [Tab(text: "Utilisateurs"), Tab(text: "Profils")],
          ),
          body: TabBarView(children: [
            ManagerList(
              manager: manager,
            ),
            ProfilList(
              manager: manager,
            )
          ]),
        ));
  }
}
