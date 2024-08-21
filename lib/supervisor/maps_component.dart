import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:spas_web/model.dart';

import '../const.dart';
import '../services/loading.dart';
import '../services/superviseur_location.dart';

class LocationMapsComponent extends StatefulWidget {
  LocationMapsComponent({super.key,required this.supervisor});
   Supervisor supervisor;
  @override
  State<LocationMapsComponent> createState() => _MapsComponentState();
}

class _MapsComponentState extends State<LocationMapsComponent> {
  late GoogleMapController _mapController;

  //final Map<String, Marker> _markers = {};


  MapType _mapType = MapType.hybrid;

  SuperviseurLocaion? _currentlocation;

  /*Future<void> addMarkerTomap(SuperviseurLocaion location) async {
    _markers.clear();
    final marker = Marker(
      onTap: () {
        CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(location.latlng.lat, location.latlng.lng),
                zoom: 17));
        _mapController.animateCamera(cameraUpdate);
      },
      markerId: MarkerId("${location.latlng.lat} , ${location.latlng.lng}"),
      position: LatLng(location.latlng.lat, location.latlng.lng),
      infoWindow: InfoWindow(
        title: "${location.latlng.lat} , ${location.latlng.lng}",
        snippet: location.supervisor?.phone,
      ),
    );
    _markers["${location.latlng.lat} , ${location.latlng.lng}"] = marker;

  }*/

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

  }

  @override
  void initState() {
    // TODO: implement initState


    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    LocationService().all().listen((event){
      var collection = event.docs
          .map((snap) {
        return SuperviseurLocaion.fromJson(jsonDecode(jsonEncode(snap.data())));
      }).where((element)=>element.supervisor!.UID==widget.supervisor.UID).toList()??[];
      _currentlocation = collection.first;
      setState(() {

      });
      CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(_currentlocation!.latlng.lat, _currentlocation!.latlng.lng),
              zoom: 30));
      _mapController.animateCamera(cameraUpdate);
    });
  }
  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _mapController.dispose();
    //Audio().stopSOs();
  }
  @override
  Widget build(BuildContext context) {
    return _currentlocation==null?const SizedBox.shrink(): GoogleMap(

      trafficEnabled: true,
      mapType: _mapType,
      markers: {
        Marker(
        onTap: () {
          CameraUpdate cameraUpdate = CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(_currentlocation!.latlng.lat, _currentlocation!.latlng.lng),
                  zoom: 17));
          _mapController.animateCamera(cameraUpdate);
        },
        markerId: MarkerId("${_currentlocation!.latlng.lat} , ${_currentlocation!.latlng.lng}"),
        position: LatLng(_currentlocation!.latlng.lat, _currentlocation!.latlng.lng),
        infoWindow: InfoWindow(
          title: "${_currentlocation!.latlng.lat} , ${_currentlocation!.latlng.lng}",
          snippet: "${_currentlocation!.supervisor?.firstName??""} ${_currentlocation!.supervisor?.lastName??""}",
        ),
      )},
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        // ignore: unnecessary_null_comparison
          target: LatLng(
              _currentlocation!.latlng.lat,
              _currentlocation!.latlng.lng),
          zoom: 15),
    );
  }
}

