import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:spas_web/accueil/pointage_site_card.dart';
import 'package:spas_web/accueil/site_card.dart';
import 'package:spas_web/accueil/site_pointing_staus_list.dart';
import 'package:spas_web/accueil/site_staus_list.dart';
import 'package:spas_web/accueil/supervisor_card.dart';
import 'package:spas_web/accueil/tool_status_card.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/providers/home_provider.dart';
import 'package:spas_web/services/agentType.dart';
import 'package:spas_web/services/authentication.dart';

import '../zone/progression_pointage_zone.dart';
import 'absenceAgent.dart';
import 'agent_card.dart';
import 'note_card.dart';

class HomePage extends StatefulWidget {
  // final Manager? manager;
  HomePage({
    super.key,

    ///required this.manager,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late HomeProvider homeProvider;
  @override
  void initState() {
    // TODO: implement initState
    homeProvider = Provider.of<HomeProvider>(context, listen: false);
    homeProvider.getSites();
    homeProvider.getSupvisor();
    super.initState();
  }

  final manager = AuthService.currentManager;

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(builder: (context, value, child) {
      return PageModel(
        titile: "SPAS GROUPE SABA",
        pageIdex: 0,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: value.sites.isEmpty || value.supvisor.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      manager != null && !value.greeting
                          ? Text(
                              "Bienvenue ${manager!.lastName}",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26),
                            )
                          : const SizedBox.shrink(),
                      const SizedBox(
                        width: 12,
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        // flutter build web
                        // firebase deploy --only hosting

                        children: [
                          Text(
                            "Chargement ...",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 20),
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          CircularProgressIndicator()
                        ],
                      ),
                    ],
                  ),
                )
              : ListView(
                  //mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.0),
                          color: AppConstants.bgColor),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                homeProvider.cleanArrays();
                                homeProvider.onRefresh();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Recharger ",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Icon(
                                      Icons.refresh,
                                      size: 35,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            PointageSiteCard(nombreSite: value.nbSite),
                            const SizedBox(
                              width: 10,
                            ),
                            SiteCard(
                              nombreSites: value.nbSite,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Skeletonizer(
                                enabled: value.supvisor.isEmpty,
                                child: SupervisorCard(
                                    superviseur: value.supvisor)),
                            const SizedBox(
                              width: 10,
                            ),
                            //Liste Agent
                            FutureBuilder(
                                future: AgentTypeService().allFuture(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    List<AgentType> data = snapshot.data ?? [];

                                    return Row(
                                      children: data
                                          .map((type) => Padding(
                                                padding: const EdgeInsets.only(
                                                    right: 4.0, left: 4.0),
                                                child: AgentCard(
                                                    domaine: type.label),
                                              ))
                                          .toList(),
                                    );
                                  } else {
                                    return Skeletonizer(
                                        enabled: true,
                                        child: SupervisorCard(
                                            superviseur: value.supvisor));
                                  }
                                }),
                            const SizedBox(
                              width: 10,
                            ),
                            NoteCard(),
                            const SizedBox(
                              width: 10,
                            ),
                            const ToolStatusCard()
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: SiteListWithStatus(sites: value.sites),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                            flex: 1,
                            child: SitePointingListWithStatus(
                                supList: value.supvisor)),
                        const SizedBox(
                          width: 10,
                        ),
                        const Expanded(
                            flex: 1, child: ZonePointageProgressionList()),
                        const SizedBox(
                          width: 10,
                        ),
                        const Expanded(
                          flex: 1,
                          child: ListAbsenceAgent(),
                        )
                      ],
                    )
                  ],
                ),
        ),
      );
    });
  }
}
