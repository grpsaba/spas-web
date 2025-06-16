import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/administration/path_error_page.dart';
import 'package:spas_web/agent/add_file_agent.dart';
import 'package:spas_web/agent/agent_form.dart';
import 'package:spas_web/agent/agent_list.dart';
import 'package:spas_web/agent/import_agent.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/notes/imprime_rapport.dart';
import 'package:spas_web/notes/note_list.dart';
import 'package:spas_web/pointage_agent/pointage_agent_list.dart';
import 'package:spas_web/pointage_agent/pointage_rondier_list.dart';
import 'package:spas_web/pointage_site/pointage_site_list.dart';
import 'package:spas_web/pointage_site/site_monthly_pointage.dart';
import 'package:spas_web/pointage_site/site_pointage_map.dart';
import 'package:spas_web/services/authentication.dart';
import 'package:spas_web/site/maps.dart';
import 'package:spas_web/site/site_form.dart';
import 'package:spas_web/site/site_list.dart';
import 'package:spas_web/supervisor/supervisor_form.dart';
import 'package:spas_web/supervisor/supervisor_list.dart';
import 'package:spas_web/supervisor/supervisor_maps.dart';
import 'package:spas_web/supervisor/supervisor_tracker.dart';
import 'package:spas_web/supervisor/supervisors_location.dart';
import 'package:spas_web/tools/checklist.dart';
import 'package:spas_web/tools/tool_form.dart';
import 'package:spas_web/tools/tool_list.dart';
import 'package:spas_web/zone/pointage_zone_list.dart';
import 'package:spas_web/zone/zone_form.dart';
import 'package:spas_web/zone/zone_list.dart';
import 'package:spas_web/zone/zone_pointage_map.dart';
import 'package:spas_web/zone/zone_site_monthly_pointage.dart';
import 'package:spas_web/zone_member/zone_member_form.dart';
import 'package:spas_web/zone_member/zone_member_list.dart';

import 'accueil/home_page.dart';
import 'administration/login.dart';
import 'agent/agent_folder.dart';
import 'agent/search_agent.dart';
import 'agent_type/agentType_form.dart';
import 'agent_type/agentType_list.dart';
import 'categorieTools/catTool_form.dart';
import 'categorieTools/catTool_list.dart';
import 'department/department_form.dart';
import 'department/department_list.dart';
import 'manager/manager_form.dart';
import 'manager/user_page.dart';

GoRouter routeConfig = GoRouter(
    initialLocation: "/home",
    // errorBuilder: (context, state) => const PathErrorPage(),
    onException: (context, state, router) {
      if (state.matchedLocation == '/agent/dossier') {
        router.go('/error', extra: 'Code agent inconnu');
      } else {
        router.go('/error', extra: 'Page Not Found');
      }
    },
    // errorPageBuilder: (context, state) =>
    //     const MaterialPage(child: PathErrorPage()),
    //routes Guard
    redirect: (BuildContext context, GoRouterState state) async {
      if (AuthService.currentManager == null) {
        await AuthService().authState();
      }

      bool isAuthenticated = AuthService.currentManager != null;

      if (isAuthenticated) {
        return null;
      } else {
        if (state.fullPath == "/agents/recherche" ||
            state.fullPath == "/agents/dossier") {
          return null;
        } else if (state.fullPath == '/error' || state.fullPath == '/login') {
          return null;
        }
        return "/login";

        // return null; //to display the intended route without redirecting
      }
    },
    routes: [
      //routes auth
      GoRoute(
          name: "page d'erreur",
          path: "/error",
          builder: (context, state) => const PathErrorPage()),
      GoRoute(
          name: "page d'authentification",
          path: "/login",
          builder: (context, state) => const Login()),
      GoRoute(
          name: "Tableau de bord",
          path: "/home",
          builder: (context, state) {
          
            return HomePage();
          }),
      //routes manager/user
      GoRoute(
          name: "liste des utilisateur",
          path: "/users",
          builder: (context, state) => UserPage(),
          routes: [
            GoRoute(
                name: "Ajoute un utilisateur",
                path: "add",
                builder: (context, state) => AddManager(
                      manager: state.extra as Manager,
                    )),
          ]),
      //routes site
      GoRoute(
          name: "liste des sites",
          path: "/sites",
          builder: (context, state) => const SiteList(),
          routes: [
            GoRoute(
                name: "Ajoute un site",
                path: "add",
                builder: (context, state) => AddSite(
                      site: state.extra as Site,
                    )),
            GoRoute(
                name: "sites maps",
                path: "maps",
                builder: (context, state) => const Maps()),
          ]),
      //routes pointages site
      GoRoute(
          name: "liste des pointages",
          path: "/pointages",
          builder: (context, state) => const PointageSiteList(),
          routes: [
            GoRoute(
                name: "rapport de pointage",
                path: "spm",
                builder: (context, state) => SitePointageMap(
                      date: state.extra as DateTime,
                    )),
            GoRoute(
                name: "rapport de pointage mensuel des sites",
                path: "smp",
                builder: (context, state) => SiteMonthlyPointage(
                      date: state.extra as DateTime,
                    )),
          ]),
      //routes Agents
      GoRoute(
          name: "liste des agents",
          path: "/agents",
          builder: (context, state) => const AgentList(),
          routes: [
            GoRoute(
                name: "Ajoute un agent",
                path: "add",
                builder: (context, state) => AddAgent(
                      agent: state.extra as Agent,
                    )),
            GoRoute(
                name: "import agents",
                path: "import",
                builder: (context, state) => const ImportAgent()),
            GoRoute(
                name: "documents agents",
                path: "documents",
                builder: (context, state) =>
                    AgentAddFile(agent: state.extra as Agent)),
            GoRoute(
                name: "dossier agent",
                path: "dossier",
                builder: (context, state) => AgentFolder(
                      code: state.extra as String,
                    )),
            GoRoute(
                name: "rechercher un agent",
                path: "recherche",
                builder: (context, state) => const SearchAgent()),
          ]),
      //routes superviseurs
      GoRoute(
          name: "liste des superviseurs",
          path: "/superviseurs",
          builder: (context, state) => const SupervisorList(),
          routes: [
            GoRoute(
                name: "Ajoute un superviseur",
                path: "add",
                builder: (context, state) => AddSupervisor(
                      supervisor: state.extra as Supervisor,
                    )),
            GoRoute(
                name: "position des superviseurs",
                path: "maps",
                builder: (context, state) => const SupervisorMaps()),
            GoRoute(
                name: "position d'un superviseur",
                path: "location",
                builder: (context, state) =>
                    SupervisorTracker(supervisor: state.extra as Supervisor)),
            //routes locations
            GoRoute(
              name: "supervisors location",
              path: "locationtracker",
              builder: (context, state) => const SupervisorsLocation(),
            ),
          ]),
      //routes tools
      GoRoute(
          name: "liste des materiaux",
          path: "/tools",
          builder: (context, state) => const ToolList(),
          routes: [
            GoRoute(
                name: "Ajoute un materiel",
                path: "add",
                builder: (context, state) => AddTool(
                      tool: state.extra as Tool,
                    )),
          ]),
      //routes pointage Agent
      GoRoute(
        name: "liste des pointages agent",
        path: "/pointageagents",
        builder: (context, state) => const PointageAgentList(),
      ),
      GoRoute(
          name: "pointage rondier",
          path: "/pointagesrondiers",
          builder: (context, state) => const PointageRondierList()),
      //routes Checklist
      GoRoute(
        name: "liste des Checklist",
        path: "/checklist",
        builder: (context, state) => const CheckListView(),
      ),

      //routes notes
      GoRoute(
          name: "liste des notes",
          path: "/notes",
          builder: (context, state) => const NoteList(),
          routes: [
            GoRoute(
                name: "rapport",
                path: "rapport",
                builder: (context, state) => ImprimeRapport(
                      source: state.extra as String,
                    )),
          ]),

      //routes equipements
      GoRoute(
          name: "liste des equipements",
          path: "/equipements",
          builder: (context, state) => const CatToolList(),
          routes: [
            GoRoute(
                name: "Ajoute un equipement",
                path: "add",
                builder: (context, state) => AddCatTool(
                      catTool: state.extra as CategorieTool,
                    )),
          ]),
      //routes departements
      GoRoute(
          name: "liste des departements",
          path: "/departements",
          builder: (context, state) => const DepartmentList(),
          routes: [
            GoRoute(
                name: "Ajoute un departement",
                path: "add",
                builder: (context, state) => AddDepatment(
                      department: state.extra as Department,
                    )),
          ]),
      //routes type agent
      GoRoute(
          name: "liste des types agent",
          path: "/typesagent",
          builder: (context, state) => const AgentTypeList(),
          routes: [
            GoRoute(
                name: "Ajoute un type agent",
                path: "add",
                builder: (context, state) => AddAgentYpe(
                      agType: state.extra as AgentType,
                    )),
          ]),
      //routes zone
      GoRoute(
          name: "liste des zones",
          path: "/zones",
          builder: (context, state) => const ZoneList(),
          routes: [
            GoRoute(
                name: "Ajoute une zone",
                path: "add",
                builder: (context, state) => AddZone(
                      zone: state.extra as Zone,
                    )),
          ]),
      //routes pointagezones
      GoRoute(
          name: "liste des pointages zone",
          path: "/pointagezones",
          builder: (context, state) => const PointageZone(),
          routes: [
            GoRoute(
                name: "Rapport nombre de pointage par chef de zone",
                path: "npcz",
                builder: (context, state) => SitePointageZoneMap(
                      date: state.extra as DateTime,
                    )),
            GoRoute(
                name: "Nombre de visite des sites par chef de zone",
                path: "nvcz",
                builder: (context, state) => ZoneSiteMonthlyPointage(
                      date: state.extra as DateTime,
                    )),
          ]),
      //routes chefszone
      GoRoute(
          name: "liste des chefs de zone",
          path: "/chefszone",
          builder: (context, state) => const ZoneMemberList(),
          routes: [
            GoRoute(
                name: "Ajoute un chef de zone",
                path: "add",
                builder: (context, state) => AddZoneMember(
                      zoneMember: state.extra as ZoneMember,
                    )),
          ]),
    ]);
