import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/manager/manager_list.dart';
import 'package:spas_web/manager/profil_list.dart';

class UserPage extends StatelessWidget {
  UserPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIdex: 1,
      titile: "Gestion utilisateurs",
      child: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.person), text: "Utilisateurs"),
                Tab(icon: Icon(Icons.work), text: "Profils")
              ],
            ),
            body: TabBarView(children: [ManagerList(), ProfilList()]),
          )),
    );
  }
}
