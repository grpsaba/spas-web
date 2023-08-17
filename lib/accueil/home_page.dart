import 'package:flutter/material.dart';
import 'package:spas_web/accueil/point_zero_card.dart';
import 'package:spas_web/accueil/pointage_site_card.dart';
import 'package:spas_web/accueil/site_card.dart';
import 'package:spas_web/accueil/site_pointing_staus_list.dart';
import 'package:spas_web/accueil/site_staus_list.dart';
import 'package:spas_web/accueil/supervisor_card.dart';
import 'package:spas_web/accueil/tool_status_card.dart';
import 'package:spas_web/model.dart';

import 'absenceAgent.dart';
import 'agent_card.dart';
import 'note_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required Manager manager});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        //mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0), color: Colors.white),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PointageSiteCard(),
                  const SizedBox(
                    width: 10,
                  ),
                  const SiteCard(),
                  const SizedBox(
                    width: 10,
                  ),
                  const SupervisorCard(),
                  const SizedBox(
                    width: 10,
                  ),
                  AgentCard(domaine: "SECURITÉ"),
                  const SizedBox(
                    width: 10,
                  ),
                  AgentCard(domaine: "NETTOYAGE"),
                  const SizedBox(
                    width: 10,
                  ),
                  const PointZeroCard(),
                  const SizedBox(
                    width: 10,
                  ),
                  const NoteCard(),
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
          const Row(
            children: [
              Expanded(
                flex: 1,
                child: SiteListWithStatus(),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(flex: 1, child: SitePointingListWithStatus()),
              SizedBox(
                width: 10,
              ),
              Expanded(
                flex: 1,
                child: ListAbsenceAgent(),
              )
            ],
          )
        ],
      ),
    );
  }
}
