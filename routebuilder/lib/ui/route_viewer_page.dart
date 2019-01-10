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
import 'package:routebuilder/ui/location_collection_map.dart';
import 'package:routebuilder/ui/location_collector.dart';

/*
  This widget manages a list of routes. A route builder selects a route and starts the LocationCollector
  for collection of raw route points.
 */
class RouteViewerPage extends StatefulWidget {
  @override
  _RouteViewerPageState createState() => _RouteViewerPageState();
}

class _RouteViewerPageState extends State<RouteViewerPage>
    implements SnackBarListener {
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
            padding: const EdgeInsets.only(left: 16.0, right: 16, top: 4.0),
            child: RouteCard(
              route: appModel.routes.elementAt(index),
              number: index + 1,
              hideLandmarks: switchStatus,
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
                  iconSize: 18,
                  icon: Icon(Icons.refresh),
                ),
              ),
            ],
            bottom: _getTotalsView(),
          ),
          body: _getListView(),
          backgroundColor: Colors.brown.shade100,
        );
      },
    );
  }

  Widget _getTotalsView() {
    return PreferredSize(
      preferredSize: Size.fromHeight(80),
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
                        appModel == null ? '0' : '${appModel.routes.length}',
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
                        appModel == null ? '0' : '${appModel.landmarks.length}',
                        style: Styles.blackBoldLarge,
                      ),
                      Text(
                        'Landmarks',
                        style: Styles.whiteSmall,
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
    );
  }

  @override
  onActionPressed(int action) {
    return null;
  }
}

class RouteCard extends StatefulWidget {
  final RouteDTO route;
  final Color color;
  final int number;
  final bool hideLandmarks;

  RouteCard({this.route, this.color, this.number, this.hideLandmarks});

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

  List<PopupMenuItem<String>> menuItems = List();
  _buildMenuItems() {
    menuItems.clear();
    menuItems.add(PopupMenuItem<String>(
      value: 'Collect Route Points',
      child: GestureDetector(
        onTap: _startRoutePointCollector,
        child: ListTile(
          leading: Icon(
            Icons.location_on,
            color: getRandomColor(),
          ),
          title: Text('Collect Route Points', style: Styles.blackSmall),
        ),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: 'Display Route Map',
      child: GestureDetector(
        onTap: _startLocationCollectionMap,
        child: ListTile(
          leading: Icon(
            Icons.map,
            color: getRandomColor(),
          ),
          title: Text(
            'Points Collected',
            style: Styles.blackSmall,
          ),
        ),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: 'Activate Route',
      child: ListTile(
        leading: Icon(
          Icons.edit,
          color: getRandomColor(),
        ),
        title: Text('Activate Route', style: Styles.blackSmall),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: 'Remove Route',
      child: ListTile(
        leading: Icon(
          Icons.cancel,
          color: Colors.pink,
        ),
        title: Text('Remove Route', style: Styles.blackSmall),
      ),
    ));
  }

  _startRoutePointCollector() {
    print('_startRoutePointCollector');
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LocationCollector(route: widget.route)));
  }

  _startLocationCollectionMap() {
    print('_startRouteMap');
    Navigator.pop(context);
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LocationCollectionMap(route: widget.route)));
  }

  @override
  Widget build(BuildContext context) {
    _buildMenuItems();
    return Card(
      elevation: 4.0,
      color: getRandomPastelColor(),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: <Widget>[
            Row(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    PopupMenuButton<String>(
                      itemBuilder: (context) {
                        return menuItems;
                      },
                    ),
                  ],
                ),
              ],
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
