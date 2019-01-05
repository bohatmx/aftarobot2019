import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/maps/snap_to_roads.dart';
import 'package:aftarobotlibrary3/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vehicle/vehicle_bloc/vehicle_bloc.dart';


// ✅  🎾 🔵  📍   ℹ️
class LandmarkMap extends StatefulWidget {

  @override
  _LandmarkMapState createState() => _LandmarkMapState();
}

class _LandmarkMapState extends State<LandmarkMap> {
  final VehicleAppBloc bloc = vehicleBloc;;
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  GoogleMapController _mapController;
  int collectionSeconds = 30;
  final List<LandmarkDTO> landmarks = List();
  @override
  void initState() {
    super.initState();

  }

  void _getLocation() {

    bloc.searchForLandmarks(latitude, longitude, radius)
  }

  void _setRouteMarkers() {
    try {
      landmarks.forEach((si) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(si.latitude, si.longitude), zoom: 12.0)));

        _mapController.addMarker(MarkerOptions(
          position: LatLng(si.latitude, si.longitude),
          icon: BitmapDescriptor.fromAsset('assets/computers.png'),
          zIndex: 4.0,
          infoWindowText: InfoWindowText(
              si.landmarkName, si.associationName),
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
      initialData: bloc.landmarks,
      stream: bloc.landmarksStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
            print(
                'LocationCollectionMap: StreamBuilder ConnectionState is active - ✅  - updating model');
            var model = snapshot.data;
            landmarks = model.arLocations;
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
            backgroundColor: Colors.brown.shade300,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(120),
              child: Column(
                children: <Widget>[
                  Text(
                    widget.route == null ? 'No Route?' : widget.route.name,
                    style: Styles.whiteBoldSmall,
                  ),
                  Text(
                    widget.route == null
                        ? 'No Association?'
                        : widget.route.associationName,
                    style: Styles.blackBoldSmall,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Counter(
                        label: 'Collected',
                        total: bloc.model.arLocations.length,
                        totalStyle: Styles.blackBoldReallyLarge,
                        labelStyle: Styles.whiteBoldSmall,
                      ),
                      SizedBox(
                        width: 40,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: Icon(Icons.cancel),
                  onPressed: stopCollection,
                ),
              ),
            ],
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
                bottom: 10,
                left: 10,
                child: Hero(
                  child: Modes(
                    listener: this,
                  ),
                  tag: 'modes',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
