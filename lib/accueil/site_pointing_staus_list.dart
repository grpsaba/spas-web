import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/search_textField.dart';

import '../generated/assets.dart';
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
            color: Colors.white, borderRadius: BorderRadius.circular(20.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Pointages site",
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
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder(
                  stream: _supervisorService.all(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var docs = snapshot.data?.docs
                          .map((e) => jsonDecode(jsonEncode(e.data())))
                          .toList();
                      var lst = jsonDecode(jsonEncode(docs));
                      //Map<String, dynamic> lstCast = Map<String, dynamic>.from(lst);

                      var data = docs
                          ?.map((e) => Supervisor.fromJson(e))
                          .toList()
                          .where((element) => element.actif == true)
                          .toList();
                      data = data
                          ?.where((element) => element.firstName
                              .toLowerCase()
                              .contains(_keyword.toLowerCase()))
                          .toList();
                      return ListView.builder(
                          itemCount: data!.length,
                          itemBuilder: (context, index) {
                            Supervisor supervisor = data![index];
                            return Card(
                              elevation: 0.2,
                              color: Colors.white,
                              child: ListTile(
                                //selected: site.UID == _selectedSite.UID,
                                selectedTileColor:
                                    Colors.blueGrey.withOpacity(0.4),
                                title: Text(
                                  '${supervisor.firstName} ${supervisor.lastName}',
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle:
                                    NbPointageStatus(supervisor: supervisor),
                                leading: const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundImage:
                                          AssetImage(Assets.assetsAgent),
                                    )),
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
