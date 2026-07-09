import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:spas_web/accueil/site_status.dart';
import 'package:spas_web/administration/home.dart';

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
  State<Maps> createState() => _MapsState();
}

class _MapsState extends State<Maps> {
  late GoogleMapController _mapController;
  final SiteService _siteService = SiteService();
  final Map<String, Marker> _markers = {};
  late List<Site> _sites;
  late List<Site> _sideSites;
  MapType _mapType = MapType.hybrid;
  String _keyword = "";

//variable de test de recherche de site dans le maps
  bool _searchSite = true;
  final bool _polyLines = false;
  final bool _trafficEnabled = true;

  BitmapDescriptor markerIcon = AppConstants.defaultMarkerIcon;

  void setCustomIcon() {
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(28, 28)),
      Assets.assetsGeopin3,
      width: 28,
      height: 28,
    ).then((value) {
      markerIcon = value;
    }).onError((error, stackTrace) {
      debugPrint("errur : ${error.toString()}");
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
    return PageModel(
      pageIndex: 10,
      title: "Sites maps",
      child: StreamBuilder(
          stream: _siteService.all(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              try {
                var docs = snapshot.data?.docs.map((e) => e.data()).toList();

                _sites = docs!
                    .map((e) => Site.fromJson(e as Map<String, dynamic>))
                    .toList()
                    .where((element) => element.actif == true)
                    .toList();
                _sideSites = _sites
                    .where((element) => element.name
                        .toLowerCase()
                        .contains(_keyword.toLowerCase()))
                    .toList();
                //return SiteScatter(sites: _sites);

                return Row(
                  children: [
                    !_searchSite
                        ? const SizedBox.shrink()
                        : SizedBox(
                            width: 166,
                            child: Column(
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
                                Expanded(
                                  child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: _sideSites.length,
                                      itemBuilder: (context, index) {
                                        Site? site = _sideSites[index];
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
                                              _mapController
                                                  .showMarkerInfoWindow(
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
                          HugeIcons.strokeRoundedCloudUpload,
                          size: 64,
                          color: Theme.of(context).primaryColor,
                        ),
                        const Text("Pas de données"),
                        const SizedBox(height: 8),
                        Text(
                          "Erreur: ${error.toString()}",
                          style: const TextStyle(color: Colors.red),
                        ),
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
