import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/maps/snap_to_roads.dart';
import 'package:aftarobotlibrary3/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:routebuilder/bloc/route_builder_bloc.dart';

/*
Handles location points collected on the route roads and obtains snapped-to-road points
*/
class SnapToRoadsPage extends StatefulWidget {
  final List<ARLocation> arLocations;
  final RouteDTO route;

  const SnapToRoadsPage(
      {Key key, @required this.arLocations, @required this.route})
      : super(key: key);
  @override
  _SnapToRoadsPageState createState() => _SnapToRoadsPageState();
}

class _SnapToRoadsPageState extends State<SnapToRoadsPage> {
  GlobalKey<ScaffoldState> _key = GlobalKey();
  List<SnappedPoint> snappedPoints;
  GoogleMapController _mapController;
  bool isMapReady = false;

  @override
  void initState() {
    super.initState();
  }

  void _writePointsToRoute() async {
    printLog(
        '_SnapToRoadsPageState::_writePointsToRoute - ⚠️ adding ${widget.arLocations.length} route points for '
        ' ${widget.route.name}');
    AppSnackbar.showSnackbarWithProgressIndicator(
        scaffoldKey: _key,
        message: 'Adding route points ...',
        textColor: Colors.yellow,
        backgroundColor: Colors.black);

    await routeBuilderBloc.addRoutePoints(
        route: widget.route, points: widget.arLocations);

    AppSnackbar.showSnackbarWithProgressIndicator(
        scaffoldKey: _key,
        message: '${widget.arLocations.length} route points added',
        textColor: Colors.white,
        backgroundColor: Colors.black);
  }

  void _setRouteMarkers() {
    print(
        'SnapToRoadsPage._setRouteMarkers **************************** ${widget.arLocations.length}');

    try {
      _mapController.clearMarkers();
      widget.arLocations.forEach((arLocation) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(arLocation.latitude, arLocation.longitude),
                zoom: 14.0)));

        _mapController.addMarker(MarkerOptions(
          position: LatLng(arLocation.latitude, arLocation.longitude),
          icon: BitmapDescriptor.fromAsset('assets/taxi.png'),
          zIndex: 4.0,
          infoWindowText: InfoWindowText('Collected Point',
              arLocation.date == null ? '' : '${arLocation.date}'),
        ));
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('Snapped Route Points'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Column(
            children: <Widget>[
              Text(
                widget.route.associationName,
                style: Styles.whiteBoldMedium,
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                widget.route.name,
                style: Styles.whiteBoldSmall,
              ),
              SizedBox(
                height: 12,
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: (controller) {
              print(
                  'SnapToRoadsPage.build ------ ....................... onMapCreated');
              _mapController = controller;
              isMapReady = true;
              _setRouteMarkers();
            },
            options: GoogleMapOptions(
              myLocationEnabled: true,
              compassEnabled: true,
              trackCameraPosition: true,
              zoomGesturesEnabled: true,
            ),
          ),
          Positioned(
            left: 20,
            top: 20,
            child: RaisedButton(
              elevation: 20,
              color: Colors.pink,
              onPressed: () {
                _writePointsToRoute();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Add To Route',
                  style: Styles.whiteSmall,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
