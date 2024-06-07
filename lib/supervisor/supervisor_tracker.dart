import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spas_web/administration/home.dart';
import 'package:spas_web/const.dart';
import 'package:spas_web/generated/assets.dart';
import 'package:spas_web/services/supervisor.dart';

import '../model.dart';
import '../services/player.dart';
import 'maps_component.dart';

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
    return PageModel(
      pageIdex: 4,
      titile:
          "Position de ${widget.supervisor.firstName} ${widget.supervisor.lastName}",
      child: LocationMapsComponent(supervisor: widget.supervisor,),
    );
  }
}
