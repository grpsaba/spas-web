import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spas_web/services/supervisor.dart';

import '../model.dart';
import '../search_textField.dart';
import '../services/loading.dart';
import '../services/player.dart';

class SupervisorMaps extends StatefulWidget {
  const SupervisorMaps({super.key});

  @override
  _SupervisorMapsState createState() => _SupervisorMapsState();
}

class _SupervisorMapsState extends State<SupervisorMaps> {
  late GoogleMapController _mapController;
  final SupervisorService _siteService = SupervisorService();
  final Map<String, Marker> _markers = {};
  late List<Supervisor> _supervisors;
  late List<Supervisor> _Sidesupervisors;
  MapType _mapType = MapType.normal;
  String _keyword = "";

//variable de test de recherche de site dans le maps
  bool _searchSupervisor = true;
  bool _polyLines = false;
  bool _trafficEnabled = false;
  Future<void> addMarkerTomap() async {
    _markers.clear();
    for (final supervisor in _supervisors) {
      final marker = Marker(
        onTap: () {
          CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(supervisor.latlng?.lat ?? 0.0,
                      supervisor.latlng?.lng ?? 0.0),
                  zoom: 17));
          _mapController.animateCamera(cameraUpdate);
        },
        markerId: MarkerId(supervisor.UID),
        position: LatLng(
            supervisor.latlng?.lat ?? 0.0, supervisor.latlng?.lng ?? 0.0),
        infoWindow: InfoWindow(
          title: "${supervisor.firstName} ${supervisor.lastName}",
          snippet: supervisor.phone,
        ),
      );
      _markers[supervisor.UID] = marker;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      addMarkerTomap();
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _mapController.dispose();
    Audio().stopSOs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Dernière position des superviseurs",
          style: TextStyle(color: Colors.white),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
                onPressed: () {
                  setState(() {
                    _searchSupervisor = _searchSupervisor ? false : true;
                  });
                },
                icon: const Icon(
                  Icons.search_sharp,
                  size: 32,
                )),
            const Text("Type de maps"),
            TextButton(
                onPressed: () {
                  setState(() {
                    _mapType = MapType.normal;
                  });
                },
                child: const Text("Normal")),
            TextButton(
                onPressed: () {
                  setState(() {
                    _mapType = MapType.satellite;
                  });
                },
                child: const Text("Satellite")),
            TextButton(
                onPressed: () {
                  setState(() {
                    _mapType = MapType.hybrid;
                  });
                },
                child: const Text("Hybride")),
            TextButton(
                onPressed: () {
                  setState(() {
                    _trafficEnabled = _trafficEnabled ? false : true;
                  });
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.traffic_outlined,
                      color: Colors.red,
                    ),
                    Text("Activer le trafic"),
                  ],
                )),
            TextButton(
                onPressed: () {
                  setState(() {
                    _polyLines = _polyLines ? false : true;
                  });
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: Colors.red,
                    ),
                    Text("Dessiner les polyLines"),
                  ],
                )),
          ],
        ),
      ),
      /*appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        actions: const [
          Sos(),
        ],
        title: const Text(
          'SPAS GROUPE SABA',
          style: TextStyle(color: Colors.white),
        ),
      ),*/
      body: StreamBuilder(
          stream: _siteService.all(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              try {
                var docs = snapshot.data?.docs
                    .map((e) => jsonDecode(jsonEncode(e.data())))
                    .toList();

                _supervisors = docs!
                    .map((e) => Supervisor.fromJson(e))
                    .toList()
                    .where((element) => element.actif == true)
                    .toList();
                _Sidesupervisors = _supervisors
                    .where((element) =>
                        element.firstName
                            .toLowerCase()
                            .contains(_keyword.toLowerCase()) ||
                        element.lastName
                            .toLowerCase()
                            .contains(_keyword.toLowerCase()) ||
                        element.phone
                            .toLowerCase()
                            .contains(_keyword.toLowerCase()))
                    .toList();
                //return SiteScatter(sites: _sites);

                return Row(
                  children: [
                    !_searchSupervisor
                        ? const SizedBox.shrink()
                        : Column(
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
                                    itemCount: _Sidesupervisors.length,
                                    itemBuilder: (context, index) {
                                      Supervisor? supervisor =
                                          _Sidesupervisors[index];
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
                                            _searchSupervisor = false;
                                            _mapType = MapType.hybrid;
                                            _mapController.showMarkerInfoWindow(
                                                MarkerId(supervisor.UID));
                                          });

                                          CameraUpdate cameraUpdate =
                                              CameraUpdate.newCameraPosition(
                                                  CameraPosition(
                                                      target: LatLng(
                                                          supervisor.latlng
                                                                  ?.lat ??
                                                              0.0,
                                                          supervisor.latlng
                                                                  ?.lng ??
                                                              0.0),
                                                      zoom: 17));

                                          _mapController
                                              .animateCamera(cameraUpdate);
                                        },
                                        title: Text(
                                          "${supervisor.firstName} ${supervisor.lastName}",
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .primaryColor),
                                        ),
                                      );
                                    }),
                              ),
                            ],
                          ),
                    Expanded(
                      child: GoogleMap(
                        polylines: !_polyLines
                            ? {}
                            : {
                                Polyline(
                                    geodesic: true,
                                    polylineId: const PolylineId("1"),
                                    points: _supervisors
                                        .map((site) => LatLng(
                                            site.latlng?.lat ?? 0.0,
                                            site.latlng?.lng ?? 0.0))
                                        .toList(),
                                    color: Colors.red,
                                    width: 2),
                              },
                        trafficEnabled: _trafficEnabled,
                        mapType: _mapType,
                        markers: _markers.values.toSet(),
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                            // ignore: unnecessary_null_comparison
                            target: LatLng(_supervisors[0].latlng?.lat ?? 0.0,
                                _supervisors[0].latlng?.lng ?? 0.0),
                            zoom: 15),
                      ),
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
                        const Text("Pas de données")
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
