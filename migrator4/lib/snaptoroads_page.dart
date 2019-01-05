import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/maps/snap_to_roads.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  void writePointsToRoute() {}

  void _setRouteMarkers() {
    print(
        'SnapToRoadsPage._setRouteMarkers **************************** ${widget.arLocations.length}');

    try {
      widget.arLocations.forEach((arLocation) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target: LatLng(arLocation.latitude, arLocation.longitude),
                zoom: 12.0)));

        _mapController.addMarker(MarkerOptions(
          position: LatLng(arLocation.latitude, arLocation.longitude),
          icon: BitmapDescriptor.fromAsset('assets/computers.png'),
          zIndex: 4.0,
          infoWindowText: InfoWindowText('Collected on', '${arLocation.date}'),
        ));
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snapped Route Points'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(80),
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
                style: Styles.blueBoldSmall,
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
              zoomGesturesEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
