import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/loading.dart';
import 'package:spas_web/zone_member/zone_rapport_pointage_generator.dart';

import '../model.dart';
import '../services/pointerZone.dart';
import '../services/site.dart';
import '../services/zoneMember.dart';
import '../utilsClass.dart';

class SitePointageZoneMap extends StatefulWidget {
  SitePointageZoneMap({super.key, required this.date});
  DateTime date;
  @override
  _SitePointageZoneMapState createState() => _SitePointageZoneMapState();
}

class _SitePointageZoneMapState extends State<SitePointageZoneMap> {
  List<Site> _listeSites = [];
  List<Map<String, dynamic>> _pointageZone = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    getSite();
  }

  getSite() async {
    _listeSites = await SiteService().allAsModel();
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 15,
      title: "Rapport nombre de pointage par chef de zone",
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.print,
              size: 68,
              color: Theme.of(context).primaryColor,
            ),
            const Text(
              "Le fichier prend tout les jours du mois sélectionné",
              style: TextStyle(
                  fontSize: 25, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(
              height: 20,
            ),
            FutureBuilder(
              future: PointingZoneService().allFuture(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<PointingZone>> snapshot) {
                List<DateTime> days = UtilsClass().jourDuMois(widget.date);
                if (snapshot.hasData) {
                  var pointageZone = snapshot.data;
                  return FutureBuilder(
                    future: ZoneMemberService().allAsModel(),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<ZoneMember>> snapshot) {
                      if (snapshot.hasData) {
                        var zoneMemnbers = snapshot.data;
                        for (ZoneMember zoneMember in zoneMemnbers ?? []) {
                          var nbSite = _listeSites
                              .where((element) =>
                                  element.actif == true &&
                                  (element.zone == zoneMember.zone))
                              .toList()
                              .length;
                          List<Map<String, dynamic>> pointing = [];
                          for (DateTime date in days) {
                            var pointage = pointageZone?.where((element) {
                              return element.date.year == date.year &&
                                  element.date.month == date.month &&
                                  element.date.day == date.day &&
                                  element.zoneMember?.UID == zoneMember.UID;
                            }).toList();
                            pointing.add(
                                {"date": date, "nbPointage": pointage?.length});
                          }

                          _pointageZone.add({
                            "zoneMember": zoneMember,
                            "nbSite": nbSite,
                            "Pointages": pointing
                          });
                          pointing = [];
                        }
                        return FittedBox(
                          child: ElevatedButton(
                            onPressed: () {
                              ZoneRapportPointage.printRepportToExcel(
                                  _pointageZone);
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.download),
                                Text('Télécharger')
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Loading(size: 64, inline: true);
                      }
                    },
                  );
                } else {
                  return Loading(size: 64, inline: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
