import 'package:flutter/material.dart';
import 'package:spas_web/services/loading.dart';
import 'package:spas_web/supervisor/rapportPointageGenerator.dart';

import '../model.dart';
import '../services/pointerSite.dart';
import '../services/site.dart';
import '../services/supervisor.dart';
import '../utilsClass.dart';

class SitePointageMap extends StatefulWidget {
  SitePointageMap({super.key, required this.date});
  DateTime date;
  @override
  _SitePointageMapState createState() => _SitePointageMapState();
}

class _SitePointageMapState extends State<SitePointageMap> {
  List<Site> _listeSites = [];
  List<Map<String, dynamic>> _pointageSupervisor = [];
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
    return FutureBuilder(
      future: PointingSiteService().allFuture(),
      builder:
          (BuildContext context, AsyncSnapshot<List<PointingSite>> snapshot) {
        List<DateTime> days = UtilsClass().jourDuMois(widget.date);
        if (snapshot.hasData) {
          var pointageSite = snapshot.data;
          return FutureBuilder(
            future: SupervisorService().allFuture(""),
            builder: (BuildContext context,
                AsyncSnapshot<List<Supervisor>> snapshot) {
              List<Map<String, dynamic>> pointing = [];
              if (snapshot.hasData) {
                var supervisors = snapshot.data;
                for (var supervisor in supervisors ?? []) {
                  pointing.clear();
                  var nbSite = _listeSites
                      .where((element) =>
                          element.actif == true &&
                          (element.supervisor?.UID == supervisor.UID ||
                              element.supervisor_2?.UID == supervisor.UID))
                      .toList()
                      .length;

                  for (DateTime date in days) {
                    var pointage = pointageSite?.where((element) {
                      return element.date.isAtSameMomentAs(date) &&
                          element.supervisor?.UID == supervisor.UID;
                    }).toList();
                    pointing
                        .add({"date": date, "nbPointage": pointage?.length});
                  }
                  _pointageSupervisor.add({
                    "supervisor": supervisor,
                    "nbSite": nbSite,
                    "Pointages": pointing
                  });
                }
                return ElevatedButton(
                  onPressed: () {
                    RapportPointage.printRepportToExcel(_pointageSupervisor);
                  },
                  child: const Row(
                    children: [Icon(Icons.download), Text('Imprimer')],
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
    );
  }
}
