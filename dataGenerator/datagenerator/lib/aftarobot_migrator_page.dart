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
import 'package:datagenerator/generator.dart';
import 'package:flutter/material.dart';

class AftaRobotMigratorPage extends StatefulWidget {
  @override
  _AftaRobotMigratorPageState createState() => _AftaRobotMigratorPageState();
}

class _AftaRobotMigratorPageState extends State<AftaRobotMigratorPage>
    implements RouteMigrationListener, AftaRobotMigrationListener {
  ScrollController scrollController = ScrollController();
  String status = 'The Great AftaRobot Data Migration';
  int routeCount = 0,
      landmarkCount = 0,
      assCount = 0,
      userCount = 0,
      carCount = 0,
      vehicleTypeCnt = 0,
      countryCount = 0;
  DateTime start, end;
  bool isMigrationDone = false, firestoreIsReady = false;
  List<Msg> messages = List();
  List<AssociationDTO> asses = List();
  List<VehicleDTO> vehicles = List();
  List<LandmarkDTO> landmarks = List();
  List<RouteDTO> routes = List();
  List<VehicleTypeDTO> carTypes = List();
  List<UserDTO> users = List();
  List<CountryDTO> countries = List();
  @override
  void initState() {
    super.initState();
    _checkMigratedStatus();
    _setCounters();
  }

  void _checkMigratedStatus() async {
    asses = await ListAPI.getAssociations();
    carTypes = await ListAPI.getVehicleTypes();
    countries = await ListAPI.getCountries();
    print('_AftaRobotMigratorPageState._checkMigratedStatus: ###########  '
        'associations: ${asses.length} countries: ${countries.length} '
        'vehicleTypes: ${carTypes.length}');

    if (countries.isEmpty && carTypes.isEmpty && asses.isEmpty) {
      firestoreIsReady = true;
    } else {
      firestoreIsReady = false;
      _getData();
    }
    setState(() {});
  }

  void _getData() async {
    landmarks = await ListAPI.getLandmarks();
    routes = await ListAPI.getRoutes();

    for (var ass in asses) {
      var cars = await ListAPI.getAssociationVehicles(ass.path);
      vehicles.addAll(cars);
      var musers = await ListAPI.getAssociationUsers(ass.path);
      users.addAll(musers);
    }
    setState(() {});
  }

  List<Counter> counters = List();

  void _setCounters() {
    counters.clear();
    var c1 = Counter(
      title: 'Countries',
      total: countryCount,
    );
    counters.add(c1);
    var c2 = Counter(
      title: 'Associations',
      total: assCount,
    );
    counters.add(c2);
    var c3 = Counter(
      title: 'Users',
      total: userCount,
    );
    counters.add(c3);
    var c4 = Counter(
      title: 'Cars',
      total: carCount,
    );
    counters.add(c4);
    var c5 = Counter(
      title: 'Car Types',
      total: vehicleTypeCnt,
    );
    counters.add(c5);
    var c6 = Counter(
      title: 'Landmarks',
      total: landmarkCount,
    );
    counters.add(c6);
    var c7 = Counter(
      title: 'Routes',
      total: routeCount,
    );
    counters.add(c7);
    setState(() {});
  }

  void _migrateAftaRobot() async {
    print(
        '\n\n\n_RouteMigratorState._migrateAftaRobot -- @@@@@@@@@@@@@@@ START YOUR ENGINES! ...');
    setState(() {
      status = 'Migrating _migrateAftaRobot ...';
    });

    _startTimer();
    start = DateTime.now();
    print('_RouteMigratorState._migrateAftaRobot +++++++++++++++++ OFF WE GO!');
    try {
      print('_RouteMigratorState._migrateAftaRobot ... start the real work!!');
      await AftaRobotMigration.migrateOldAftaRobot(
          listener: this, routeMigrationListener: this);
      print(
          '\n\n\n_RouteMigratorState._migrateAftaRobot - migration done? #################b check Firestore');
      end = DateTime.now();
      print(
          '_AftaRobotMigratorPageState._migrateAftaRobot - ######## COMPLETE - elapsed ${end.difference(start).inMinutes}');
    } catch (e) {
      print(e);
      setState(() {
        status = e.toString();
      });
    }
  }

  Timer timer;
  String timerText;
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

  void _showDialog() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text(
                "Confirm  Migration",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
              ),
              content: Container(
                height: 200.0,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Do you want to migrate ALL the data from the Firebase Realtime Database to the shiny, new Cloud Firestore?'
                            '\n\nThis will take quite a few minutes so I suggest you go get a smoke and a coffee :):)',
                        style: Styles.blackBoldSmall,
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text(
                    'NO',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: RaisedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _migrateAftaRobot();
                    },
                    elevation: 4.0,
                    color: Colors.teal.shade500,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Start BigTime Migration',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ));
  }

  Widget _getList() {
    return ListView.builder(
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: messages.elementAt(index).icon,
            title: Text(
              messages.elementAt(index).message,
              style: Styles.blackSmall,
            ),
          );
        });
  }

  Widget _getGrid() {
    _setCounters();
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
          itemCount: 7,
          gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemBuilder: (BuildContext context, int index) {
            return CounterCard(
                total: counters.elementAt(index).total,
                title: counters.elementAt(index).title);
          }),
    );
  }

  Widget _getBottom() {
    return PreferredSize(
      preferredSize: Size.fromHeight(120),
      child: Column(
        children: <Widget>[
          firestoreIsReady == true
              ? RaisedButton(
                  elevation: 16,
                  color: Colors.pink,
                  onPressed: _showDialog,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Start Your Bloody Engines!',
                      style: Styles.whiteSmall,
                    ),
                  ),
                )
              : Container(
                  color: Colors.brown.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Looks Migrated Already',
                      style: Styles.blackBoldLarge,
                    ),
                  ),
                ),
          SizedBox(
            height: 8,
          ),
          Text(
            status,
            style: Styles.whiteSmall,
          ),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AftaRobot Migrator',
          style: Styles.whiteBoldMedium,
        ),
        bottom: _getBottom(),
        backgroundColor: Colors.indigo.shade300,
      ),
      body: Stack(
        children: <Widget>[
          _getList(),
          _getGrid(),
        ],
      ),
    );
  }

  @override
  onLandmarkAdded(LandmarkDTO landmark) {
    print(
        '_RouteMigratorState.onLandmarkAdded -- %%%%%%%%%%%% ${landmark.landmarkName}');
    landmarks.add(landmark);
    landmarkCount = landmarks.length;
    var msg = Msg(
        icon: Icon(Icons.location_on, color: getRandomColor()),
        message: 'Landmark - ${landmark.landmarkName}');
    messages.add(msg);
    _setCounters();
  }

  @override
  onRouteAdded(RouteDTO route) {
    print('\n\n_RouteMigratorState.onRouteAdded -- *********** ${route.name}');
    routes.add(route);
    routeCount = routes.length;
    var msg = Msg(
        icon: Icon(Icons.airport_shuttle, color: getRandomColor()),
        message: 'Route - ${route.name}');
    messages.add(msg);
    _setCounters();
  }

  @override
  onComplete() {
    print(
        '\n\n_RouteMigratorState.onComplete -- ########################### FINISHED. DONE. CHECK!!!');

    if (timer != null) {
      if (timer.isActive) {
        timer.cancel();
      }
    }

    setState(() {
      isMigrationDone = true;
      firestoreIsReady = false;
    });
  }

  @override
  onAssociationAdded(AssociationDTO ass) {
    print(
        '_RouteMigratorState.onAssociationAdded ---- ### ${ass.associationName}');
    asses.add(ass);
    assCount = asses.length;
    var msg = Msg(
        icon: Icon(
          Icons.apps,
          color: getRandomColor(),
        ),
        message: 'Association - ${ass.associationName}');
    messages.add(msg);
    _setCounters();
  }

  @override
  onVehicleAdded(VehicleDTO car) {
    print(
        '_RouteMigratorState.onVehicleAdded -- ${car.vehicleReg} ${car.path}');
    vehicles.add(car);
    carCount = vehicles.length;
    var msg = Msg(
        icon: Icon(
          Icons.airport_shuttle,
          color: getRandomColor(),
        ),
        message:
            'Vehicle: - ${car.vehicleReg} - ${car.vehicleType.make} ${car.vehicleType.model}');
    messages.add(msg);
    _setCounters();
  }

  @override
  onUserAdded(UserDTO user) {
    print('_RouteMigratorState.onUserAdded ====> ${user.name}');
    users.add(user);
    userCount = users.length;
    var msg = Msg(
        icon: Icon(
          Icons.person,
          color: getRandomColor(),
        ),
        message: 'Users - ${user.name} ${user.email}');
    messages.add(msg);
    _setCounters();
  }
}

class CounterCard extends StatelessWidget {
  final int total;
  final String title;
  final TextStyle totalStyle, titleStyle;
  final Color cardColor;
  final Icon icon;

  CounterCard(
      {@required this.total,
      @required this.title,
      this.totalStyle,
      this.titleStyle,
      this.cardColor,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 80,
      child: Card(
        elevation: 1.0,
        color: cardColor == null ? getRandomPastelColor() : cardColor,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                '$total',
                style: totalStyle == null ? Styles.blackBoldLarge : totalStyle,
              ),
              SizedBox(
                height: 4,
              ),
              Text(
                title,
                style: titleStyle == null ? Styles.greyLabelSmall : titleStyle,
              ),
            ],
          ),
        ),
      ),
    );
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

class Counter {
  String title;
  int total;

  Counter({this.title, this.total});
}
