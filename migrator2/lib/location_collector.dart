import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/maps/snap_to_roads.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:simple_permissions/simple_permissions.dart';

class LocationCollector extends StatefulWidget {
  final RouteDTO route;

  const LocationCollector({Key key, this.route}) : super(key: key);
  @override
  _LocationCollectorState createState() => _LocationCollectorState();
}

class _LocationCollectorState extends State<LocationCollector>
    implements SnackBarListener {
  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();
  Permission permission = Permission.AccessFineLocation;
  List<ARLocation> locationsCollected = List();
  @override
  void initState() {
    super.initState();

    _checkPermission();
  }

  void _getLocation() async {
    var locationManager = new Location();
    var currentLocation = await locationManager.getLocation();
    var arLoc = ARLocation.fromJson(currentLocation);

    arLoc.routeID = widget.route.routeID;
    await LocalDB.saveARLocation(arLoc);
    setState(() {
      locationsCollected.add(arLoc);
    });
    AppSnackbar.showSnackbarWithAction(
      scaffoldKey: _key,
      action: 1,
      message: 'Location has been collected',
      actionLabel: 'Cool',
      textColor: Colors.white,
      backgroundColor: Colors.teal.shade700,
      icon: Icons.location_on,
      listener: this,
    );
  }

  _requestPermission() async {
    print('\n\n######################### requestPermission');
    try {
      final res = await SimplePermissions.requestPermission(permission);
      print("\n########### permission request result is " + res.toString());
    } catch (e) {
      print(e);
    }
  }

  _checkPermission() async {
    print('\n\n######################### checkPermission');
    try {
      bool res = await SimplePermissions.checkPermission(permission);
      print("***************** permission checked is " + res.toString() + '\n');
      if (res == false) {
        _requestPermission();
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LocationCollector'),
        backgroundColor: Colors.pink.shade300,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: Column(
            children: <Widget>[
              RaisedButton(
                color: Colors.blue,
                elevation: 6,
                onPressed: _getLocation,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Start Collection', style: Styles.whiteMedium),
                ),
              ),
              SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(32.0),
        child: ListView.builder(
          itemCount: locationsCollected.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(Icons.my_location),
              title: Text('Collected at ${DateTime.now().toIso8601String()}',
                  style: Styles.blackBoldSmall),
              subtitle: Text(
                  '${locationsCollected.elementAt(index).latitude} ${locationsCollected.elementAt(index).longitude}',
                  style: Styles.greyLabelSmall),
            );
          },
        ),
      ),
    );
  }

  @override
  onActionPressed(int action) {
    // TODO: implement onActionPressed
    return null;
  }
}
