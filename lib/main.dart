import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:spas_web/router.dart';
import 'package:url_strategy/url_strategy.dart';

import 'const.dart';
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
    return MaterialApp.router(
      routerConfig: routeConfig,
      debugShowCheckedModeBanner: false,
      title: 'SPAS GROUPE SABA',
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
          textTheme: GoogleFonts.robotoTextTheme(),
          /*textTheme: GoogleFonts.robotoTextTheme().copyWith(
              titleLarge: const TextStyle(color: AppConstants.textColor),
              titleMedium: const TextStyle(color: AppConstants.textColor),
              titleSmall: const TextStyle(color: AppConstants.textColor),
              bodyLarge: const TextStyle(color: AppConstants.textColor),
              bodySmall: const TextStyle(color: AppConstants.textColor),
              bodyMedium: const TextStyle(color: AppConstants.textColor),
              labelLarge: const TextStyle(color: AppConstants.textColor),
              labelMedium: const TextStyle(color: AppConstants.textColor),
              labelSmall: const TextStyle(color: AppConstants.textColor),
              headlineLarge: const TextStyle(color: AppConstants.textColor),
              displayLarge: const TextStyle(color: AppConstants.textColor),
              displayMedium: const TextStyle(color: AppConstants.textColor),
              displaySmall: const TextStyle(color: AppConstants.textColor),
            ),*/

          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          colorSchemeSeed: AppConstants.primaryColor,
          fontFamily: GoogleFonts.roboto().fontFamily),
    );
  }
}
