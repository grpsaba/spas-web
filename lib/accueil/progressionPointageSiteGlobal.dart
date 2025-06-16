import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animation_progress_bar/flutter_animation_progress_bar.dart';
import 'package:spas_web/services/pointerSite.dart';

import '../model.dart';
import '../services/site.dart';

class PointageSiteGlobal extends StatefulWidget {
  final QuerySnapshot<Object?>? data;
  final int nbSite;
  const PointageSiteGlobal({
    super.key,
    this.data,
    required this.nbSite,
  });

  @override
  _PointageSiteGlobalState createState() => _PointageSiteGlobalState();
}

class _PointageSiteGlobalState extends State<PointageSiteGlobal> {
  //int nbSite = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    //getNbSite();
  }

  getNbSite() async {
    List<Site> sites = await SiteService().allAsModel();
    //nbSite = sites.where((element) => element.actif == true).toList().length;
  }

  @override
  Widget build(BuildContext context) {
    //plage de filtrage

    //mettre les données collectée en forma json
    var docs = widget.data?.docs.map((e) => e.data()).toList();

    //filter les données selon la plage
    var collection = docs
        ?.map((e) => PointingSite.fromJson(e as Map<String, dynamic>))
        .toList();
    //collection = collection?.where((element) => element.isToday()).toList();

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
    if (widget.nbSite == 0) {
      purcent = 0.0;
    } else {
      purcent = value * 100 / widget.nbSite;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FAProgressBar(
          //progressType: LinearProgressBar.progressTypeLinear,
          displayText: "%",
          size: 15,
          maxValue: 100.0,
          currentValue: purcent,
          progressColor: purcent <= 30
              ? Colors.red
              : purcent <= 60
                  ? Colors.orange
                  : Colors.green,
          backgroundColor: Colors.grey,
        ),
        Text("site: $value/${widget.nbSite}",
            style: const TextStyle(color: Colors.white))
      ],
    );
    // return StreamBuilder(
    //     stream: PointingSiteService().all(),
    //     builder: (context, snapshot) {
    //       if (snapshot.hasError) return const SizedBox.shrink();
    //       if (snapshot.hasData) {
    //         //plage de filtrage

    //         //mettre les données collectée en forma json
    //         var docs = snapshot.data?.docs.map((e) => e.data()).toList();

    //         //filter les données selon la plage
    //         var collection = docs
    //             ?.map((e) => PointingSite.fromJson(e as Map<String, dynamic>))
    //             .toList();
    //         collection =
    //             collection?.where((element) => element.isToday()).toList();

    //         //transformer les données sous forme maps site => liste pointage du site
    //         List<Map<String, dynamic>> pointages = [];
    //         List<Site>? sites = collection?.map((e) => e.site).toSet().toList();
    //         //elimination des doublons
    //         /*var temps = [];
    //         for (Site site in sites ?? []) {
    //           temps.add(site);
    //           sites?.removeWhere((element) => element.UID == site.UID);
    //         }*/
    //         for (Site site in sites ?? []) {
    //           var Listpointage = collection?.where((element) {
    //             return element.site.UID == site.UID;
    //           }).toList();

    //           pointages.add({"site": site, "pointages": Listpointage ?? []});
    //         }

    //         //filtre par site

    //         /* pointages = pointages.where((element) {
    //           Site site = element["site"];
    //           return site.supervisor?.UID == widget.supervisor.UID;
    //         }).toList();*/

    //         int? value = pointages.length;
    //         double purcent = 0;
    //         //prendre le nombre de site su superviseur
    //         if (nbSite == 0) {
    //           purcent = 0.0;
    //         } else {
    //           purcent = value * 100 / nbSite;
    //         }
    //         return Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             FAProgressBar(
    //               //progressType: LinearProgressBar.progressTypeLinear,
    //               displayText: "%",
    //               size: 15,
    //               maxValue: 100.0,
    //               currentValue: purcent,
    //               progressColor: purcent <= 30
    //                   ? Colors.red
    //                   : purcent <= 60
    //                       ? Colors.orange
    //                       : Colors.green,
    //               backgroundColor: Colors.grey,
    //             ),
    //             Text("site: $value/$nbSite",
    //                 style: const TextStyle(color: Colors.white))
    //           ],
    //         );
    //       } else {
    //         return const SizedBox.shrink();
    //       }
    //     });
  }
}
