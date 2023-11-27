import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bootstrap5/flutter_bootstrap5.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_strategy/url_strategy.dart';

import 'administration/start_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  //Audio().stopSOs();
  //enlever le # dans url de la page
  setPathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //le flutter bootstrap5 est indiquer ici mais exploiter
    return FlutterBootstrap5(
      builder: (context) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SPAS GROUPE SABA',
          //le theme bootstrap par défaut est changé ici
          theme: BootstrapTheme.of(context).toTheme(
              theme: ThemeData(
                  // This is the theme of your application.
                  //
                  // Try running your application with "flutter run". You'll see the
                  // application has a blue toolbar. Then, without quitting the app, try
                  // changing the primarySwatch below to Colors.green and then invoke
                  // "hot reload" (press "r" in the console where you ran "flutter run",
                  // or simply save your changes to "hot reload" in a Flutter IDE).
                  // Notice that the counter didn't reset back to zero; the application
                  // is not restarted.
                  //textTheme: GoogleFonts.robotoTextTheme(),
                  scaffoldBackgroundColor: Colors.white,
                  useMaterial3: true,
                  colorSchemeSeed: Colors.indigo,
                  fontFamily: GoogleFonts.roboto().fontFamily)),
          home: const Starter()),
    );
  }
}
