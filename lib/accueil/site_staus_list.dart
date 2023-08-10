import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:spas_web/accueil/site_status.dart';
import 'package:spas_web/search_textField.dart';

import '../generated/assets.dart';
import '../model.dart';
import '../services/agent.dart';
import '../services/loading.dart';
import '../services/site.dart';
import 'nombreAgentStatut.dart';

class SiteListWithStatus extends StatefulWidget {
  const SiteListWithStatus({super.key});

  @override
  _SupervisorListState createState() => _SupervisorListState();
}

class _SupervisorListState extends State<SiteListWithStatus> {
  final SiteService _siteService = SiteService();
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
                  "Sites",
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
            SizedBox(
              height: MediaQuery.of(context).size.height - 264,
              child: StreamBuilder(
                  stream: _siteService.all(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var docs = snapshot.data?.docs
                          .map((e) => jsonDecode(jsonEncode(e.data())))
                          .toList();
                      var lst = jsonDecode(jsonEncode(docs));
                      //Map<String, dynamic> lstCast = Map<String, dynamic>.from(lst);

                      var data = docs
                          ?.map((e) => Site.fromJson(e))
                          .toList()
                          .where((element) => element.actif == true)
                          .toList();
                      data = data
                          ?.where((element) => element.name
                              .toLowerCase()
                              .contains(_keyword.toLowerCase()))
                          .toList();
                      return ListView.builder(
                          itemCount: data!.length,
                          itemBuilder: (context, index) {
                            Site site = data![index];
                            return Card(
                              elevation: 0.2,
                              color: Colors.white,
                              child: ListTile(
                                //selected: site.UID == _selectedSite.UID,
                                selectedTileColor:
                                    Colors.blueGrey.withOpacity(0.4),
                                title: Text(
                                  site.name,
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: NbAgentStatus(site: site),
                                leading: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: SiteStatus(
                                      site: site,
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
                                              var height =
                                                  MediaQuery.of(context)
                                                      .size
                                                      .height;
                                              var width = MediaQuery.of(context)
                                                  .size
                                                  .width;

                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child: Container(
                                                              padding: const EdgeInsets
                                                                      .symmetric(
                                                                  horizontal:
                                                                      8.0),
                                                              alignment:
                                                                  Alignment
                                                                      .center,
                                                              decoration: BoxDecoration(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .primaryColor,
                                                                  borderRadius: const BorderRadius
                                                                          .only(
                                                                      topLeft: Radius
                                                                          .circular(
                                                                              20),
                                                                      topRight:
                                                                          Radius.circular(
                                                                              20))),
                                                              height: 50,
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .spaceBetween,
                                                                children: [
                                                                  Text(
                                                                    site.name,
                                                                    style: const TextStyle(
                                                                        color: Colors
                                                                            .white),
                                                                  ),
                                                                  IconButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      icon:
                                                                          const Icon(
                                                                        Icons
                                                                            .cancel,
                                                                        color: Colors
                                                                            .white,
                                                                      ))
                                                                ],
                                                              )),
                                                        ),
                                                      ],
                                                    ),
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          Column(
                                                            children: [
                                                              const Text(
                                                                "Adresse",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black54),
                                                              ),
                                                              Text(
                                                                site.adresse,
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Column(
                                                            children: [
                                                              const Text(
                                                                "Contact",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black54),
                                                              ),
                                                              Text(
                                                                site.phone,
                                                                style: const TextStyle(
                                                                    color: Colors
                                                                        .black),
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Column(
                                                            children: [
                                                              const Text(
                                                                "Agents",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .black54),
                                                              ),
                                                              siteAgent(site)
                                                            ],
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    const CircleAvatar(
                                                      radius: 64,
                                                      backgroundImage:
                                                          AssetImage(Assets
                                                              .assetsAgent),
                                                    ),
                                                    const Text(
                                                      "Superviseur 1",
                                                      style: TextStyle(
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      "${site.supervisor?.firstName} ${site.supervisor?.lastName}",
                                                      style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(
                                                      "Contact: ${site.supervisor!.phone}",
                                                      style: const TextStyle(
                                                          color: Colors.black54,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    const SizedBox(
                                                      height: 10,
                                                    ),
                                                    site.supervisor_2 == null
                                                        ? const SizedBox
                                                            .shrink()
                                                        : const Divider(),
                                                    site.supervisor_2 == null
                                                        ? const SizedBox
                                                            .shrink()
                                                        : const Text(
                                                            "Superviseur 2",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                    site.supervisor_2 == null
                                                        ? const SizedBox
                                                            .shrink()
                                                        : Text(
                                                            "${site.supervisor_2?.firstName} ${site.supervisor_2?.lastName}",
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                    site.supervisor_2 == null
                                                        ? const SizedBox
                                                            .shrink()
                                                        : Text(
                                                            "Contact: ${site.supervisor_2!.phone}",
                                                            style: const TextStyle(
                                                                color: Colors
                                                                    .black54,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      });
                                  /*  setState(() {
                                            _selectedSite = site;
                                          });*/
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

  Widget siteAgent(Site site) {
    return FutureBuilder(
        future: AgentService().allBySite(site.UID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              "0",
              style: TextStyle(color: Colors.black),
            );
          }
          if (snapshot.hasData) {
            var data = snapshot.data;
            return Text("${data?.length}",
                style: const TextStyle(color: Colors.black));
          } else {
            return const Text("0", style: TextStyle(color: Colors.black));
          }
        });
  }
}
