import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:commuter/bloc/commuter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LandmarkMap extends StatefulWidget {
  final CommuterBloc commuterBloc;
  final LandmarkDTO landmark;

  LandmarkMap({@required this.commuterBloc, @required this.landmark});

  @override
  _LandmarkMapState createState() => _LandmarkMapState();
}

class _LandmarkMapState extends State<LandmarkMap> {
  List<LandmarkDTO> landmarks;
  GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _getRouteLandmarks();
  }

  Future _getRouteLandmarks() async {
    landmarks = await widget.commuterBloc
        .getRouteLandmarks(routeID: widget.landmark.routeID);
  }

  void _setRouteMarkers() {
    try {
      landmarks.forEach((si) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(si.latitude, si.longitude), zoom: 16.0)));

        _mapController.addMarker(MarkerOptions(
          position: LatLng(si.latitude, si.longitude),
          icon: BitmapDescriptor.fromAsset('assets/condominium.png'),
          zIndex: 4.0,
          infoWindowText: InfoWindowText(si.landmarkName, si.associationName),
        ));
      });
      //put own marker
      _mapController.addMarker(MarkerOptions(
        position: LatLng(widget.landmark.latitude, widget.landmark.longitude),
//        icon: BitmapDescriptor.fromAsset('assets/taxi.png'),
        zIndex: 4.0,
        infoWindowText: InfoWindowText(
            '${widget.landmark.landmarkName}', "${widget.landmark.routeName}"),
      ));
    } catch (e) {
      printLog(e);
    }
  }

  void _onMapCreated() {
    printLog('###########  ℹ️ _onMapCreated ...............');
    if (landmarks == null) {
      return;
    }
    _setRouteMarkers();
  }

  @override
  Widget build(BuildContext context) {
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
  }
}
