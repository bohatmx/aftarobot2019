import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/api/file_util.dart';
import 'package:aftarobotlibrary3/api/list_api.dart';
import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class RouteViewerPage extends StatefulWidget {
  @override
  _RouteViewerPageState createState() => _RouteViewerPageState();
}

/*
  #region
*/
class _RouteViewerPageState extends State<RouteViewerPage>
    implements RouteCardListener, SnackBarListener {
  List<RouteDTO> routes;
  List<LandmarkDTO> landmarks;
  ScrollController scrollController = ScrollController();
  String status = 'AftaRobot Routes';
  int routeCount = 0, landmarkCount = 0;
  List<AssociationDTO> asses = List();

  static const platformDirections = const MethodChannel('aftarobot/directions');
  static const platformDistance = const MethodChannel('aftarobot/distance');
  static const beaconScanStream = const EventChannel('aftarobot/beaconScan');

  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();
  int beaconCount = 0;
  @override
  void initState() {
    super.initState();
    _getNewRoutes();
    _checkPermission();
  }

  _requestPermission() async {
    print('\n\n######################### requestPermission');
    try {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.location]);
      print(permissions);
      print("\n########### permission request for location is:  ✅ ");
    } catch (e) {
      print(e);
    }
  }

  _checkPermission() async {
    print('\n\n######################### checkPermission');
    try {
      PermissionStatus locationPermission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.location);

      if (locationPermission == PermissionStatus.denied) {
        _requestPermission();
      } else {
        print(
            "***************** location permission status is:  ✅  ✅ $locationPermission");
      }
    } catch (e) {
      print(e);
    }
  }

  Future _getDirections(
      {double originLatitude,
      double originLongitude,
      double destinationLatitude,
      double destinationLongitude}) async {
    print(
        '\n\n_RouteViewerPageState: ################## _getDirections ******************');
    var map = {
      'originLatitude': originLatitude,
      'originLongitude': originLongitude,
      'destinationLatitude': destinationLatitude,
      'destinationLongitude': destinationLongitude,
    };
    var string = json.encode(map);
    print("sending $string to channel for directions");
    try {
      final String result =
          await platformDirections.invokeMethod('getDirections', string);
      var map = json.decode(result);
      print(
          '_RouteViewerPageState: ########## map from directionsChannel $map');
    } on PlatformException catch (e) {
      print(e);
    }
  }

  Timer timer;
  void _startTimer() {}
  void _setCounters() {
    setState(() {
      routeCount = routes.length;
      landmarkCount = landmarks.length;
    });
  }

  void _getNewRoutes() async {
    routes = await LocalDB.getRoutes();
    landmarks = await LocalDB.getLandmarks();
    _setCounters();
    routes = await ListAPI.getRoutes();
    landmarks = await ListAPI.getLandmarks();

    _sortRoutes();
    _setCounters();
    LocalDB.saveRoutes(Routes(routes));
    LocalDB.saveLandmarks(Landmarks(landmarks));
  }

  void _sortRoutes() {
    routes.sort((a, b) =>
        (a.associationName + a.name).compareTo((b.associationName + b.name)));
  }

  void _refresh() async {
    print('_RouteViewerPageState._refresh .................');
    routes = await ListAPI.getRoutes();
    landmarks = await ListAPI.getLandmarks();
    _sortRoutes();
    _setCounters();

    await LocalDB.saveRoutes(Routes(routes));
    await LocalDB.saveLandmarks(Landmarks(landmarks));

    print('_RouteViewerPageState._refresh ------- done. saved data in cache');
  }

  DateTime start, end;

  Widget _getListView() {
    return ListView.builder(
        itemCount: routes == null ? 0 : routes.length,
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16.0),
            child: RouteCard(
              route: routes.elementAt(index),
              number: index + 1,
              hideLandmarks: switchStatus,
              listener: this,
            ),
          );
        });
  }

  String switchLabel = 'Hide';
  bool switchStatus = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('AftaRobot Routes'),
        backgroundColor: Colors.indigo.shade300,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0),
            child: IconButton(
              onPressed: _refresh,
              iconSize: 28,
              icon: Icon(Icons.refresh),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 20,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '$routeCount',
                            style: Styles.blackBoldLarge,
                          ),
                          Text(
                            'Routes',
                            style: Styles.whiteSmall,
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '$landmarkCount',
                            style: Styles.blackBoldLarge,
                          ),
                          Text(
                            'Landmarks',
                            style: Styles.whiteSmall,
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 80,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _getListView(),
      backgroundColor: Colors.brown.shade100,
    );
  }

  @override
  onRouteTapped(RouteDTO route) async {
    print(
        '_RouteViewerPageState.onRouteTapped: &&&&&&&&&&& route: ${route.name}');
  }

  @override
  onActionPressed(int action) {
    return null;
  }
}

/*
  #region
*/
abstract class RouteCardListener {
  onRouteTapped(RouteDTO route);
}

class RouteCard extends StatefulWidget {
  final RouteDTO route;
  final Color color;
  final int number;
  final bool hideLandmarks;
  final RouteCardListener listener;

  RouteCard(
      {this.route, this.color, this.number, this.hideLandmarks, this.listener});

  @override
  _RouteCardState createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  int index = 0;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  void _expansionCallBack(int panelIndex, bool isExpanded) {
    print(
        ".................. _expansionCallBack panelIndex: $panelIndex isExpanded: $isExpanded");
    setState(() {
      this.isExpanded = !isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0,
      color: getRandomPastelColor(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: () {
                print(
                    '_RouteCardState.build --- route name tapped: ${widget.route.name}');
                if (widget.listener != null) {
                  widget.listener.onRouteTapped(widget.route);
                }
              },
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 40,
                    child: Text(
                      widget.number == null ? '0' : '${widget.number}',
                      style: Styles.pinkBoldSmall,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      child: Text(
                        widget.route.name,
                        style: Styles.blackBoldMedium,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                ),
                Flexible(
                  child: Container(
                    child: Text(
                      widget.route.associationName,
                      style: Styles.greyLabelSmall,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10,
            ),
            //_buildSpatialInfoList(),
          ],
        ),
      ),
    );
  }
}
