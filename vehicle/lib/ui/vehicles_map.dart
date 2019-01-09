import 'package:aftarobotlibrary3/data/vehicle_location.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vehicle/vehicle_bloc/vehicle_bloc.dart';

class VehiclesMap extends StatefulWidget {
  @override
  _VehiclesMapState createState() => _VehiclesMapState();
}

class _VehiclesMapState extends State<VehiclesMap> {
  List<VehicleLocation> vehicleLocations;
  VehicleAppBloc bloc = VehicleAppBloc();
  GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    bloc.searchForVehiclesAroundUs();
  }

  void _setRouteMarkers() {
    try {
      vehicleLocations.forEach((si) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(si.latitude, si.longitude), zoom: 16.0)));

        _mapController.addMarker(MarkerOptions(
          position: LatLng(si.latitude, si.longitude),
          icon: BitmapDescriptor.fromAsset('assets/condominium.png'),
          zIndex: 4.0,
          infoWindowText: InfoWindowText(
              '${si.vehicle.vehicleType.model} ${si.vehicle.vehicleType.model}',
              si.date),
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
      printLog(e);
    }
  }

  void _onMapCreated() {
    printLog('###########  ℹ️ _onMapCreated ...............');
    if (vehicleLocations == null) {
      return;
    }
    _setRouteMarkers();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      initialData: bloc.vehicleLocations,
      stream: bloc.vehicleLocationStream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
            printLog(
                '🔵 ConnectionState.active set vehicleLocations from stream data');
            vehicleLocations = snapshot.data;
            _onMapCreated();
            break;
          case ConnectionState.waiting:
            printLog(' 🎾 onnectionState.waiting .......');
            break;
          case ConnectionState.done:
            printLog(' 🎾 ConnectionState.done ???');
            break;
          case ConnectionState.none:
            printLog(' 🎾 ConnectionState.none - do nuthin ...');
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
              Positioned(
                left: 40,
                top: 20,
                child: Card(
                  color: getRandomPastelColor(),
                  elevation: 8,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Row(
                            children: <Widget>[
                              Text(
                                'AftaRobot Taxi Map',
                                style: Styles.blackBoldSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
