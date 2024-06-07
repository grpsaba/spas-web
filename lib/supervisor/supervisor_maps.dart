import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/superviseur_location.dart';
import 'package:spas_web/services/supervisor.dart';

import '../const.dart';
import '../model.dart';
import '../search_textField.dart';
import '../services/loading.dart';
import '../services/player.dart';
import 'maps_component.dart';

class SupervisorMaps extends StatefulWidget {
  const SupervisorMaps({super.key});

  @override
  _SupervisorMapsState createState() => _SupervisorMapsState();
}

class _SupervisorMapsState extends State<SupervisorMaps> {

  final SupervisorService _supervisorService = SupervisorService();

  List<SuperviseurLocaion> _locations = [];

  Supervisor _selectedSupervisor =Supervisor(UID: '', code: '', firstName: '', lastName: '', phone: '', email: '', token: '', tracking: true, latlng: null, actif: null, department: null);
  String _keyword = "";
  List<LatLng> _polylineCoordinates = [];
//variable de test de recherche de site dans le maps




  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    Audio().stopSOs();
  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
      pageIdex: 4,
      titile: "Positions des superviseurs",
      child: FutureBuilder(
          future: _supervisorService.allFuture(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {

              try {
                List<Supervisor> supervisors = snapshot.data?.where((e) =>e.UID.toLowerCase().contains(_keyword.toLowerCase()) || e.lastName.toLowerCase().contains(_keyword.toLowerCase())|| e.firstName.toLowerCase().contains(_keyword.toLowerCase())).toList() ?? [];


                return Row(
                  children: [
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SearchTextField(
                              onSearch: (value) {
                                setState(() {
                                  _keyword = value;
                                });
                              },
                              onPress: () {}),
                        ),
                        SizedBox(
                          width: 150,
                          height: MediaQuery.of(context).size.height -
                              (MediaQuery.of(context).size.height - 620),
                          child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: supervisors.length,
                              itemBuilder: (context, index) {
                                Supervisor? supervisor =
                                supervisors[index];
                                return ListTile(
                                  leading: const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.red,
                                      )),
                                  onTap: () {
                                    setState(() {
                                      _selectedSupervisor = supervisor;
                                      setState(() {

                                      });
                                    });

                                  },
                                  title: Text(
                                    "${supervisor.firstName} ${supervisor.lastName}",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).primaryColor),
                                  ),
                                );
                              }),
                        ),
                      ],
                    ),
                   Expanded(
                      child: LocationMapsComponent(supervisor:_selectedSupervisor),
                    ),
                  ],
                );
              } catch (error) {
                return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_rounded,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                         Text("Pas de données ${error.toString()}")
                      ]),
                );
              }
            } else {
              return Center(
                child: Loading(
                  size: 64,
                  inline: false,
                ),
              );
            }
          }),
    );
  }
}
