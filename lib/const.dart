import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'model.dart';

class AppConstants {
  static const bgColor = Color(0xFF404040);
  static Color secondaryColor = const Color(0xFF727171).withOpacity(0.4);
  static const primaryColor = Colors.indigo;
  static const textColor = Colors.white;
  static double dialogWidth = 400.0;
  static double dialogHeight = 400.0;
  static String oragnisationName = "Groupe SABA";
  static String maps_api_key = "AIzaSyA550YQ-pZ6mwNZI-iHfcjIOZoO1TMEMl0";
  static BitmapDescriptor defaultMarkerIcon = BitmapDescriptor.defaultMarker;
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
        generBadge: false),
    Module(
        moduleName: ModuleName.DEPARTMENT,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.AGENT_TYPE,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.ZONE,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.ZONE_MEMBER,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.POINTAGE_SITE,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.POINTAGE_AGENT,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.POINTAGE_RONDIER,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.POINTAGE_TOOL,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.POINTAGE_ZONE,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false),
    Module(
        moduleName: ModuleName.ERROR_LOG,
        add: true,
        delete: false,
        validation: false,
        view: true,
        print: false,
        generBadge: false)
  ];

  static List<Autorisation_model> autorisations = [
    Autorisation_model(
        autorisation:
            "Autoriser à apporter ou à consommer de la nourriture, de la sucrerie et toutes autres boissons non alcoolisées et non interdites. ",
        interdiction:
            "Interdiction formelle de consommer des stupéfiants, alcool et autres produits néfastes sur le site."),
    Autorisation_model(
        autorisation: "Autoriser à être devant la porte du site.",
        interdiction:
            "Interdire d’entretenir des relations sexuelles sur le site."),
    Autorisation_model(
        autorisation:
            "Autoriser à faire le tour du site selon les consignes donner.",
        interdiction:
            "Interdire d’entretenir des relations amoureuses de quelque nature que ce soit avec les occupants du site."),
    Autorisation_model(
        autorisation:
            "Autoriser à prévenir les autorités locales en cas d’incident majeure ou soupçon de terrorisme.",
        interdiction: "Interdire de quitter son uniforme, chaussure…"),
    Autorisation_model(
        autorisation: "Autoriser à rentrer dans les toilettes.",
        interdiction:
            "Interdire de porter les armes blanches et celles non autorisées selon les consignes du site."),
    Autorisation_model(
        autorisation:
            "Autoriser à utiliser ses effets personnes ; à bien les ranger.",
        interdiction:
            "Interdire de faire des injures, bagarres et tout autre comportement pouvant nuire aux intérêts de la société et du client."),
    Autorisation_model(
        autorisation: "Autoriser à porter les vêtements de pluie.",
        interdiction:
            "Interdire d’utiliser le matériel (ustensiles ou matériels de toutes natures que ce soit …)"),
    Autorisation_model(
        autorisation: "Autoriser à donner des informer à sa hiérarchie.",
        interdiction: "Interdire de dormir sur le site."),
    Autorisation_model(
        autorisation: "",
        interdiction:
            "Interdire de prendre des colis sans l’accord du résident."),
    Autorisation_model(
        autorisation: "",
        interdiction: "Interdire d’abandonner son site sans motif valable."),
    Autorisation_model(
        autorisation: "", interdiction: "Interdire de voler ou d’escroquer."),
    Autorisation_model(
        autorisation: "", interdiction: "Interdire de faire le ménage."),
    Autorisation_model(
        autorisation: "",
        interdiction:
            "Interdire de voyager avec le résident pendant le service."),
    Autorisation_model(
        autorisation: "", interdiction: "Interdire de venir en retard."),
    Autorisation_model(
        autorisation: "",
        interdiction:
            "Interdire de s’absenter ou d’abandonner le site sans motif valable.")
  ];

  static List<Consigne_model> consignes = [
    Consigne_model(
        consigne: "SURVEILLANCE",
        tache:
            "APS doit assurer la protection des résidents, leurs biens, leur intégrité et leur honneur."),
    Consigne_model(
        consigne: "DETECTION/ FILTRAGE ACCES",
        tache:
            "APS doit impérativement connaitre tous les résidents permanents et temporaires. Il lui est formellement interdit de faire rentrer un intrus sans le consentement du /des résidents."),
    Consigne_model(
        consigne: "OUVERUTRE/ FERMETURE",
        tache:
            "APS doit veiller sur les accès du site. Doit ouvrir les portes ou les portails selon les instructions du/des résidents."),
    Consigne_model(
        consigne: "COURTOISIE/RECEPTION VISITEUR",
        tache:
            "APS doit impérativement être courtois, poli et respectueux.Il doit pouvoir maitriser n'importe quel type de situation se présentant à lui."),
    Consigne_model(
        consigne: "PROPRETE DU SITE",
        tache:
            "APS doit maintenir son lieu de travail propre, les toilettes et autres."),
    Consigne_model(
        consigne: "INCENDIE",
        tache:
            "APS doit signaler tout soupçon d’incendie ou toutes anomalie pouvant provoquer un incendie.En cas d’incendie, il doit prévenir, le résident et ses responsables."),
    Consigne_model(
        consigne: "ANOMALIE",
        tache:
            "APS doit signaler tout soupçon d’incendie ou toutes anomalie pouvant provoquer un incendie.En cas d’incendie, il doit prévenir, le résident et ses responsables."),
    Consigne_model(
        consigne: "PORTE DOMICILE",
        tache:
            "APS doit maintenir les portes closes. Il doit aussi vérifier les fermetures et signaler les anomalies."),
    Consigne_model(
        consigne: "RONDE SUR LES SITES",
        tache:
            "APS faire le contour du site de font à comble ; signaler toute anomalie et autres. le Superviseur doit se rendre sur les sites au moins deux (2) le jour et une fois la nuit."),
  ];
}
