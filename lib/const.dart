import 'package:flutter/material.dart';

import 'model.dart';

class AppConstants {
  static double dialogWidth = 400.0;
  static double dialogHeight = 400.0;
  static Color bacgroundColors = Colors.grey.withOpacity(0.1);
  static String oragnisationName = "Groupe SABA";
  static List<Module> moduleList = [
    Module(
        moduleName: ModuleName.MANAGER,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.AGENT,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.SUPERVISEUR,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.SITE,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.NOTE,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.TOOL,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.TABLEAU_DE_BORD,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.CATEGORIE_TOOL,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false)
  ];
}
