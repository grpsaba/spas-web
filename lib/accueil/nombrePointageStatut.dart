import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/services/pointerSite.dart';

import '../model.dart';
import '../services/site.dart';

class NbPointageStatus extends StatefulWidget {
  NbPointageStatus({super.key, required this.supervisor});
  Supervisor supervisor;
  @override
  _NbAgentStatusState createState() => _NbAgentStatusState();
}

class _NbAgentStatusState extends State<NbPointageStatus> {
  //int nbSite = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // WidgetsFlutterBinding.ensureInitialized();
    //getNbSite();
  }

  /*getNbSite() async {
    List<Site> sites =
        await SiteService().allBySupervisor(widget.supervisor.UID);

    nbSite = sites.length;
  }*/

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: PointingSiteService()
            .allTodayBySupervisor(supervisor: widget.supervisor),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }
          if (snapshot.hasData) {
            //plage de filtrage
            DateTime today = DateTime.now();
            //mettre les données collectée en forma json
            var docs = snapshot.data?.docs.map((e) => e.data()).toList();

            // //filter les données selon la plage
            // var collection = docs
            //     ?.map((e) => PointingSite.fromJson(e as Map<String, dynamic>))
            //     .where((p) =>
            //         p.date.day == today.day &&
            //         p.date.year == today.year &&
            //         p.date.month == today.month)
            //     .toList();
            var collection = docs
                ?.map((e) => PointingSite.fromJson(e as Map<String, dynamic>))
                .toList();
            //transformer les données sous forme maps site => liste pointage du site
            List<Map<String, dynamic>> pointages = [];
            List<Site>? sites =
                collection?.map((e) => e.site).toSet().toList() ?? [];

            /* for (Site site in sites ?? []) {
              var Listpointage = collection?.where((element) {
                return element.site.UID == site.UID;
              }).toList();

              pointages.add({"site": site, "pointages": Listpointage ?? []});
            }*/

            return FutureBuilder(
                future: SiteService().allBySupervisor(widget.supervisor.UID),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var data = snapshot.data ?? [];

                    int value = sites.length;
                    double purcent = 0;
                    //prendre le nombre de site su superviseur
                    if (data.isEmpty) {
                      purcent = 0.0;
                    } else {
                      purcent = value * 100 / data.length;
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FAProgressBar(
                          //progressType: LinearProgressBar.progressTypeLinear,
                          displayText: "%",
                          size: 12,
                          maxValue: 100.0,
                          currentValue: purcent,
                          progressColor: purcent <= 30
                              ? Colors.red
                              : purcent <= 60
                                  ? Colors.orange
                                  : Colors.green,
                          backgroundColor: AppConstants.bgColor,
                        ),
                        Text("site: $value/${data.length}",
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12))
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return const Text("Something went wrong");
                  } else {
                    return const LinearProgressIndicator();
                  }
                });
          } else {
            return const LinearProgressIndicator();
          }
        });
  }
}
