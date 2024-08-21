import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spas_web/accueil/site_status.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/services/superviseur_location.dart';
import 'package:spas_web/services/supervisor.dart';

import '../const.dart';
import '../generated/assets.dart';
import '../model.dart';
import '../search_textField.dart';
import '../services/loading.dart';
import '../services/player.dart';
import '../services/site.dart';

class SupervisorsLocation extends StatefulWidget {
  const SupervisorsLocation({super.key});

  @override
  SupervisorsLocationState createState() => SupervisorsLocationState();
}

class SupervisorsLocationState extends State<SupervisorsLocation> {
  late GoogleMapController _mapController;
  final LocationService _locationService = LocationService();
  final Map<String, Marker> _markers = {};
  Supervisor? _supervisorFolowed;
  late List<SuperviseurLocaion> _locations;
  List<Site> _sites = [];
  MapType _mapType = MapType.hybrid;
  String _keyword = "";

//variable de test de recherche de site dans le maps
  bool _searchsupervisor = true;
  bool _polyLines = false;
  bool _trafficEnabled = false;

  BitmapDescriptor markerIcon = AppConstants.defaultMarkerIcon;
  BitmapDescriptor siteMarkerIcon = AppConstants.defaultMarkerIcon;

  void setSiteCustomIcon() {
    BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(28, 28)), Assets.assetsGeopin3)
        .then((value) {
      siteMarkerIcon = value;
    }).onError((error, stackTrace) {
      print("erreur : ${error.toString()}");
    });
  }
  void setCustomIcon() {
    BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(28, 28)), Assets.assetsGeopin)
        .then((value) {
      markerIcon = value;
    }).onError((error, stackTrace) {
      print("erreur : ${error.toString()}");
    });
  }
  Future<void> addSiteMarkerTomap() async {

    for (final site in _sites) {

      final marker = Marker(
        icon: siteMarkerIcon,
        onTap: () {
          CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(site.latLng.lat, site.latLng.lng), zoom: 17));
          _mapController.animateCamera(cameraUpdate);
        },
        markerId: MarkerId(site.UID),
        position: LatLng(site.latLng.lat, site.latLng.lng),
        infoWindow: InfoWindow(
          title:site.name,
          snippet:
          "${site.supervisor?.firstName??""},${site.supervisor?.lastName??""}",
        ),
      );
      _markers[site.UID] = marker;
    }
  }
  Future<void> addMarkerTomap() async {
    _markers.clear();
    for (final location in _locations) {

      final marker = Marker(
        icon: markerIcon,
        onTap: () {
          CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(location.latlng.lat, location.latlng.lng), zoom: 17));
          _mapController.animateCamera(cameraUpdate);
        },
        markerId: MarkerId(location.supervisor?.UID??''),
        position: LatLng(location.latlng.lat, location.latlng.lng),
        infoWindow: InfoWindow(
          title:'${location.supervisor?.firstName??''} ${location.supervisor?.lastName??''}',
          snippet:
          "${location.latlng.lat},${location.latlng.lng}",
        ),
      );
      _markers[location.supervisor?.UID??''] = marker;
    }
    addSiteMarkerTomap();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

  }

  @override
  void initState() {
    // TODO: implement initState
    WidgetsFlutterBinding.ensureInitialized();
    setCustomIcon();
    setSiteCustomIcon();

    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _mapController.dispose();

  }

  @override
  Widget build(BuildContext context) {
    return PageModel(
        pageIdex: 10,
        titile: "Sites maps",
        child: Row(
          children: [
            !_searchsupervisor
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
                  child: FutureBuilder(
                      future: SupervisorService().allFuture(),
                      builder: (context, snapshot) {
                        if(snapshot.hasData){
                          List<Supervisor> data=snapshot.data?.where((s)=>s.firstName.toLowerCase().contains(_keyword.toLowerCase())||s.lastName.toLowerCase().contains(_keyword.toLowerCase())).toList()??[];
                          return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                Supervisor? supervisor = data[index];
                                return ListTile(

                                  onTap: () async{
                                    setState(() {
                                      _supervisorFolowed = supervisor;
                                      _mapType = MapType.hybrid;
                                      _mapController.showMarkerInfoWindow(
                                          MarkerId(supervisor.UID));
                                    });
                                    var locaion = await LocationService().one(supervisor.UID);
                                    CameraUpdate cameraUpdate =
                                    CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                            target: LatLng(
                                                locaion.latlng.lat,
                                                locaion.latlng.lng),
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
                              });
                        }else{
                          return const SizedBox.shrink();
                        }

                      }
                  ),
                ),
              ],
            ),

                Expanded(
              child: FutureBuilder(
                future: SiteService().allAsModel(),
                builder: (context, snapshot) {
                  if(snapshot.hasData){
                    _sites=snapshot.data??[];


                    return StreamBuilder(
                        stream: _locationService.all(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {

                            var docs = snapshot.data?.docs
                                .map((e) => jsonDecode(jsonEncode(e.data())))
                                .toList()??[];

                            _locations = docs
                                .map((e) => SuperviseurLocaion.fromJson(e)).toList();
                            var supFoloweds=_locations.where((l)=>l.supervisor==_supervisorFolowed);
                            SuperviseurLocaion? supervisorFolowedLocaion;
                            if(supFoloweds.isNotEmpty){
                              supervisorFolowedLocaion=supFoloweds.first;
                            }

                            addMarkerTomap();
                            return  GoogleMap(
                              polylines: !_polyLines
                                  ? {}
                                  : {
                                Polyline(
                                    geodesic: true,
                                    polylineId: const PolylineId("1"),
                                    points: _locations
                                        .map((sl) => LatLng(
                                        sl.latlng.lat, sl.latlng.lng))
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
                                      supervisorFolowedLocaion!=null?supervisorFolowedLocaion.latlng.lat: _locations[0].latlng.lat,supervisorFolowedLocaion!=null?supervisorFolowedLocaion.latlng.lng: _locations[0].latlng.lng),
                                  zoom: 15),
                            );



                          } else {
                            return Center(
                              child: Loading(
                                size: 64,
                                inline: false,
                              ),
                            );
                          }
                        });
                  }else {
                    return Center(
                      child: Loading(
                        size: 64,
                        inline: false,
                      ),
                    );
                  }

                }

              ),
            ),
          ],
        )
    );
  }
}
