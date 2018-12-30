import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/maps/snap_to_roads.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:location/location.dart';
import 'package:migrator2/snaptoroads_page.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:flutter/scheduler.dart';

class LocationCollector extends StatefulWidget {
  final RouteDTO route;
  LocationCollector({this.route});
  @override
  _LocationCollectorState createState() => _LocationCollectorState();
}

class _LocationCollectorState extends State<LocationCollector>
    implements SnackBarListener {
  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();
  Permission permission = Permission.AccessFineLocation;
  List<ARLocation> locationsCollected = List();

  bg.Config config = bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      stopOnTerminate: false,
      startOnBoot: true,
      debug: true,
      logLevel: bg.Config.LOG_LEVEL_VERBOSE,
      schedule: [
        '1-7 9:00-17:00', // Sun-Sat: 9:00am to 5:00pm (every day)
      ],
      reset: true);
  @override
  void initState() {
    super.initState();
    _checkPermission();
    _getLocationsFromCache();
    bg.BackgroundGeolocation.onActivityChange(_onActivityChanged);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChanged);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 10.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: true,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            reset: true))
        .then((bg.State state) {
      print('++++++++++++ BackgroundGeolocation configured ....');
      print(state);
    });
  }

  _onMotionChanged(bg.Location location) {
    print('&&&&&&&&&&&&& onMotionChanged: location ${location.toMap()}');
    if (location.isMoving) {
      _showSnack(message: 'We are moving ...', color: Colors.green);
      print(
          '************************ WE ARE MOVING ......... LOOK FOR BEACON NOW!!');
    } else {
      print("------------------------  JUST CHILLIN .......");
    }
  }

  _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    print(
        '+++++++++++++++ _onConnectivityChange connected: ${event.connected}');
    _showSnack(
        message: 'Connectivity: ${event.connected}', color: Colors.green);
  }

  _onActivityChanged(bg.ActivityChangeEvent event) {
    print('############# _onActivityChanged: ${event.toMap()}');
    _showSnack(message: event.toString());
  }

  _showSnack({String message, Color color}) {
    AppSnackbar.showSnackbar(
        backgroundColor: Colors.black,
        scaffoldKey: _key,
        textColor: color == null ? Colors.white : color,
        message: message);
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

  void _eraseLocations() async {
    setState(() {
      prevLocation = null;
      locationsCollected.clear();
    });
    await LocalDB.deleteARLocations();
    // LocalDB.delete
  }

  void _getLocationsFromCache() async {
    locationsCollected = await LocalDB.getARLocations();
    setState(() {});
  }

  ARLocation prevLocation;
  void _getGPSLocation() async {
    print(
        '_LocationCollectorState ############# getLocation starting ..............');
    var locationManager = new Location();
    var currentLocation = await locationManager.getLocation();
    var arLoc = ARLocation.fromJson(currentLocation);
    if (prevLocation != null) {
      if (arLoc.latitude == prevLocation.latitude &&
          arLoc.longitude == prevLocation.longitude) {
        print('########## DUPLICATE location .... ignored ');
      } else {
        _saveARLocation(arLoc);
      }
    } else {
      _saveARLocation(arLoc);
    }
  }

  void _saveARLocation(ARLocation arLoc) async {
    try {
      arLoc.routeID = widget.route.routeID;
      prevLocation = arLoc;
      await LocalDB.saveARLocation(location: arLoc);
      locationsCollected = await LocalDB.getARLocations();
      print(
          '+++++++++++_LocationCollectorState location saved ++++++++++++++++++++ cache now has ${locationsCollected.length}\n\n');

      setState(() {
        locationsCollected.add(arLoc);
      });
    } catch (e) {
      print('Problem here??????????');
      print(e);
    }
    return null;
  }

  List<SnappedPoint> snappedPoints;
  void getSnappedPointsFromRoads() async {
    print(
        "########################## getSnappedPointsFromRoads: Snap To Roads API");
    List<ARLocation> list = List();
    locationsCollected.forEach((si) {
      var loc = ARLocation(
        latitude: si.latitude,
        longitude: si.longitude,
      );
      list.add(loc);
    });
    //TODO - testing ... REMOVE ////////////////////////////////////////////////////////
    locationsCollected.clear();
    widget.route.spatialInfos.forEach((si) {
      locationsCollected.add(ARLocation(
        latitude: si.fromLandmark.latitude,
        longitude: si.fromLandmark.longitude,
      ));
    });
    //////////////////////////////////////////////////////////////////////////////////////
    try {
      snappedPoints = await SnapToRoads.getSnappedPoints(list);
      list.clear();
      snappedPoints.forEach((sp) {
        list.add(sp.location);
      });
      print(
          '\n\n\n##################### sending ${list.length} to SnapToRoadsPage ########################\n\n\n');
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext context) => SnapToRoadsPage(
                    route: widget.route,
                    arLocations: list,
                  )));
    } catch (e) {
      print(e);
      AppSnackbar.showErrorSnackbar(
        scaffoldKey: _key,
        message: '******** Problem calling Google Roads API $e',
        actionLabel: "Close",
        listener: this,
      );
    }
    return null;
  }

  @override
  void onActionPressed(int action) {}
  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    });
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('LocationCollector'),
        backgroundColor: Colors.pink.shade300,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Container(
                        child: Text(
                          widget.route.name,
                          style: Styles.whiteMedium,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                  ],
                ),
                SizedBox(
                  height: 8,
                ),
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 20,
                    ),
                    Flexible(
                      child: Container(
                        child: Text(
                          widget.route.associationName,
                          style: Styles.blackBoldSmall,
                          overflow: TextOverflow.clip,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                  ],
                ),
                SizedBox(
                  height: 0,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          controller: scrollController,
          itemCount: locationsCollected.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 2.0,
              color: getRandomPastelColor(),
              child: ListTile(
                leading: Icon(
                  Icons.location_on,
                  color: getRandomColor(),
                ),
                title: Text(
                    'Collected at ${getFormattedDateShortWithTime(DateTime.now().toIso8601String(), context)}',
                    style: Styles.blackBoldSmall),
                subtitle: Text(
                    '${locationsCollected.elementAt(index).latitude} ${locationsCollected.elementAt(index).longitude}  #${index + 1}',
                    style: Styles.greyLabelSmall),
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.brown.shade100,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.cancel,
              size: 40,
              color: Colors.pink,
            ),
            title: Text('Erase Locations'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_location, size: 40, color: Colors.blue),
            title: Text('Build Route'),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.location_on,
              size: 40,
              color: Colors.black,
            ),
            title: Text('Get Location Here'),
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              _eraseLocations();
              break;
            case 1:
              getSnappedPointsFromRoads();
              break;
            case 2:
              _getGPSLocation();
              break;
          }
        },
      ),
    );
  }
}
