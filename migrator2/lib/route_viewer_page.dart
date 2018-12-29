import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/api/list_api.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/spatialinfodto.dart';
import 'package:aftarobotlibrary/util/city_map_search.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/maps/snap_to_roads.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:migrator2/location_collector.dart';
import 'package:simple_permissions/simple_permissions.dart';

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
  Permission permission = Permission.AccessFineLocation;
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

  void _startRouteBuilding() async {
    await _startDirectionsTest(route);
    print(
        '\n########### startRouteBuilding ------------------------------ ...');
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LocationCollector(route: route)));
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
    if (routes.isEmpty) {
      routes = await ListAPI.getRoutes();
      landmarks = await ListAPI.getLandmarks();
    }
    _setCounters();
  }

  void _refresh() async {
    print('_RouteViewerPageState._refresh .................');
    routes = await ListAPI.getRoutes();
    landmarks = await ListAPI.getLandmarks();
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
              icon: Icon(Icons.my_location),
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
                      Column(
                        children: <Widget>[
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            switchStatus == false ? 'Hide' : 'Show',
                            style: switchStatus == false
                                ? Styles.blackSmall
                                : Styles.yellowBoldSmall,
                          ),
                          Switch(
                            onChanged: _onSwitchChanged,
                            value: switchStatus,
                            activeColor: Colors.yellow,
                          ),
                        ],
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

  List<LandmarkDTO> newLandmarks = List();

  void _onSwitchChanged(bool value) {
    print('_RouteViewerPageState._onSwitchChanged hideRoutes = $value');
    setState(() {
      switchStatus = value;
    });
  }

  RouteDTO route;
  @override
  onRouteTapped(RouteDTO route) async {
    this.route = route;
    print(
        '_RouteViewerPageState.onRouteTapped: &&&&&&&&&&& route: ${route.name}');
    _showChoiceDialog();
  }

  void _showChoiceDialog() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text(
                "Action Stations!",
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor),
              ),
              content: Container(
                height: 120.0,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Please select the way you want to go',
                        style: Styles.blackBoldMedium,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                RaisedButton(
                  elevation: 4.0,
                  color: Colors.pink,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Route Build',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _startRouteBuilding();
                  },
                ),
                SizedBox(
                  width: 20,
                ),
                RaisedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _proceedToMap(route);
                  },
                  elevation: 4.0,
                  color: Colors.teal.shade500,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Start Map',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ));
  }

  void _proceedToMap(RouteDTO route) async {
    //await _startDirectionsTest(route);
    _goToMapSearch(context: context, route: route);
  }

  Future _startDirectionsTest(RouteDTO route) async {
    route.spatialInfos.sort((a, b) => a.fromLandmark.rankSequenceNumber);
    var info1 = route.spatialInfos.first;
    var info2 = route.spatialInfos.last;

    AppSnackbar.showSnackbar(
        scaffoldKey: _key,
        message:
            'Getting route directions: ${info1.fromLandmark.landmarkName} to ${info2.fromLandmark.landmarkName}',
        backgroundColor: Colors.black,
        textColor: Colors.white);
    var start = DateTime.now();

    await _getDirections(
      originLatitude: info1.fromLandmark.latitude,
      originLongitude: info1.fromLandmark.longitude,
      destinationLatitude: info2.fromLandmark.latitude,
      destinationLongitude: info2.fromLandmark.longitude,
    );
    var end = DateTime.now();
    print(
        '######### directions received, elapsed time: ${end.difference(start).inSeconds}');
    return null;
  }


  void _goToMapSearch(
      {BuildContext context, LandmarkDTO landmark, RouteDTO route}) {
    
    if (route != null) {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => CityMapSearch(
                  route: route,
                )),
      );
    } else {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => CityMapSearch(
                  landmark: landmark,
                )),
      );
    }
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
    widget.route.spatialInfos.sort((a, b) => a.fromLandmark.rankSequenceNumber
        .compareTo(b.fromLandmark.rankSequenceNumber));
  }

  void _expansionCallBack(int panelIndex, bool isExpanded) {
    print(
        ".................. _expansionCallBack panelIndex: $panelIndex isExpanded: $isExpanded");
    setState(() {
      this.isExpanded = !isExpanded;
    });
  }

  Widget _buildSpatialInfoList() {
    List<SpatialInfoPair> pairs = List();
    widget.route.spatialInfos.forEach((si) {
      pairs.add(SpatialInfoPair(
        spatialInfo: si,
        route: widget.route,
      ));
    });
    List<ExpansionPanel> list = List();
    var panel = ExpansionPanel(
      isExpanded: isExpanded,
      headerBuilder: (context, isExpanded) {
        print('ExpansionPanel headerBuilder $isExpanded');
        return Row(
          children: <Widget>[
            SizedBox(
              width: 20,
            ),
            Text('Route Landmarks', style: Styles.greyLabelMedium)
          ],
        );
      },
      body: Column(
        children: pairs,
      ),
    );
    list.add(panel);
    return ExpansionPanelList(
      animationDuration: Duration(milliseconds: 500),
      children: list,
      expansionCallback: _expansionCallBack,
    );
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
              height: 20,
            ),
            _buildSpatialInfoList(),
          ],
        ),
      ),
    );
  }
}

class SpatialInfoPair extends StatelessWidget {
  final SpatialInfoDTO spatialInfo;
  final RouteDTO route;

  SpatialInfoPair({this.route, this.spatialInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            _goToMap(context: context, landmark: spatialInfo.fromLandmark);
          },
          child: ListTile(
            title: Row(
              children: <Widget>[
                Text(
                  '${spatialInfo.fromLandmark.rankSequenceNumber}',
                  style: Styles.blueBoldSmall,
                ),
                SizedBox(
                  width: 12,
                ),
                Flexible(
                  child: Container(
                    child: Text(
                      '${spatialInfo.fromLandmark.landmarkName}',
                      style: Styles.blackBoldSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: <Widget>[
                SizedBox(
                  width: 20,
                ),
                Text(
                  '${spatialInfo.fromLandmark.latitude}  ${spatialInfo.fromLandmark.longitude}',
                  style: Styles.greyLabelSmall,
                ),
              ],
            ),
            leading: Icon(
              Icons.my_location,
              color: Colors.teal.shade700,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _goToMap(context: context, landmark: spatialInfo.toLandmark);
          },
          child: ListTile(
            title: Row(
              children: <Widget>[
                Text(
                  '${spatialInfo.toLandmark.rankSequenceNumber}',
                  style: Styles.blueBoldSmall,
                ),
                SizedBox(
                  width: 12,
                ),
                Flexible(
                  child: Container(
                    child: Text(
                      '${spatialInfo.toLandmark.landmarkName}',
                      style: Styles.blackBoldSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 20,
                    ),
                    Text(
                      '${spatialInfo.toLandmark.latitude}  ${spatialInfo.toLandmark.longitude}',
                      style: Styles.greyLabelSmall,
                    ),
                  ],
                ),
              ],
            ),
            leading: Icon(
              Icons.my_location,
              color: Colors.pink.shade600,
            ),
          ),
        ),
      ],
    );
  }

  void _goToMap({BuildContext context, LandmarkDTO landmark, RouteDTO route}) {
    if (route != null) {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => CityMapSearch(
                  route: route,
                )),
      );
    } else {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => CityMapSearch(
                  landmark: landmark,
                )),
      );
    }
  }
}
