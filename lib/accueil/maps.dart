import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spas_web/accueil/site_status.dart';

import '../const.dart';
import '../generated/assets.dart';
import '../model.dart';
import '../search_textField.dart';
import '../services/loading.dart';
import '../services/player.dart';
import '../services/site.dart';

class Maps extends StatefulWidget {
  const Maps({super.key});

  @override
  _MapsState createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  late GoogleMapController _mapController;
  final SiteService _siteService = SiteService();
  final Map<String, Marker> _markers = {};
  late List<Site> _sites;
  late List<Site> _Sidesites;
  MapType _mapType = MapType.normal;
  String _keyword = "";

//variable de test de recherche de site dans le maps
  bool _searchSite = true;
  bool _polyLines = false;
  bool _trafficEnabled = false;

  BitmapDescriptor markerIcon = AppConstants.defaultMarkerIcon;

  void setCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(64, 64)), Assets.assetsPosition)
        .then((value) {
      markerIcon = value;
    }).onError((error, stackTrace) {
      print("errur : ${error.toString()}");
    });
  }

  Future<void> addMarkerTomap() async {
    _markers.clear();
    for (final site in _sites) {
      final marker = Marker(
        icon: markerIcon,
        onTap: () {
          CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(site.latLng.lat, site.latLng.lng), zoom: 17));
          _mapController.animateCamera(cameraUpdate);
        },
        markerId: MarkerId(site.UID),
        position: LatLng(site.latLng.lat, site.latLng.lng),
        infoWindow: InfoWindow(
          title: site.name,
          snippet:
              "${site.adresse} superviseur: ${site.supervisor?.firstName} ${site.supervisor?.lastName} ${site.supervisor?.phone}",
        ),
      );
      _markers[site.name] = marker;
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      addMarkerTomap();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    WidgetsFlutterBinding.ensureInitialized();
    setCustomIcon();
    super.initState();
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(
                onPressed: () {
                  setState(() {
                    _searchSite = _searchSite ? false : true;
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

                _sites = docs!
                    .map((e) => Site.fromJson(e))
                    .toList()
                    .where((element) => element.actif == true)
                    .toList();
                _Sidesites = _sites
                    .where((element) => element.name
                        .toLowerCase()
                        .contains(_keyword.toLowerCase()))
                    .toList();
                //return SiteScatter(sites: _sites);

                return Row(
                  children: [
                    !_searchSite
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
                                    itemCount: _Sidesites.length,
                                    itemBuilder: (context, index) {
                                      Site? site = _Sidesites[index];
                                      return ListTile(
                                        leading: SizedBox(
                                            width: 15,
                                            height: 15,
                                            child: SiteStatus(
                                              site: site,
                                            )),
                                        onTap: () {
                                          setState(() {
                                            _searchSite = false;
                                            _mapType = MapType.hybrid;
                                            _mapController.showMarkerInfoWindow(
                                                MarkerId(site.UID));
                                          });

                                          CameraUpdate cameraUpdate =
                                              CameraUpdate.newCameraPosition(
                                                  CameraPosition(
                                                      target: LatLng(
                                                          site.latLng.lat,
                                                          site.latLng.lng),
                                                      zoom: 17));

                                          _mapController
                                              .animateCamera(cameraUpdate);
                                        },
                                        title: Text(
                                          site.name,
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
                                    points: _sites
                                        .map((site) => LatLng(
                                            site.latLng.lat, site.latLng.lng))
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
                            target: LatLng(
                                _sites[0].latLng.lat, _sites[0].latLng.lng),
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
