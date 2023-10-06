import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spas_web/administration/start_page.dart';

import '../services/authentication.dart';
import '../services/loading.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _email_ctrl = TextEditingController();
  final TextEditingController _pass_ctrl = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  String _message = "";
  bool _isLogin = false;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _email_ctrl.dispose();
    _pass_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      body: Center(
        child: Container(
          width: 400,
          height: 450,
          padding: const EdgeInsets.only(
              top: 8.0, bottom: 8.0, left: 15.0, right: 15.0),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.indigo.withOpacity(0.5)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                    radius: 64, backgroundImage: AssetImage("assets/logo.png")),
                const SizedBox(
                  height: 20,
                ),
                Form(
                  key: _key,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(20)),
                              height: 48,
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: TextFormField(
                                controller: _email_ctrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                    hintText: "Email",
                                    hintStyle: TextStyle(color: Colors.white),
                                    labelStyle: TextStyle(color: Colors.white),
                                    prefixIcon: Icon(
                                      Icons.phone,
                                      color: Colors.white,
                                    ),
                                    border: InputBorder.none),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(20)),
                              height: 48,
                              padding:
                                  const EdgeInsets.only(left: 8.0, right: 8.0),
                              child: CallbackShortcuts(
                                bindings: <ShortcutActivator, VoidCallback>{
                                  const SingleActivator(
                                      LogicalKeyboardKey.enter): () {
                                    login();
                                  }
                                },
                                child: Focus(
                                  autofocus: true,
                                  child: TextFormField(
                                    controller: _pass_ctrl,
                                    obscureText: true,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                        hintText: "Mot de passe",
                                        hintStyle:
                                            TextStyle(color: Colors.white),
                                        labelStyle:
                                            TextStyle(color: Colors.white),
                                        prefixIcon: Icon(
                                          Icons.sms,
                                          color: Colors.white,
                                        ),
                                        border: InputBorder.none),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 40,
                      ),
                      _isLogin
                          ? Loading(size: 64, inline: false)
                          : CallbackShortcuts(
                              bindings: <ShortcutActivator, VoidCallback>{
                                const SingleActivator(LogicalKeyboardKey.enter):
                                    () {
                                  login();
                                }
                              },
                              child: Focus(
                                autofocus: true,
                                child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        fixedSize: const Size(200, 48),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(20))),
                                    onPressed: () {
                                      login();
                                    },
                                    child: const Text("Connectez-vous")),
                              ),
                            ),
                      const SizedBox(
                        height: 30,
                      ),
                      Text(
                        _message,
                        style: const TextStyle(color: Colors.white),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

//methode de connexion
  void login() {
    if (_key.currentState!.validate()) {
      setState(() {
        _isLogin = true;
        _message = "";
      });
      _authService
          .loginWithEmail(_email_ctrl.text, _pass_ctrl.text)
          .then((user) {
        setState(() {
          _isLogin = false;
          _message = "";
        });
        //your code hier

        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const Starter()));
      }).onError((error, stackTrace) {
        setState(() {
          _isLogin = false;

          switch (error.hashCode) {
            case 495537990:
              _message = "Vérifiez votre connexion internet.";
              break;
            default:
              _message = "Erreur de connexion";
          }
        });
      });
    }
  }
}
