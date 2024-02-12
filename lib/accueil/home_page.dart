import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/accueil/pointage_site_card.dart';
import 'package:spas_web/accueil/site_card.dart';
import 'package:spas_web/accueil/site_pointing_staus_list.dart';
import 'package:spas_web/accueil/site_staus_list.dart';
import 'package:spas_web/accueil/supervisor_card.dart';
import 'package:spas_web/accueil/tool_status_card.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/services/agentType.dart';

import '../zone/progression_pointage_zone.dart';
import 'absenceAgent.dart';
import 'agent_card.dart';
import 'note_card.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key, required this.manager});
  Manager manager;
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
                borderRadius: BorderRadius.circular(20.0),
                color: AppConstants.bgColor),
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
                  //Liste Agent
                  StreamBuilder(
                      stream: AgentTypeService().all(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          var docs = snapshot.data?.docs
                              .map((e) => jsonDecode(jsonEncode(e.data())))
                              .toList();

                          List<AgentType>? data = docs
                                  ?.map((e) => AgentType.fromJson(e))
                                  .toList() ??
                              [];

                          return Row(
                            children: data
                                .map((type) => Padding(
                                      padding: const EdgeInsets.only(
                                          right: 4.0, left: 4.0),
                                      child: AgentCard(domaine: type.label),
                                    ))
                                .toList(),
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),

                  const SizedBox(
                    width: 10,
                  ),
                  NoteCard(manager: widget.manager),
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
              Expanded(flex: 1, child: ZonePointageProgressionList()),
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
