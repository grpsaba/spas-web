import 'package:animated_background/animated_background.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/const.dart';

class SearchAgent extends StatefulWidget {
  const SearchAgent({super.key});

  @override
  _SearchAgentState createState() => _SearchAgentState();
}

class _SearchAgentState extends State<SearchAgent>
    with TickerProviderStateMixin {
  final TextEditingController _code_ctrl = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    _code_ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgColor,
      body: AnimatedBackground(
        behaviour: RandomParticleBehaviour(
            options: const ParticleOptions(
                baseColor: Colors.white, spawnMaxRadius: 10)),
        vsync: this,
        child: Center(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 10,
                ),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      "GROUPE SABA",
                      textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.only(
                      top: 8.0, bottom: 8.0, left: 15.0, right: 15.0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppConstants.primaryColor.withOpacity(0.5)),
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
                              SizedBox(
                                width: 300,
                                child: TextFormField(
                                  controller: _code_ctrl,
                                  validator: (value) {
                                    return value!.isNotEmpty
                                        ? null
                                        : "Code obligatoire";
                                  },
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    filled: true,
                                    fillColor: AppConstants.bgColor,
                                    hintText: "Inserer le code l'agent",
                                    hintStyle: TextStyle(color: Colors.white),
                                    labelStyle: TextStyle(
                                        color: Colors.white, fontSize: 20),
                                    prefixIcon: Icon(
                                      Icons.vpn_key,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 40,
                              ),
                              ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppConstants.bgColor,
                                      fixedSize: const Size(200, 48),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20))),
                                  onPressed: () {
                                    if (_key.currentState!.validate()) {
                                      context.go("/agents/dossier",
                                          extra: _code_ctrl.text);
                                    }
                                  },
                                  child: const Text(
                                    "Rechercher",
                                    style: TextStyle(color: Colors.white),
                                  )),
                              const SizedBox(
                                height: 40,
                              ),
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
}
