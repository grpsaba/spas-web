import 'package:flutter/material.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/loading.dart';
import 'package:spas_web/supervisor/rapportPointageGenerator.dart';

import '../model.dart';
import '../services/pointerSite.dart';
import '../services/site.dart';
import '../utilsClass.dart';

class SiteMonthlyPointage extends StatefulWidget {
  SiteMonthlyPointage({super.key, required this.date});
  DateTime date;
  @override
  _SiteMonthlyPointageState createState() => _SiteMonthlyPointageState();
}

class _SiteMonthlyPointageState extends State<SiteMonthlyPointage> {
  List<Map<String, dynamic>> _pointing = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIndex: 6,
      title: "Pointages -> Nombre de visite des sites",
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
              "Nombre de visite par mois",
              style: TextStyle(
                  fontSize: 25, fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(
              height: 20,
            ),
            FutureBuilder(
              future: PointingSiteService().allFuture(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<PointingSite>> snapshot) {
                List<DateTime> days = UtilsClass().jourDuMois(widget.date);
                DateTime debut = days.first;
                DateTime end = days.last;
                if (snapshot.hasData) {
                  var pointageSite = snapshot.data;
                  return FutureBuilder(
                    future: SiteService().allAsModel(),
                    builder: (BuildContext context,
                        AsyncSnapshot<List<Site>> snapshot) {
                      if (snapshot.hasData) {
                        var sites = snapshot.data;
                        for (Site site in sites ?? []) {
                          var pointage = pointageSite?.where((element) {
                            return (element.date.isAfter(debut
                                        .subtract(const Duration(days: 1))) &&
                                    element.date.isBefore(
                                        end.add(const Duration(days: 1)))) &&
                                element.site.UID == site.UID;
                          }).toList();
                          _pointing.add({
                            "site": site,
                            "date":
                                "${debut.day}/${debut.month}/${debut.year} - ${end.day}/${end.month}/${end.year}",
                            "nbPointage": pointage?.length
                          });
                        }
                        return FittedBox(
                          child: ElevatedButton(
                            onPressed: () {
                              RapportPointage.printMonthlySiteRepportToExcel(
                                  _pointing);
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
