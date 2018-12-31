import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/util/maps/snap_to_roads.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:migrator2/bloc/route_builder_bloc.dart';
import 'package:migrator2/location_collector.dart';

// ✅  🎾 🔵  📍   ℹ️
class LocationCollectionMap extends StatefulWidget {
  final RouteDTO route;
  LocationCollectionMap({this.route});
  @override
  _LocationCollectionMapState createState() => _LocationCollectionMapState();
}

class _LocationCollectionMapState extends State<LocationCollectionMap>
    implements ModesListener {
  final RouteBuilderBloc bloc = routeBuilderBloc;
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  List<ARLocation> locationsCollected = List();
  GoogleMapController _mapController;
  int collectionSeconds = 10;
  @override
  onModeSelected(int seconds) {
    setState(() {
      collectionSeconds = seconds;
    });
    startCollection();
  }

  startCollection() {
    try {
      bloc.startRoutePointCollectionTimer(collectionSeconds: collectionSeconds);
      _showSnack(
          message: 'Collection started -  ✅  ', color: Colors.lightGreen);
    } catch (e) {
      print(e);
    }
  }

  stopCollection() {
    try {
      bloc.stopRoutePointCollectionTimer();
      _showSnack(
          message: 'Collection stopped -   ⚠️ ', color: Colors.lightGreen);
    } catch (e) {
      print(e);
    }
  }

  _showSnack({String message, Color color}) {
    AppSnackbar.showSnackbar(
        backgroundColor: Colors.black,
        scaffoldKey: _key,
        textColor: color == null ? Colors.white : color,
        message: message);
  }

  void _setRouteMarkers() {
    try {
      locationsCollected.forEach((si) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(si.latitude, si.longitude), zoom: 12.0)));

        _mapController.addMarker(MarkerOptions(
          position: LatLng(si.latitude, si.longitude),
          icon: BitmapDescriptor.fromAsset('assets/computers.png'),
          zIndex: 4.0,
          infoWindowText: InfoWindowText(
              'Collected Route Point', '${si.latitude} ${si.longitude}'),
        ));
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    print('################ LocationCollectionMap build +++++ re-building');
    return StreamBuilder(
      initialData: bloc.model,
      stream: bloc.stream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
            print(
                'LocationCollectionMap: StreamBuilder ConnectionState is active - ✅  - updating model');
            var model = snapshot.data;
            locationsCollected = model.arLocations;
            _setRouteMarkers();
            break;
          case ConnectionState.waiting:
            print(
                'LocationCollectionMap: StreamBuilder ConnectionState is waiting - ️️ℹ️  ...');
            break;
          case ConnectionState.done:
            print(
                'LocationCollectionMap: StreamBuilder ConnectionState is done - ️️ 🔵  ...');
            break;
          case ConnectionState.none:
            print(
                'LocationCollectionMap: StreamBuilder ConnectionState is none - ️️ 🎾  ...');
            break;
        }

        return Scaffold(
          key: _key,
          appBar: AppBar(
            title: Text('Route Point Collector'),
          ),
          body: Stack(
            children: <Widget>[
              GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  print('++++ ✅  ++++ ✅  GoogleMap created');
                  _mapController = controller;
                  _setRouteMarkers();
                },
                options: GoogleMapOptions(
                  myLocationEnabled: true,
                  compassEnabled: true,
                  zoomGesturesEnabled: true,
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Modes(
                  listener: this,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
