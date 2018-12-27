import 'dart:async';

import 'package:aftarobotlibrary/api/list_api.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/spatialinfodto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:aftarobotlibrary/util/city_map_search.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:datagenerator/aftarobot_migration.dart';
import 'package:flutter/material.dart';

class RouteViewerPage extends StatefulWidget {
  @override
  _RouteViewerPageState createState() => _RouteViewerPageState();
}

class _RouteViewerPageState extends State<RouteViewerPage>
    implements AftaRobotMigrationListener {
  List<RouteDTO> routes;
  List<LandmarkDTO> landmarks;
  ScrollController scrollController = ScrollController();
  String status = 'OLD AftaRobot Routes';
  int routeCount = 0, landmarkCount = 0;
  List<AssociationDTO> asses = List();
  @override
  void initState() {
    super.initState();
    _getOldRoutes();
  }

  void _getOldRoutes() async {
    var tempRoutes = await AftaRobotMigration.getOldRoutes();
    List<RouteDTO> filteredRoutes = List();
    tempRoutes.forEach((r) {
      if (r.spatialInfos.length > 0) {
        filteredRoutes.add(r);
      }
    });
    routes = filteredRoutes;
    print(
        '_RouteMigratorState._getOldRoutes - filtered routes. ${routes.length} routes are valid');
    _setCounters();

    setState(() {
      status = 'OLD AftaRobot Routes';
    });
  }

  void _setCounters() {
    routeCount = routes.length;
    routes.forEach((r) {
      r.spatialInfos.forEach((si) {
        landmarkCount++;
      });
    });
  }

  void _getNewRoutes() async {
    routes = await ListAPI.getRoutes();
    _setCounters();
    setState(() {
      status = 'NEW AftaRobot Routes';
    });
  }

  void _migrateAss() async {
    print(
        '\n\n\n_RouteMigratorState._migrateRoutes -- @@@@@@@@@@@@@@@ START YOUR ENGINES! ...');
    setState(() {
      status = 'Migrating Routes ...';
    });

    _startTimer();

    RouteDTO mRoute;
    routes.forEach((r) {
      if (r.spatialInfos.isNotEmpty) {
        mRoute = r;
      }
    });
    print('_RouteMigratorState._migrateRoutes +++++++++++++++++ OFF WE GO!');
    try {
      List<RouteDTO> clonedRoutes = List();
      List<RouteDTO> tempRoutes = List.from(routes);
      tempRoutes.forEach((r) {
        if (r.spatialInfos.length > 0) {
          clonedRoutes.add(r);
        }
      });
      print(
          '_RouteMigratorState._migrateRoutes - sending ${clonedRoutes.length} routes with defined spatialInfos');
      await AftaRobotMigration.primeQueriesToGetIndexingLink(
          route: mRoute,
          landmark: mRoute.spatialInfos.elementAt(0).fromLandmark);
      print('_RouteMigratorState._migrateRoutes ... start the real work!!');

      print(
          '\n\n_RouteMigratorState._migrateRoutes - migration done? #################b check Firestore');
    } catch (e) {
      print(e);
    }
  }

  Timer timer;
  String timerText;
  DateTime start, end;
  void _startTimer() {
    if (timer != null) {
      if (timer.isActive) {
        timer.cancel();
      }
    }
    start = DateTime.now();
    timer = Timer.periodic(Duration(seconds: 15), (mTimer) {
      //double shit here
      end = DateTime.now();
      int diffSeconds = end.difference(start).inSeconds;
      int diffMinutes = end.difference(start).inMinutes;
      if (diffSeconds < 60) {
        setState(() {
          timerText = '$diffSeconds seconds';
        });
      } else {
        setState(() {
          if (diffMinutes == 1) {
            timerText = '$diffMinutes minute';
          } else {
            timerText = '$diffMinutes minutes';
          }
        });
      }
    });
  }

  Widget _getListView() {
    return ListView.builder(
        itemCount: routes == null ? 0 : routes.length,
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16),
            child: RouteCard(
              route: routes.elementAt(index),
              number: index + 1,
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('RouteMigrator'),
        backgroundColor: Colors.indigo.shade300,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(140),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    RaisedButton(
                      elevation: 8,
                      color: Colors.pink,
                      onPressed: _migrateAss,
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Start Migration',
                          style: Styles.whiteSmall,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          '$routeCount',
                          style: Styles.blackBoldLarge,
                        ),
                        Text(
                          'Routes',
                          style: Styles.blackSmall,
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 40,
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          '$landmarkCount',
                          style: Styles.blackBoldLarge,
                        ),
                        Text(
                          'Landmarks',
                          style: Styles.blackSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 28,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      status,
                      style: Styles.whiteSmall,
                    ),
                    SizedBox(
                      width: 40,
                    ),
                    Row(
                      children: <Widget>[
                        Text(
                          'Elapsed:',
                          style: Styles.whiteSmall,
                        ),
                        SizedBox(
                          width: 6,
                        ),
                        Text(
                          timerText == null ? '0' : timerText,
                          style: Styles.blackBoldSmall,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _getListView(),
      backgroundColor: Colors.indigo.shade100,
    );
  }

  List<LandmarkDTO> newLandmarks = List();
  @override
  onLandmarkAdded(LandmarkDTO landmark) {
    print(
        '_RouteMigratorState.onLandmarkAdded -- %%%%%%%%%%%% ${landmark.landmarkName}');
    newLandmarks.add(landmark);
    setState(() {
      landmarkCount--;
    });
  }

  List<RouteDTO> newRoutes = List();
  @override
  onRouteAdded(RouteDTO route) {
    print('\n\n_RouteMigratorState.onRouteAdded -- *********** ${route.name}');
    newRoutes.add(route);
    List<RouteDTO> mList = List();
    routes.forEach((r) {
      if (r.routeID != route.routeID) {
        mList.add(r);
      }
    });
    routes = mList;
    setState(() {
      routeCount = routes.length;
    });
  }

  @override
  onComplete() {
    newRoutes.forEach((r) {
      landmarkCount += r.spatialInfos.length;
    });
    if (timer != null) {
      if (timer.isActive) {
        timer.cancel();
      }
    }
    setState(() {
      routes = newRoutes;
      routeCount = routes.length;
    });
  }

  @override
  onAssociationAdded(AssociationDTO ass) {
    print(
        '_RouteMigratorState.onAssociationAdded ---- ### ${ass.associationName}');
    asses.add(ass);
    return null;
  }

  List<VehicleDTO> cars = List();
  @override
  onVehicleAdded(VehicleDTO car) {
    print(
        '_RouteMigratorState.onVehicleAdded -- ${car.vehicleReg} ${car.path}');
    cars.add(car);
  }

  @override
  onUserAdded(UserDTO user) {
    print('_RouteMigratorState.onUserAdded ====> ${user.name}');
    return null;
  }

  @override
  onCountriesAdded(List<CountryDTO> countries) {
    // TODO: implement onCountriesAdded
    return null;
  }

  @override
  onVehicleTypeAdded(VehicleTypeDTO car) {
    // TODO: implement onVehicleTypeAdded
    return null;
  }

  @override
  onDuplicateRecord(String message) {
    // TODO: implement onDuplicateRecord
    return null;
  }

  @override
  onGenericMessage(String message) {
    // TODO: implement onGenericMessage
    return null;
  }

  @override
  onLandmarksAdded(List<LandmarkDTO> landmarks) {
    // TODO: implement onLandmarksAdded
    return null;
  }

  @override
  onUsersAdded(List<UserDTO> users) {
    // TODO: implement onUsersAdded
    return null;
  }

  @override
  onVehiclesAdded(List<VehicleDTO> cars) {
    // TODO: implement onVehiclesAdded
    return null;
  }

  @override
  onAssociationsAdded(List<AssociationDTO> associations) {
    // TODO: implement onAssociationsAdded
    return null;
  }
}

class RouteCard extends StatefulWidget {
  final RouteDTO route;
  final Color color;
  final int number;

  RouteCard({this.route, this.color, this.number});

  @override
  _RouteCardState createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  int index = 0;
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    List<ExpansionPanel> panels = List();
    int mIndex = 0;
    widget.route.spatialInfos.sort((a, b) => a.fromLandmark.rankSequenceNumber
        .compareTo(b.fromLandmark.rankSequenceNumber));
    if (widget.route.spatialInfos.isNotEmpty) {
      widget.route.spatialInfos.forEach((si) {
        bool iAmExpanding = false;
        if (index == mIndex) {
          iAmExpanding = isExpanded;
        }
        var panel = ExpansionPanel(
            isExpanded: iAmExpanding,
            body: SpatialInfoPair(
              spatialInfo: si,
              route: widget.route,
            ),
            headerBuilder: (BuildContext context, bool isExpanded) {
              return Padding(
                padding: const EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8),
                child: Text(
                  si.fromLandmark.landmarkName,
                  style: Styles.blackBoldSmall,
                ),
              );
            });

        panels.add(panel);
        mIndex++;
      });
    }

    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 28,
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
            Row(
              children: <Widget>[
                SizedBox(
                  width: 28,
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
            widget.route.spatialInfos.isEmpty
                ? Container()
                : ExpansionPanelList(
                    children: panels,
                    animationDuration: Duration(milliseconds: 500),
                    expansionCallback: (int index, bool isExpanded) {
                      print(
                          'RouteCard.build - expansionCallback: index: $index isExpanded: $isExpanded - ${DateTime.now().toUtc().toIso8601String()}');
                      setState(() {
                        this.index = index;
                        this.isExpanded = !isExpanded;
                      });
                    },
                  ),
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
            _goToMapSearch(
                context: context, landmark: spatialInfo.fromLandmark);
          },
          child: ListTile(
            title: Text(
              '${spatialInfo.fromLandmark.landmarkName} (seq: ${spatialInfo.fromLandmark.rankSequenceNumber})',
              style: Styles.blackSmall,
            ),
            subtitle: Text(
              '${spatialInfo.fromLandmark.latitude}  ${spatialInfo.fromLandmark.longitude}',
              style: Styles.greyLabelSmall,
            ),
            leading: Icon(
              Icons.airport_shuttle,
              color: Colors.teal.shade600,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _goToMapSearch(context: context, landmark: spatialInfo.toLandmark);
          },
          child: ListTile(
            title: Text(
              '${spatialInfo.toLandmark.landmarkName} (seq: ${spatialInfo.toLandmark.rankSequenceNumber})',
              style: Styles.blackSmall,
            ),
            subtitle: Text(
              '${spatialInfo.toLandmark.latitude}  ${spatialInfo.toLandmark.longitude}',
              style: Styles.greyLabelSmall,
            ),
            leading: Icon(
              Icons.airport_shuttle,
              color: Colors.pink.shade600,
            ),
          ),
        ),
      ],
    );
  }

  void _goToMapSearch({BuildContext context, LandmarkDTO landmark}) {
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
