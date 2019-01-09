import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/data/spatialinfodto.dart';
import 'package:aftarobotlibrary3/util/city_map_search.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:routebuilder/bloc/route_builder_bloc.dart';
import 'package:routebuilder/ui/location_collector.dart';

class RouteViewerPage extends StatefulWidget {
  @override
  _RouteViewerPageState createState() => _RouteViewerPageState();
}

/*
  #region
*/
class _RouteViewerPageState extends State<RouteViewerPage>
    implements RouteCardListener, SnackBarListener {
  ScrollController scrollController = ScrollController();
  String status = 'AftaRobot Routes';
  int routeCount = 0, landmarkCount = 0;
  List<AssociationDTO> asses = List();

  static const platformDirections = const MethodChannel('aftarobot/directions');
  static const platformDistance = const MethodChannel('aftarobot/distance');
  static const beaconScanStream = const EventChannel('aftarobot/beaconScan');

  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();
  int beaconCount = 0;
  RouteBuilderBloc _bloc = routeBuilderBloc;
  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  void _checkPermission() async {
    bool ok = await _bloc.checkPermission();
    if (!ok) {
      await _bloc.requestPermission();
    }
  }

  void _startRouteBuilding() async {
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

  void _sortRoutes() {
    appModel.routes.sort((a, b) =>
        (a.associationName + a.name).compareTo((b.associationName + b.name)));
  }

  void _refresh() async {
    print('_RouteViewerPageState._refresh .................');
    AppSnackbar.showSnackbarWithProgressIndicator(
        scaffoldKey: _key,
        message: 'Loading fresh data',
        textColor: Colors.yellow,
        backgroundColor: Colors.black);
    await _bloc.getRoutes();
    await _bloc.getLandmarks();
    _key.currentState.removeCurrentSnackBar();
  }

  DateTime start, end;

  Widget _getListView() {
    return ListView.builder(
        itemCount: appModel == null ? 0 : appModel.routes.length,
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16.0),
            child: RouteCard(
              route: appModel.routes.elementAt(index),
              number: index + 1,
              hideLandmarks: switchStatus,
              listener: this,
            ),
          );
        });
  }

  String switchLabel = 'Hide';
  bool switchStatus = false;
  RouteBuilderModel appModel;
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RouteBuilderModel>(
      initialData: _bloc.model,
      stream: _bloc.appModelStream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
            printLog('🔵 ConnectionState.active set data from stream data');
            appModel = snapshot.data;
            _sortRoutes();
            break;
          case ConnectionState.waiting:
            printLog(' 🎾 onnectionState.waiting .......');
            break;
          case ConnectionState.done:
            printLog(' 🎾 ConnectionState.done ???');
            break;
          case ConnectionState.none:
            printLog(' 🎾 ConnectionState.none - do nuthin ...');
            break;
        }
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
                  iconSize: 24,
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
                                appModel == null
                                    ? '0'
                                    : '${appModel.routes.length}',
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
                                appModel == null
                                    ? '0'
                                    : '${appModel.landmarks.length}',
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
      },
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
                FlatButton(
                  color: Colors.pink,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                FlatButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _proceedToMap(route);
                  },
                  color: Colors.teal.shade500,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
              height: 10,
            ),
            //_buildSpatialInfoList(),
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
