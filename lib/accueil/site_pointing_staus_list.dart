import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/notes/imprime_rapport.dart';
import 'package:spas_web/search_textField.dart';

import '../model.dart';
import '../services/loading.dart';
import '../services/supervisor.dart';
import 'Site_non_visite_par_sup.dart';
import 'nombrePointageStatut.dart';

class SitePointingListWithStatus extends StatefulWidget {
  const SitePointingListWithStatus({super.key});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SitePointingListWithStatus> {
  final SupervisorService _supervisorService = SupervisorService();
  final TextEditingController _texController = TextEditingController();
  String _keyword = "";
  DateTime _dateDebut = DateTime.now();
  DateTime _dateFin = DateTime.now();
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
            Row(
              children: [
                const Text(
                  "Pointages site",
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
                const SizedBox(
                  width: 5,
                ),
                SearchTextField(
                    fillColor: AppConstants.bgColor,
                    hintColor: AppConstants.secondaryColor,
                    textColor: Colors.white,
                    onSearch: (value) {
                      setState(() {
                        _keyword = value;
                      });
                    },
                    onPress: () {}),
              ],
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder(
                  future: _supervisorService.allActifFuture(_keyword),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                        // TODO: Handle this case.
                        return const SizedBox.shrink();
                      case ConnectionState.waiting:
                        // TODO: Handle this case.
                        return Loading(size: 64, inline: false);

                      case ConnectionState.active:
                        // TODO: Handle this case.

                      var  data = snapshot.data??[];

                      return sipervisorList(data: data);
                      case ConnectionState.done:
                        var  data = snapshot.data??[];
                        return sipervisorList(data: data);
                    }
                  }),
            ),
          ],
        ));
  }
  Widget sipervisorList({required List<Supervisor> data}){
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          Supervisor supervisor = data[index];
          return Card(
            elevation: 0.2,
            color: AppConstants.secondaryColor
                .withOpacity(0.3),
            child: ListTile(
              //selected: site.UID == _selectedSite.UID,
              selectedTileColor:
              AppConstants.secondaryColor,
              title: Text(
                '${supervisor.firstName} ${supervisor.lastName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
              subtitle:
              NbPointageStatus(supervisor: supervisor),
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
                              "${supervisor.firstName} ${supervisor.lastName}")));
                },
              ),
              /* leading: const SizedBox(
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

                            var width =
                                MediaQuery.of(context)
                                    .size
                                    .width;

                            return Container(
                              width: width - (width - 500),
                              child: SiteNonVisite(
                                supervisor: supervisor,
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
  }
}
