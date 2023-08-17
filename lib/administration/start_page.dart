import 'package:flutter/material.dart';

import '../model.dart';
import '../services/authentication.dart';
import '../services/loading.dart';
import '../services/manager.dart';
import 'home.dart';
import 'login.dart';

class Starter extends StatefulWidget {
  const Starter({super.key});

  @override
  _StarterAgentState createState() => _StarterAgentState();
}

class _StarterAgentState extends State<Starter> {
  final AuthService _authService = AuthService();
  Supervisor? _supervisor;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // TODO: init manager count
    ManagerService().init();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    AuthService().logOut();
  }

  @override
  Widget build(BuildContext context) {
    //initializing the firebase notification

    return FutureBuilder<Manager?>(
        future: _authService.authState(),
        builder: (BuildContext context, AsyncSnapshot<Manager?> snapshot) {
          if (snapshot.hasError) {
            return const Scaffold(
              backgroundColor: Colors.blueGrey,
              body: Center(
                child: Text(
                  "Une erreur c'est produite",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              backgroundColor: Colors.blueGrey,
              body: Center(
                  child: Loading(
                size: 64,
                inline: false,
              )),
            );
          }
          if (snapshot.hasData) {
            print(snapshot.data!.profil?.toJson());
            if (snapshot.data != null) {
              return AdminHome(manager: snapshot.data!);
            } else {
              return const Login();
            }
          } else {
            return const Login();
          }
        });
  }
}
