import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/zone/pointage_statut.dart';
import 'package:spas_web/zone/site_non_pointe_par_zone.dart';

import '../model.dart';
import '../notes/imprime_rapport.dart';
import '../services/loading.dart';
import '../services/zoneMember.dart';

class ZonePointageProgressionList extends StatefulWidget {
  const ZonePointageProgressionList({super.key});

  @override
  _ZonePointageProgressionListState createState() =>
      _ZonePointageProgressionListState();
}

class _ZonePointageProgressionListState
    extends State<ZonePointageProgressionList> {
  final ZoneMemberService _zoneService = ZoneMemberService();
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now();
  String _keyword = "";

  /*Site _selectedSite = Site(
      nbAgent: 0,
      UID: "",
      codeSite: "",
      name: "",
      adresse: "",
      phone: "",
      latLng: LatLngModel(lng: 0.0, lat: 0.0),
      email: "",
      supervisor: null,
      token: '');*/
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(8.0),
        height: MediaQuery.of(context).size.height - 192,
        decoration: BoxDecoration(
            color: AppConstants.secondaryColor,
            borderRadius: BorderRadius.circular(20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Pointages site par zone",
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
            /*Row(
              children: [
                const Text(
                  "Pointages site par zone",
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(
                  width: 5,
                ),
                SearchTextField(
                    onSearch: (value) {
                      setState(() {
                        _keyword = value;
                      });
                    },
                    onPress: () {}),
              ],
            ),*/
            const Divider(),
            Expanded(
              child: FutureBuilder(
                  future: _zoneService.allActifAsModel(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {

                      var data = snapshot.data??[];

                      data = data
                          .where((element) =>
                              element.zone!.name
                                  .toLowerCase()
                                  .contains(_keyword.toLowerCase()) ||
                              "${element.firstName} ${element.lastName}"
                                  .toLowerCase()
                                  .contains(_keyword.toLowerCase()))
                          .toList();
                      return ListView.builder(
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            ZoneMember zoneMember = data[index];
                            return Card(
                              elevation: 0.2,
                              color:
                                  AppConstants.secondaryColor.withOpacity(0.3),
                              child: ListTile(
                                //selected: site.UID == _selectedSite.UID,
                                selectedTileColor: AppConstants.secondaryColor,
                                title: Text(
                                  "${zoneMember.firstName} ${zoneMember.lastName} - ${zoneMember.zone?.codeZone ?? ""}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                                trailing: IconButton(
                                  tooltip: "Rapport",
                                  icon: const Icon(
                                    Icons.description,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => ImprimeRapport(
                                                source:
                                                    "${zoneMember.firstName} ${zoneMember.lastName}")));
                                  },
                                ),
                                subtitle: ZonePointageProgressBar(
                                    zoneMember: zoneMember),
                                /*leading: const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          AssetImage(Assets.assetsAgent),
                                    )),*/
                                onTap: () {
                                  showDialog(
                                      context: context,
                                      builder: (_) {
                                        return AlertDialog(
                                          contentPadding:
                                              const EdgeInsets.all(0.0),
                                          alignment: Alignment.center,
                                          content: Builder(
                                            builder: (context) {
                                              // Get available height and width of the build area of this widget. Make a choice depending on the size.

                                              var width = MediaQuery.of(context)
                                                  .size
                                                  .width;

                                              return SizedBox(
                                                width: width - (width - 500),
                                                child: SiteNonVisiteParZone(
                                                  zoneMember: zoneMember,
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      });
                                },
                              ),
                            );
                          });
                    } else {
                      return Center(
                        child: Loading(
                          size: 64,
                          inline: false,
                        ),
                      );
                    }
                  }),
            ),
          ],
        ));
  }
}
