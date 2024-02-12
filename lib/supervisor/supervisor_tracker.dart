import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/generated/assets.dart';
import 'package:spas_web/services/supervisor.dart';

import '../model.dart';
import '../services/player.dart';

class SupervisorTracker extends StatefulWidget {
  SupervisorTracker({super.key, required this.supervisor});
  Supervisor supervisor;

  @override
  _SupervisorTrackerState createState() => _SupervisorTrackerState();
}

class _SupervisorTrackerState extends State<SupervisorTracker> {
  late GoogleMapController _mapController;
  final SupervisorService _service = SupervisorService();
  MapType _mapType = MapType.hybrid;
  List<LatLng> _polyLineCoordinates = [];
  BitmapDescriptor markerIcon = AppConstants.defaultMarkerIcon;

  void setCustomIcon() {
    BitmapDescriptor.fromAssetImage(
            const ImageConfiguration(size: Size(48, 48)), Assets.assetsAgent)
        .then((value) {
      markerIcon = value;
    }).onError((error, stackTrace) {
      print("errur : ${error.toString()}");
    });
  }

  void getCurrentLocation() {
    _service.one(widget.supervisor.UID).then((value) {
      widget.supervisor = value ?? widget.supervisor;
    });
    updatePosition().listen((supervisor) {
      widget.supervisor = supervisor;
      setState(() {});
    });
  }

  Stream<Supervisor> updatePosition() {
    return Stream<Supervisor>.periodic(Duration(minutes: 3), (value) {
      Supervisor? supervisor = widget.supervisor;
      _service.one(widget.supervisor.UID).then((value) {
        supervisor = value;
      });
      return supervisor ?? widget.supervisor;
    });
  }

  Future<void> getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PointLatLng pointLatLng = PointLatLng(widget.supervisor.latlng?.lat ?? 0.0,
        widget.supervisor.latlng?.lng ?? 0.0);
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        AppConstants.maps_api_key, pointLatLng, pointLatLng);
    if (result.points.isNotEmpty) {
      for (var polyPoint in result.points) {
        _polyLineCoordinates
            .add(LatLng(polyPoint.latitude, polyPoint.longitude));
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void initState() {
    // TODO: implement initState
    setCustomIcon();
    getCurrentLocation();

    getPolyPoints();
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          "Tracking superviseur",
          style: TextStyle(color: Colors.white),
        ),
      ),
      /*bottomNavigationBar: BottomAppBar(
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
      ),*/
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
      body: GoogleMap(
        polylines: {
          Polyline(
              geodesic: true,
              polylineId: const PolylineId("route"),
              points: _polyLineCoordinates,
              color: Colors.red,
              width: 2),
        },
        trafficEnabled: true,
        mapType: _mapType,
        markers: {
          Marker(
            onTap: () {
              /* CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
                  CameraPosition(
                      target: LatLng(supervisor.latlng?.lat ?? 0.0,
                          supervisor.latlng?.lng ?? 0.0),
                      zoom: 17));
              _mapController.animateCamera(cameraUpdate);*/
            },
            icon: markerIcon,
            markerId: MarkerId(widget.supervisor.UID),
            position: LatLng(widget.supervisor.latlng?.lat ?? 0.0,
                widget.supervisor.latlng?.lng ?? 0.0),
            infoWindow: InfoWindow(
              title:
                  "${widget.supervisor.firstName} ${widget.supervisor.lastName}",
              snippet: widget.supervisor.phone,
            ),
          )
        },
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
            // ignore: unnecessary_null_comparison
            target: LatLng(widget.supervisor.latlng?.lat ?? 0.0,
                widget.supervisor.latlng?.lng ?? 0.0),
            zoom: 15),
      ),
    );
  }
}
