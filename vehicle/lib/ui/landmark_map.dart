import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vehicle/vehicle_bloc/vehicle_bloc.dart';

class LandmarkMap extends StatefulWidget {
  @override
  _LandmarkMapState createState() => _LandmarkMapState();
}

class _LandmarkMapState extends State<LandmarkMap> {
  List<LandmarkDTO> landmarks;
  VehicleAppBloc bloc = vehicleAppBloc;
  GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    bloc.searchForLandmarks();
  }

  void _setRouteMarkers() {
    try {
      landmarks.forEach((si) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(si.latitude, si.longitude), zoom: 16.0)));

        _mapController.addMarker(MarkerOptions(
          position: LatLng(si.latitude, si.longitude),
          icon: BitmapDescriptor.fromAsset('assets/computers.png'),
          zIndex: 4.0,
          infoWindowText: InfoWindowText(si.landmarkName, si.associationName),
        ));
      });
      //put own marker
      var loc = bloc.currentLocation;
      _mapController.addMarker(MarkerOptions(
        position: LatLng(loc.coords.latitude, loc.coords.longitude),
//        icon: BitmapDescriptor.fromAsset('assets/taxi.png'),
        zIndex: 4.0,
        infoWindowText: InfoWindowText("We are here", ""),
      ));
    } catch (e) {
      print(e);
    }
  }

  void _onMapCreated() {
    print('###########  ℹ️ _onMapCreated ...............');
    if (landmarks == null) {
      return;
    }
    _setRouteMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: bloc.landmarks,
      stream: bloc.landmarksStream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
            print('🔵 ConnectionState.active set landmarks from stream data');
            landmarks = snapshot.data;
            _onMapCreated();
            break;
          case ConnectionState.waiting:
            print(' 🎾 ConnectionState.waiting .......');
            break;
          case ConnectionState.done:
            print(' 🎾 ConnectionState.done ???');
            break;
          case ConnectionState.none:
            print(' 🎾 ConnectionState.none - do nuthin ...');
            break;
        }
        return Scaffold(
//          appBar: AppBar(
//            title: Text('Landmark Map'),
//          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                onMapCreated: (mapController) {
                  _mapController = mapController;
                  _onMapCreated();
                },
                options: GoogleMapOptions(
                  zoomGesturesEnabled: true,
                  compassEnabled: true,
                  tiltGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  myLocationEnabled: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
