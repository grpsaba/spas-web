import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:spas_web/const.dart';

import '../model.dart';
import '../services/pointerZone.dart';
import '../services/site.dart';

class ZonePointageProgressBar extends StatefulWidget {
  ZonePointageProgressBar({super.key, required this.zoneMember});
  ZoneMember zoneMember;
  @override
  _ZonePointageProgressBarState createState() =>
      _ZonePointageProgressBarState();
}

class _ZonePointageProgressBarState extends State<ZonePointageProgressBar> {
  int nbSite = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    getNbSite();
  }

  getNbSite() async {
    List<Site> sites = await SiteService().allByZone(widget.zoneMember.zone!);
    nbSite = sites.where((element) => element.actif == true).toList().length;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: PointingZoneService().all(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const SizedBox.shrink();
          if (snapshot.hasData) {
            //plage de filtrage

            //mettre les données collectée en forma json
            var docs = snapshot.data?.docs
                .map((e) => jsonDecode(jsonEncode(e.data())))
                .toList();

            //filter les données selon la plage
            var collection =
                docs?.map((e) => PointingZone.fromJson(e)).toList();
            collection = collection
                ?.where((element) =>
                    element.isToday() &&
                    element.zoneMember?.UID == widget.zoneMember.UID)
                .toList();

            //transformer les données sous forme maps site => liste pointage du site
            List<Map<String, dynamic>> pointages = [];
            List<Site>? sites = collection?.map((e) => e.site).toSet().toList();
            //elimination des doublons
            /*var temps = [];
            for (Site site in sites ?? []) {
              temps.add(site);
              sites?.removeWhere((element) => element.UID == site.UID);
            }*/
            for (Site site in sites ?? []) {
              var Listpointage = collection?.where((element) {
                return element.site.UID == site.UID;
              }).toList();

              pointages.add({"site": site, "pointages": Listpointage ?? []});
            }

            //filtre par site

            /* pointages = pointages.where((element) {
              Site site = element["site"];
              return site.supervisor?.UID == widget.supervisor.UID;
            }).toList();*/

            int? value = pointages.length;
            double purcent = 0;
            //prendre le nombre de site su superviseur
            if (nbSite == 0) {
              purcent = 0.0;
            } else {
              purcent = value * 100 / nbSite;
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
                Text("site: $value/$nbSite",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12))
              ],
            );
          } else {
            return const LinearProgressIndicator();
          }
        });
  }
}
