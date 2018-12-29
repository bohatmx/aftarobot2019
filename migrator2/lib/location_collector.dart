import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/maps/snap_to_roads.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:simple_permissions/simple_permissions.dart';
import 'package:flutter/scheduler.dart';

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
    _getLocationsFromCache();
  }

  void _eraseLocations() async {
    setState(() {
      locationsCollected.clear();
    });
    // LocalDB.delete
  }

  void _getLocationsFromCache() async {
    locationsCollected = await LocalDB.getARLocations();
    setState(() {});
  }

  void _getLocation() async {
    print('############# getLocation starting ..............');
    var locationManager = new Location();
    var currentLocation = await locationManager.getLocation();
    var arLoc = ARLocation.fromJson(currentLocation);

    try {
      arLoc.routeID = widget.route.routeID;
      await LocalDB.saveARLocation(arLoc);
      locationsCollected = await LocalDB.getARLocations();
      print(
          '+++++++++++ location saved ++++++++++++++++++++ cache has ${locationsCollected.length}');

      setState(() {
        locationsCollected.add(arLoc);
      });
    } catch (e) {
      print(e);
    }

    // AppSnackbar.showSnackbarWithAction(
    //   scaffoldKey: _key,
    //   action: 1,
    //   message: 'Location has been collected',
    //   actionLabel: 'Cool',
    //   textColor: Colors.white,
    //   backgroundColor: Colors.teal.shade700,
    //   icon: Icons.location_on,
    //   listener: this,
    // );
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
              break;
            case 2:
              _getLocation();
              break;
          }
        },
      ),
    );
  }

  @override
  onActionPressed(int action) {
    return null;
  }
}
