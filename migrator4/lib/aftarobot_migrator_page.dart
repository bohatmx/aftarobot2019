import 'dart:async';

import 'package:aftarobotlibrary3/api/file_util.dart';
import 'package:aftarobotlibrary3/api/list_api.dart';
import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/countrydto.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/data/spatialinfodto.dart';
import 'package:aftarobotlibrary3/data/userdto.dart';
import 'package:aftarobotlibrary3/data/vehicledto.dart';
import 'package:aftarobotlibrary3/data/vehicletypedto.dart';
import 'package:aftarobotlibrary3/util/city_map_search.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:migrator4/aftarobot_migration.dart';
import 'package:migrator4/generator.dart';
import 'package:migrator4/lists/assoc_list_page.dart';
import 'package:migrator4/lists/country_list_page.dart';
import 'package:migrator4/lists/route_list_page.dart';
import 'package:migrator4/lists/user_list_page.dart';
import 'package:migrator4/lists/vehicle_list_page.dart';
import 'package:migrator4/lists/vehicletype_list_page.dart';
import 'package:permission_handler/permission_handler.dart';

class AftaRobotMigratorPage extends StatefulWidget {
  @override
  _AftaRobotMigratorPageState createState() => _AftaRobotMigratorPageState();
}

class _AftaRobotMigratorPageState extends State<AftaRobotMigratorPage>
    with TickerProviderStateMixin
    implements
        AftaRobotMigrationListener,
        SnackBarListener,
        CounterCardListener {
  ScrollController scrollController = ScrollController();
  AnimationController animationController;
  Animation animation;
  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

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
    _initializeMessages();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _checkPermission();
    animation =
        new CurvedAnimation(parent: animationController, curve: Curves.linear);
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

  void _initializeMessages() {
    var msg = Msg(
      icon: Icon(
        Icons.apps,
        color: getRandomColor(),
      ),
      message: 'The action has yet to start',
      style: Styles.blackBoldMedium,
    );
    var msg2 = Msg(
      icon: Icon(
        Icons.apps,
        color: getRandomColor(),
      ),
      message: 'Pressing the Big Red Button might change things, eh?',
      style: Styles.greyLabelSmall,
    );

    setState(() {
      messages.add(msg);
      messages.add(msg2);
    });
  }

  void _checkMigratedStatus() async {
    await _getCachedData();
    if (landmarks.isEmpty) {
      firestoreIsReady = true;
    } else {
      firestoreIsReady = false;
      messages.clear();
      messages.add(Msg(
        icon: Icon(Icons.airplanemode_active),
        message:
            'This is new Firestore data. Yay! or rather, Yebo Gogo! AftaRobot is ready for action',
        style: Styles.purpleBoldSmall,
      ));
    }
    print('_AftaRobotMigratorPageState._checkMigratedStatus: ###########  '
        'landmarks from LocalDB: ${landmarks.length}');
  }

  Future _getCachedData() async {
    print(
        '\n\n\n_AftaRobotMigratorPageState._getCachedData ........... from LocalDB');
    var start = DateTime.now();
    try {
      countries = await LocalDB.getCountries();
      asses = await LocalDB.getAssociations();
      users = await LocalDB.getUsers();
      vehicles = await LocalDB.getVehicles();
      carTypes = await LocalDB.getVehicleTypes();
      landmarks = await LocalDB.getLandmarks();
      routes = await LocalDB.getRoutes();
      await _setCounters(animationIndex: CountriesIndex);
      await _setCounters(animationIndex: AssIndex);
      await _setCounters(animationIndex: UserIndex);
      await _setCounters(animationIndex: CarIndex);
      await _setCounters(animationIndex: CarTypeIndex);
      await _setCounters(animationIndex: LandmarkIndex);
      await _setCounters(animationIndex: RouteIndex);
      print(
          '_AftaRobotMigratorPageState._getCachedData; \ncountries: ${countries.length}\nassocs: ${asses.length}\n'
          'users: ${users.length} \ncars: ${vehicles.length} \ncarTypes: ${carTypes.length}\n'
          'landmarks: ${landmarks.length} \nroutes: ${routes.length}');
      var end = DateTime.now();
      print(
          '_AftaRobotMigratorPageState._getCachedData - elapsed ${end.difference(start).inMilliseconds} ms');
      _setCounters();
    } catch (e) {
      print(e);
    }
    //refresh from Firestore
    //_getFreshDataFromFirestore();
  }

  Future _getFreshDataFromFirestore() async {
    print(
        '\n\n_AftaRobotMigratorPageState._getFreshDataFromFirestore .............');
    AppSnackbar.showSnackbarWithProgressIndicator(
        scaffoldKey: _key,
        message: 'Loading from Firestore ...',
        textColor: Colors.yellow,
        backgroundColor: Colors.black);

    var start = DateTime.now();
    try {
      countries = await ListAPI.getCountries();
      if (countries.isNotEmpty) {
        await LocalDB.saveCountries(Countries(countries));
      }

      asses = await ListAPI.getAssociations();
      if (asses.isNotEmpty) {
        await LocalDB.saveAssociations(Associations(asses));
      }

      carTypes = await ListAPI.getVehicleTypes();
      if (carTypes.isNotEmpty) {
        await LocalDB.saveVehicleTypes(VehicleTypes(carTypes));
      }
      await _getMoreData();
      var end = DateTime.now();
      print(
          '_AftaRobotMigratorPageState._getFreshDataFromFirestore ass: ${asses.length} types: ${carTypes.length} countries: ${countries.length}');
      print(
          '_AftaRobotMigratorPageState._getFreshDataFromFirestore - ${end.difference(start).inMilliseconds} ms');
      _key.currentState.removeCurrentSnackBar();
    } catch (e) {
      print(e);
      AppSnackbar.showErrorSnackbar(
          scaffoldKey: _key,
          message: 'We have a data problem, sir!',
          listener: this,
          actionLabel: 'ok');
    }
  }

  Future _getMoreData() async {
    print(
        '\n\n_AftaRobotMigratorPageState.__getMoreData............................');
    _showBusySnack('Loading more Firestore data');
    var start = DateTime.now();
    landmarks = await ListAPI.getLandmarks();
    if (landmarks.isNotEmpty) {
      await LocalDB.saveLandmarks(Landmarks(landmarks));
    }

    routes = await ListAPI.getRoutes();
    if (routes.isNotEmpty) {
      await LocalDB.saveRoutes(Routes(routes));
    }

    users.clear();
    vehicles.clear();
    for (var ass in asses) {
      var cars = await ListAPI.getAssociationVehicles(ass.path);
      print(
          '_AftaRobotMigratorPageState._getMoreData cars: ${cars.length} from ${ass.associationName} : ${ass.path} - addAll to list');

      vehicles.addAll(cars);
      var mUsers = await ListAPI.getAssociationUsers(ass.path);
      print(
          '_AftaRobotMigratorPageState._getMoreData mUsers: ${mUsers.length} from ${ass.associationName} : ${ass.path} - addAll to list');
      users.addAll(mUsers);
    }

    if (vehicles.isNotEmpty) {
      await LocalDB.saveVehicles(Vehicles(vehicles));
    }
    if (users.isNotEmpty) {
      await LocalDB.saveUsers(Users(users));
    }

    _key.currentState.removeCurrentSnackBar();
    var end = DateTime.now();
    print(
        '_AftaRobotMigratorPageState._getMoreData - elapsed: ${end.difference(start).inMilliseconds} ms');
    print(
        '_AftaRobotMigratorPageState._getMoreData - landmarks: ${landmarks.length} '
        'routes: ${routes.length} cars: ${vehicles.length} users: ${users.length}: finished. setCounters now. Fool!');
    _setCounters();
    return null;
  }

  List<Counter> counters = List();

  Future _setCounters({int animationIndex}) async {
    counters.clear();

    var c1 = Counter(
        title: CountriesCounter,
        icon: Icon(Icons.language),
        total: countries.length,
        animationRequired:
            _getAnimationSwitch(animationIndex, CountriesCounter));
    counters.add(c1);

    var c2 = Counter(
        title: AssCounter,
        icon: Icon(Icons.apps),
        total: asses.length,
        animationRequired: _getAnimationSwitch(animationIndex, AssCounter));
    counters.add(c2);

    var c3 = Counter(
      title: UserCounter,
      icon: Icon(Icons.people),
      total: users.length,
      animationRequired: _getAnimationSwitch(animationIndex, UserCounter),
    );

    counters.add(c3);
    var c4 = Counter(
      title: CarCounter,
      icon: Icon(Icons.airport_shuttle),
      total: vehicles.length,
      animationRequired: _getAnimationSwitch(animationIndex, CarCounter),
    );

    counters.add(c4);

    var c5 = Counter(
        title: CarTypeCounter,
        icon: Icon(Icons.airport_shuttle),
        total: carTypes.length,
        animationRequired: _getAnimationSwitch(animationIndex, CarTypeCounter));
    counters.add(c5);

    var c6 = Counter(
      title: LandmarkCounter,
      icon: Icon(Icons.location_on),
      total: landmarks.length,
      animationRequired: _getAnimationSwitch(animationIndex, LandmarkCounter),
    );
    counters.add(c6);

    var c7 = Counter(
        title: RouteCounter,
        icon: Icon(Icons.my_location),
        total: routes.length,
        animationRequired: _getAnimationSwitch(animationIndex, RouteCounter));
    counters.add(c7);

    setState(() {});

    return null;
  }

  bool _getAnimationSwitch(int animationIndex, String title) {
    if (animationIndex == null) {
      return false;
    }
    switch (title) {
      case CountriesCounter:
        if (animationIndex == 0) {
          return true;
        } else {
          return null;
        }
        break;
      case AssCounter:
        if (animationIndex == 1) {
          return true;
        } else {
          return null;
        }
        break;
      case UserCounter:
        if (animationIndex == 2) {
          return true;
        } else {
          return null;
        }
        break;
      case CarCounter:
        if (animationIndex == 3) {
          return true;
        } else {
          return null;
        }
        break;
      case CarTypeCounter:
        if (animationIndex == 4) {
          return true;
        } else {
          return null;
        }
        break;
      case LandmarkCounter:
        if (animationIndex == 5) {
          return true;
        } else {
          return null;
        }
        break;
      case RouteCounter:
        if (animationIndex == 6) {
          return true;
        } else {
          return null;
        }
        break;
      default:
        return null;
    }
  }

  static const CountriesCounter = 'Countries',
      AssCounter = 'Associations',
      UserCounter = 'Users',
      CarCounter = 'Cars',
      CarTypeCounter = ' Types',
      LandmarkCounter = 'Landmarks',
      RouteCounter = 'Routes';
  static const CountriesIndex = 0,
      AssIndex = 1,
      UserIndex = 2,
      CarIndex = 3,
      CarTypeIndex = 4,
      LandmarkIndex = 5,
      RouteIndex = 6;
  void _showBusySnack(String message) {
    AppSnackbar.showSnackbarWithProgressIndicator(
        scaffoldKey: _key,
        message: message,
        textColor: Colors.white,
        backgroundColor: Colors.black);
  }

  void _migrateAftaRobot() async {
    print(
        '\n\n\n_RouteMigratorState._migrateAftaRobot -- @@@@@@@@@@@@@@@ START YOUR ENGINES! ...');
    setState(() {
      status = 'Migrating ... moving data bits :)';
    });

    _startTimer();
    AppSnackbar.showSnackbarWithProgressIndicator(
        scaffoldKey: _key,
        message: 'Starting the Marathon :):)',
        textColor: Colors.blue,
        backgroundColor: Colors.black);
    users.clear();
    countries.clear();
    asses.clear();
    carTypes.clear();
    landmarks.clear();
    routes.clear();
    vehicles.clear();
    _setCounters();

    start = DateTime.now();
    print('_RouteMigratorState._migrateAftaRobot +++++++++++++++++ OFF WE GO!');
    try {
      print('_RouteMigratorState._migrateAftaRobot ... start the real work!!');
//      await AftaRobotMigration.migrateCars(listener: this);
      await AftaRobotMigration.migrateOldAftaRobot(listener: this);
//      _migrateRoutes();
      _key.currentState.removeCurrentSnackBar();
      print(
          '\n\n\n_RouteMigratorState._migrateAftaRobot - migration done? #################b check Firestore');
      end = DateTime.now();
      print(
          '_AftaRobotMigratorPageState._migrateAftaRobot - ######## COMPLETE - elapsed ${end.difference(start).inMinutes}');
    } catch (e) {
      print(e);
      messages.add(Msg(
        icon: Icon(
          Icons.error,
          color: Colors.red.shade800,
        ),
        message: e.toString(),
        style: Styles.pinkBoldSmall,
      ));
      setState(() {
        status = 'Problem. Check logs below';
      });
    }
  }

  void _migrateRoutes() async {
    print(
        '_AftaRobotMigratorPageState._migrateRoutes ..... starting ..............');
    AppSnackbar.showSnackbarWithProgressIndicator(
        scaffoldKey: _key,
        message: 'Removing debris and cleaning up... will take a WHILE!',
        textColor: Colors.yellow,
        backgroundColor: Colors.black);
    var oldRoutes = await AftaRobotMigration.getOldRoutes();
    await LocalDB.deleteFile(LocalDB.RouteData);
    await LocalDB.deleteFile(LocalDB.LandmarkData);
    await AftaRobotMigration.deleteRoutesAndLandmarks();
    setState(() {
      landmarks.clear();
      routes.clear();
      start = DateTime.now();
    });
    _key.currentState.removeCurrentSnackBar();
    await AftaRobotMigration.migrateRoutes(routes: oldRoutes, mListener: this);
    print(
        '\n\n\n_RouteMigratorState._migrateAftaRobot - migration done? #################b check Firestore');
    end = DateTime.now();
    print(
        '_AftaRobotMigratorPageState._migrateAftaRobot - ######## COMPLETE - elapsed ${end.difference(start).inMinutes}');
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

  void _showForceMigrationDialog() {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text(
                "Confirm Forced  Migration",
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
                        'Do you want to DELETE everything and migrate ALL the data from the Firebase Realtime Database to the shiny, new Cloud Firestore?'
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
                  child: GestureDetector(
                    onTap: _showForceMigrationDialog,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Looks Migrated Already',
                        style: Styles.blackBoldLarge,
                      ),
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
    if (messages == null) {
      _initializeMessages();
    }
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(
          'AftaRobot Migrator',
          style: Styles.whiteBoldMedium,
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.build),
            onPressed: _migrateRoutes,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _getFreshDataFromFirestore,
          ),
        ],
        bottom: _getBottom(),
        backgroundColor: Colors.indigo.shade300,
      ),
      body: Stack(
        children: <Widget>[
          Opacity(
            opacity: 0.2,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/fincash.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomScrollView(
              slivers: <Widget>[
                SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      animationController.reset();
                      animationController.forward();
                      //check whether animation required
                      if (counters.elementAt(index).animationRequired == null) {
                        return CounterCard(
                          total: counters.elementAt(index).total,
                          title: counters.elementAt(index).title,
                          icon: counters.elementAt(index).icon,
                          cardListener: this,
                          index: index,
                        );
                      }
                      if (counters.elementAt(index).animationRequired) {
                        return CounterCard(
                          total: counters.elementAt(index).total,
                          title: counters.elementAt(index).title,
                          icon: counters.elementAt(index).icon,
                          cardListener: this,
                          index: index,
                          animation: animationController,
                        );
                      } else {
                        return CounterCard(
                          total: counters.elementAt(index).total,
                          title: counters.elementAt(index).title,
                          icon: counters.elementAt(index).icon,
                          index: index,
                          cardListener: this,
                        );
                      }
                    },
                    childCount: counters.length,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      crossAxisCount: 3),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                    if (messages == null || messages.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          elevation: 6.0,
                          color: getRandomPastelColor(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  'Migration has not started yet',
                                  style: Styles.blackMedium,
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    if (index >= messages.length) {
                      return null;
                    }
                    return ListTile(
                      leading: messages.elementAt(index).icon,
                      title: Text(
                        messages.elementAt(index).message,
                        style: messages.elementAt(index).style,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
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
        style: Styles.blackSmall,
        message: 'Landmark - ${landmark.landmarkName}');
    messages.add(msg);
    animationIndex = LandmarkIndex;
    _setCounters(animationIndex: LandmarkIndex);
  }

  @override
  onLandmarksAdded(List<LandmarkDTO> marks) {
    landmarks.addAll(marks);
    landmarkCount = landmarks.length;

    marks.forEach((mark) {
      var msg = Msg(
          icon: Icon(Icons.location_on, color: getRandomColor()),
          style: Styles.blackSmall,
          message: 'Landmark - ${mark.landmarkName}');
      messages.add(msg);
      animationIndex = LandmarkIndex;
    });

    _setCounters(animationIndex: LandmarkIndex);
  }

  @override
  onRouteAdded(RouteDTO route) {
    print('\n\n_RouteMigratorState.onRouteAdded -- *********** ${route.name}');
    routes.add(route);
    routeCount = routes.length;
    var msg = Msg(
        icon: Icon(Icons.airport_shuttle, color: getRandomColor()),
        style: Styles.blueBoldSmall,
        message: 'Route - ${route.name}');

    messages.add(msg);
    animationIndex = RouteIndex;
    _setCounters(animationIndex: RouteIndex);
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

    _getFreshDataFromFirestore();
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
        style: Styles.brownBoldSmall,
        message: 'Association - ${ass.associationName}');
    messages.add(msg);
    animationIndex = AssIndex;
    _setCounters(animationIndex: AssIndex);
  }

  @override
  onAssociationsAdded(List<AssociationDTO> associations) {
    asses.addAll(associations);
    assCount = asses.length;
    var msg = Msg(
        icon: Icon(
          Icons.apps,
          color: getRandomColor(),
        ),
        style: Styles.brownBoldSmall,
        message: '${associations.length} Associations added');
    messages.add(msg);
    animationIndex = AssIndex;
    _setCounters(animationIndex: AssIndex);
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
        style: Styles.blackSmall,
        message:
            'Vehicle: - ${car.vehicleReg} - ${car.vehicleType.make} ${car.vehicleType.model}');
    messages.add(msg);
    animationIndex = CarIndex;
    _setCounters(animationIndex: CarIndex);
  }

  @override
  onUsersAdded(List<UserDTO> users) {
    print('\n\n_AftaRobotMigratorPageState.onUsersAdded .....');
    this.users.addAll(users);
    userCount = users.length;
    var msg = Msg(
        icon: Icon(
          Icons.person,
          color: getRandomColor(),
        ),
        style: Styles.blackSmall,
        message: ' ${users.length} Users added');
    messages.add(msg);
    animationIndex = UserIndex;

    _setCounters(animationIndex: UserIndex);
  }

  @override
  onVehiclesAdded(List<VehicleDTO> cars) {
    vehicles.addAll(cars);
    carCount = vehicles.length;
    var msg = Msg(
        icon: Icon(
          Icons.airport_shuttle,
          color: getRandomColor(),
        ),
        style: Styles.blackSmall,
        message: '${cars.length} - cars added');

    messages.add(msg);
    animationIndex = CarIndex;
    _setCounters(animationIndex: CarIndex);
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
        style: Styles.blackSmall,
        message: 'Users - ${user.name} ${user.email}');
    messages.add(msg);
    animationIndex = UserIndex;

    _setCounters(animationIndex: UserIndex);
  }

  int animationIndex;
  @override
  onCountriesAdded(List<CountryDTO> countries) {
    print('_AftaRobotMigratorPageState.onCountriesAdded: ${countries.length}');
    this.countries = countries;
    countryCount = countries.length;
    countries.forEach((c) {
      var msg = Msg(
          icon: Icon(
            Icons.group_work,
            color: getRandomColor(),
          ),
          style: Styles.purpleBoldSmall,
          message: 'Country: - ${c.name} ');
      messages.add(msg);
    });
    animationIndex = CountriesIndex;
    _setCounters(animationIndex: CountriesIndex);
  }

  @override
  onVehicleTypeAdded(VehicleTypeDTO carType) {
    print(
        '_AftaRobotMigratorPageState.onVehicleTypeAdded:  - ${carType.make} ${carType.model} ');
    carTypes.add(carType);
    vehicleTypeCnt = carTypes.length;
    var msg = Msg(
        icon: Icon(
          Icons.airport_shuttle,
          color: getRandomColor(),
        ),
        style: Styles.blueBoldSmall,
        message: 'Car Type - ${carType.make} ${carType.model}');
    messages.add(msg);
    animationIndex = CarTypeIndex;
    _setCounters(animationIndex: CarTypeIndex);
  }

  @override
  onDuplicateRecord(String message) {
    setState(() {
      var msg = Msg(
          icon: Icon(
            Icons.cancel,
            color: Colors.deepOrange,
          ),
          style: Styles.pinkBoldSmall,
          message: message);
      messages.add(msg);
    });
  }

  @override
  onGenericMessage(String message) {
    setState(() {
      var msg = Msg(
          icon: Icon(
            Icons.message,
            color: getRandomColor(),
          ),
          style: Styles.blackBoldSmall,
          message: message);
      messages.add(msg);
    });
  }

  void _refresh() {
    countries.clear();
    asses.clear();
    users.clear();
    vehicles.clear();
    carTypes.clear();
    landmarks.clear();
    routes.clear();
    _setCounters();

    _getFreshDataFromFirestore();
  }

  @override
  onActionPressed(int action) {
    // TODO: implement onActionPressed
    return null;
  }

  @override
  onCounterCardTapped(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => CountryListPage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => AssociationListPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => UserListPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => VehicleListPage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => VehicleTypeListPage()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => RouteListPage()),
        );
        break;
      case 6:
        Navigator.push(
          context,
          new MaterialPageRoute(builder: (context) => RouteListPage()),
        );
        break;
    }
  }
}

abstract class CounterCardListener {
  onCounterCardTapped(int index);
}

class CounterCard extends StatelessWidget {
  final int total, index;
  final String title;
  final TextStyle totalStyle, titleStyle;
  final Color cardColor;
  final Icon icon;
  final CounterCardListener cardListener;
  final AnimationController animation;

  CounterCard(
      {@required this.total,
      @required this.title,
      this.totalStyle,
      this.titleStyle,
      this.cardListener,
      this.cardColor,
      this.animation,
      this.index,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (cardListener != null && index != null) {
          cardListener.onCounterCardTapped(index);
        }
      },
      child: SizedBox(
        height: 140,
        width: 80,
        child: Card(
          elevation: 4.0,
          color: cardColor == null ? getRandomPastelColor() : cardColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                animation == null
                    ? Text(
                        '$total',
                        style: totalStyle == null
                            ? Styles.blackBoldLarge
                            : totalStyle,
                      )
                    : ScaleTransition(
                        scale: animation,
                        child: Text(
                          '$total',
                          style: totalStyle == null
                              ? Styles.blackBoldLarge
                              : totalStyle,
                        ),
                      ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  title,
                  style:
                      titleStyle == null ? Styles.greyLabelSmall : titleStyle,
                ),
                icon == null ? Icon(Icons.print) : icon,
              ],
            ),
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
  final String title;
  final int total;
  final Icon icon;
  final bool animationRequired;

  Counter({this.title, this.total, this.icon, this.animationRequired});
}
