import 'dart:math';

import 'package:animated_background/animated_background.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/sos_wiget.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';

import '../services/authentication.dart';
import '../services/loading.dart';
import '../services/player.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final TextEditingController _email_ctrl = TextEditingController();
  final TextEditingController _pass_ctrl = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  String _message = "";
  bool _isLogin = false;
  Consigne_model consigne = Consigne_model(consigne: "", tache: "");
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    consigne = getCondignDuJours();
    TTS().speetch(consigne.tache);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _email_ctrl.dispose();
    _pass_ctrl.dispose();
  }

  Consigne_model getCondignDuJours() {
    int index = Random().nextInt(AppConstants.consignes.length - 1);
    return AppConstants.consignes[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
            options: const ParticleOptions(
                baseColor: Colors.white, spawnMaxRadius: 7)),
        vsync: this,
        child: Center(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Sos(),
                const SizedBox(
                  height: 10,
                ),
                const Text(
                  "CONSIGNES DU JOUR",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(
                  height: 10,
                ),
                Chip(
                  side: BorderSide.none,
                  backgroundColor: Colors.white.withOpacity(0.4),
                  label: Text(
                    consigne.consigne,
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      consigne.tache,
                      textStyle: const TextStyle(
                        color: Colors.white,
                      ),
                      speed: const Duration(milliseconds: 100),
                    ),
                  ],
                  totalRepeatCount: 4,
                  pause: const Duration(milliseconds: 50),
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  width: 400,
                  height: 450,
                  padding: const EdgeInsets.only(
                      top: 8.0, bottom: 8.0, left: 15.0, right: 15.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.blueGrey.withOpacity(0.5)),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                            radius: 64,
                            backgroundImage: AssetImage("assets/logo.png")),
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
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      height: 48,
                                      padding: const EdgeInsets.only(
                                          left: 8.0, right: 8.0),
                                      child: TextFormField(
                                        controller: _email_ctrl,
                                        style: const TextStyle(
                                            color: Colors.white),
                                        decoration: const InputDecoration(
                                            hintText: "Email",
                                            hintStyle:
                                                TextStyle(color: Colors.white),
                                            labelStyle:
                                                TextStyle(color: Colors.white),
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
                                          borderRadius:
                                              BorderRadius.circular(20)),
                                      height: 48,
                                      padding: const EdgeInsets.only(
                                          left: 8.0, right: 8.0),
                                      child: CallbackShortcuts(
                                        bindings: <ShortcutActivator,
                                            VoidCallback>{
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
                                            style: const TextStyle(
                                                color: Colors.white),
                                            decoration: const InputDecoration(
                                                hintText: "Mot de passe",
                                                hintStyle: TextStyle(
                                                    color: Colors.white),
                                                labelStyle: TextStyle(
                                                    color: Colors.white),
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
                                      bindings: <ShortcutActivator,
                                          VoidCallback>{
                                        const SingleActivator(
                                            LogicalKeyboardKey.enter): () {
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
                                                        BorderRadius.circular(
                                                            20))),
                                            onPressed: () {
                                              login();
                                            },
                                            child:
                                                const Text("Connectez-vous")),
                                      ),
                                    ),
                              const SizedBox(
                                height: 30,
                              ),
                              /* TextButton(
                                  onPressed: () async {
                                    List<Agent> agents =
                                        await AgentService().allFuture();
                                    /* agents = agents.where((element) {
                                      if (element.site != null) {
                                        return element.site!.UID !=
                                            "rXkVVl9AH8MYSPn25FSHS7eESpc2";
                                      } else {
                                        return true;
                                      }
                                    }).toList();*/

                                    for (Agent ag in agents) {
                                      /* Agent newAg = Agent(
                                          code: "",
                                          firstName: ag.firstName,
                                          lastName: ag.lastName,
                                          phone: ag.phone,
                                          email: ag.email,
                                          tracking: ag.tracking,
                                          site: ag.site,
                                          department: ag.department,
                                          typeAgent: ag.typeAgent,
                                          actif: ag.actif,
                                          docs: ag.docs,
                                          contacts: ag.contacts,
                                          dateEmbauche: ag.dateEmbauche,
                                          dateArret: ag.dateArret);*/
                                      //newAg.genererCode();
                                      // AgentService().add(newAg);
                                      if (int.tryParse(ag.phone) == null) {
                                        ag.phone = "";
                                      }
                                      AgentService().update(ag);
                                    }
                                    MotionToast.success(description: Text("OK"))
                                        .show(context);
                                  },
                                  child: Text(
                                    "update all agent",
                                    style: TextStyle(color: Colors.white),
                                  )),*/
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
              ],
            ),
          ),
        ),
      ),
    );
  }

//methode de connexion
  void login() async {
    if (_key.currentState!.validate()) {
      setState(() {
        _isLogin = true;
        _message = "";
      });
      _authService
          .loginWithEmail(_email_ctrl.text, _pass_ctrl.text)
          .then((user) async {
        await _authService.authState();
        setState(() {
          _isLogin = false;
          _message = "";
        });
        //your code hier

        if (mounted) context.go('/home');
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
