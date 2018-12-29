import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/api/list_api.dart';
import 'package:aftarobotlibrary/data/association_bag.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:aftarobotlibrary/directions/direct_util.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:flutter/services.dart';
import 'package:migrator2/aftarobot_migrator_page.dart';
import 'package:migrator2/beacon_scanner.dart';
import 'package:migrator2/city_migrate.dart';
import 'package:migrator2/generator.dart';
import 'package:migrator2/location_test_page.dart';
import 'package:migrator2/main.dart';
import 'package:migrator2/route_viewer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with TickerProviderStateMixin
    implements GeneratorListener, SnackBarListener, AssociationBagListener {
  List<Msg> _messages = List();
  List<AssociationBag> bags = List(), activeBags = List();
  ScrollController scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();
  AnimationController animationController;
  Animation animation;
  List<VehicleTypeDTO> carTypes = List();
  List<UserDTO> users = List();
  List<AssociationDTO> asses = List();
  List<VehicleDTO> cars = List();
  static const platform = const MethodChannel('samples.flutter.io/battery');
  String _batteryLevel = '0';

  Future<String> _getBatteryLevel() async {
    String batteryLevel;
    try {
      final int result = await platform.invokeMethod('getBatteryLevel');
      batteryLevel = 'Battery: $result % .';
    } on PlatformException catch (e) {
      batteryLevel = "Failed: '${e.message}'.";
    }

    setState(() {
      _batteryLevel = batteryLevel;
    });
    return batteryLevel;
  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    animation =
        new CurvedAnimation(parent: animationController, curve: Curves.linear);

    _getCachedData();
    test();
  }

  void test() async {
    await DirectionsUtil.getDirections();
    _batteryLevel = await _getBatteryLevel();
  }

  Future _getCachedData() async {
    var start = DateTime.now();
    try {
      var countries = await LocalDB.getCountries();
      asses = await LocalDB.getAssociations();
      users = await LocalDB.getUsers();
      cars = await LocalDB.getVehicles();
      carTypes = await LocalDB.getVehicleTypes();
      var landmarks = await LocalDB.getLandmarks();
      var routes = await LocalDB.getRoutes();

      print(
          '_DashboardState._getCachedData; \ncountries: ${countries.length}\nassocs: ${asses.length}\n'
          'users: ${users.length} \ncars: ${cars.length} \ncarTypes: ${carTypes.length}\n'
          'landmarks: ${landmarks.length} \nroutes: ${routes.length}');
      var end = DateTime.now();
      print(
          '_DashboardState._getCachedData - elapsed ${end.difference(start).inMilliseconds} ms');
      var total = countries.length +
          asses.length +
          users.length +
          cars.length +
          carTypes.length +
          landmarks.length +
          routes.length;
      if (total == 0) {
        print(
            '_DashboardState._getCachedData ########## EMPTY LOCAL CACHE - start the MIGRATOR!!!');
        _startAftaMigrator();
      } else {
        _start();
      }
    } catch (e) {
      print(e);
    }
  }

  void _start() async {
    print('_DashboardState._start .................... get Bags!');
    if (asses.isNotEmpty && users.isNotEmpty && cars.isNotEmpty) {
      activeBags = await getAssociationBags();
    } else {
      activeBags = await ListAPI.getAssociationBags(this);
    }
    setState(() {});
  }

  Future<List<AssociationBag>> getAssociationBags() async {
    for (var ass in asses) {
      AssociationBag bag = AssociationBag();
      bag.association = ass;

      List<UserDTO> admins = List();
      users.forEach((u) {
        if (u.associationID == ass.associationID) {
          admins.add(u);
        }
      });
      bag.users = admins;

      List<VehicleDTO> mcars = List();
      cars.forEach((c) {
        if (c.associationID == ass.associationID) {
          mcars.add(c);
        }
      });
      bag.cars = mcars;
      bag.carTypes = _filter(ass, mcars);
      print(
          '_DashboardState.getAssociationBags bag.cars: ${bag.cars.length} types: ${bag.carTypes.length} users: ${bag.users.length}');
      setState(() {
        activeBags.add(bag);
        counter++;
      });
    }

    return activeBags;
  }

  List<VehicleTypeDTO> _filter(AssociationDTO ass, List<VehicleDTO> cars) {
    List<VehicleTypeDTO> list = List();
    cars.forEach((car) {
      if (!_isVehicleTypeFound(list, car.vehicleType)) {
        list.add(car.vehicleType);
      }
    });

    return list;
  }

  static bool _isVehicleTypeFound(
      List<VehicleTypeDTO> list, VehicleTypeDTO type) {
    var isFound = false;
    list.forEach((t) {
      if (type == null || t == null) {
        //do nothing
      } else {
        if (type.vehicleTypeID == t.vehicleTypeID) {
          isFound = true;
        }
      }
    });
    return isFound;
  }

  void _refresh() {
    _start();
    setState(() {
      activeBags.clear();
      errorText = null;
      counter = 0;
    });
  }

  void _startLocationTestPage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => LocationTestPage()),
    );
  }

  void _startGenerationPage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => GenerationPage()),
    );
  }

  void _startRouteViewerPage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => RouteViewerPage()),
    );
  }

  void _startBeaconScanner() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => BeaconScanner()),
    );
  }

  void _startCityMigrator() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => CityMigrator()),
    );
  }

  void _startAftaMigrator() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => AftaRobotMigratorPage()),
    );
  }

  String errorText;

  Widget _getBottom() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
                top: 10.0, bottom: 20.0, left: 10.0, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  color: Colors.indigo,
                  elevation: 8.0,
                  onPressed: _refresh,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Get Fresh Data',
                      style: Styles.whiteSmall,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '$counter',
                        style: Styles.blackBoldLarge,
                      ),
                      Text(
                        'Associations',
                        style: Styles.blackBoldSmall,
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            _batteryLevel == null ? 'Battery' : _batteryLevel,
            style: Styles.blackSmall,
          ),
        ],
      ),
    );
  }

  _doSomething() {
    print('_DGHomePageState._doSomething ${DateTime.now().toIso8601String()}');
  }

  @override
  Widget build(BuildContext context) {
    animationController.reset();
    animationController.forward();

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('AftaRobot Data'),
        leading: IconButton(icon: Icon(Icons.apps), onPressed: _doSomething),
        bottom: _getBottom(),
        backgroundColor: Colors.purple.shade300,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _start,
          ),
        ],
      ),
      backgroundColor: Colors.purple.shade100,
      body: Stack(
        children: <Widget>[
          Opacity(
            opacity: 0.3,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/fincash.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          BagList(
            activeBags: activeBags,
            scrollController: scrollController,
            animationController: animationController,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.loyalty),
            title: Text(
              'Cities',
              style: Styles.blackSmall,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            title: Text(
              'Beacons',
              style: Styles.blackSmall,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.my_location),
            title: Text(
              'Routes',
              style: Styles.blackSmall,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            title: Text(
              'Build',
              style: Styles.blackSmall,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions),
            title: Text(
              'Migrate',
              style: Styles.blackSmall,
            ),
          ),
        ],
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          switch (index) {
            case 0:
              print(
                  '_ExistingDataPageState.build -- #1 _startCityMigrator() index: $index');
              _startCityMigrator();
              break;
            case 1:
              print(
                  '_ExistingDataPageState.build -- #2 _startBeaconScanner() index: $index');
              _startBeaconScanner();
              break;
            case 2:
              print(
                  '_ExistingDataPageState.build -- #3 _startRouteViewerPage() index: $index');
              _startRouteViewerPage();
              break;
            case 3:
              print(
                  '_ExistingDataPageState.build -- #4 _startGenerationPage() index: $index');
              _startGenerationPage();
              break;
            case 4:
              print(
                  '_ExistingDataPageState.build -- #5 _startAftaMigrator() index: $index');
              _startAftaMigrator();
              break;
          }
        },
      ),
    );
  }

  @override
  onEvent(Msg msg) {
    setState(() {
      _messages.add(msg);
    });
  }

  @override
  onActionPressed(int action) {
    return null;
  }

  @override
  onError(String message) {
    AppSnackbar.showErrorSnackbar(
        scaffoldKey: _key, message: message, listener: this, actionLabel: "OK");
    setState(() {
      errorText = message;
    });
  }

  int counter = 0;
  @override
  onRecordAdded() {
    setState(() {
      counter++;
    });
  }

  @override
  onBag(AssociationBag bag) {
    print(
        '_ExistingDataPageState.onBag #################### bag coming in ....${DateTime.now().toIso8601String()}');
    setState(() {
      activeBags.add(bag);
      counter++;
    });
  }
}

class AssocCard extends StatelessWidget {
  final double elevation;
  final AssociationBag bag;
  final Color color;
  final AnimationController animationController;
  AssocCard(
      {this.elevation,
      @required this.bag,
      this.color,
      @required this.animationController});

  @override
  Widget build(BuildContext context) {
    bag.filterUsers();
    return ScaleTransition(
      scale: animationController,
      child: Card(
        elevation: elevation == null ? 2.0 : elevation,
        color: color == null ? Colors.white : color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 10.0,
              ),
              Row(
                children: <Widget>[
                  Flexible(
                    child: Container(
                      child: Text(
                        bag.association.associationName,
                        style: Styles.blackBoldMedium,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10.0,
              ),
              Row(
                children: <Widget>[
                  Text(
                    bag.association.associationID == null
                        ? ''
                        : bag.association.associationID,
                    style: Styles.greyLabelSmall,
                  ),
                ],
              ),
              SizedBox(height: 8.0),
              CardItem(
                title: 'Owners',
                total: bag.owners.length,
                titleStyle: Styles.blackBoldSmall,
                totalStyle: Styles.pinkBoldMedium,
                icon: Icon(Icons.people),
              ),
              CardItem(
                title: 'Drivers',
                total: bag.drivers.length,
                titleStyle: Styles.blackBoldSmall,
                totalStyle: Styles.blueBoldMedium,
                icon: Icon(Icons.airport_shuttle),
              ),
              SizedBox(
                height: 4.0,
              ),
              CardItem(
                title: 'Marshals',
                total: bag.marshals.length,
                titleStyle: Styles.blackBoldSmall,
                totalStyle: Styles.tealBoldMedium,
                icon: Icon(Icons.pan_tool),
              ),
              CardItem(
                title: 'Association Staff',
                total: bag.officeAdmins.length,
                titleStyle: Styles.blackBoldSmall,
                totalStyle: Styles.blackBoldMedium,
                icon: Icon(Icons.people),
              ),
              SizedBox(
                height: 4.0,
              ),
              CardItem(
                title: 'Vehicles',
                total: bag.cars.length,
                titleStyle: Styles.blackBoldSmall,
                totalStyle: Styles.blueBoldMedium,
                icon: Icon(Icons.airport_shuttle),
              ),
              CardItem(
                title: 'Vehicle Types',
                total: bag.carTypes.length,
                titleStyle: Styles.blackBoldSmall,
                totalStyle: Styles.blackBoldMedium,
                icon: Icon(
                  Icons.airport_shuttle,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final Icon icon;
  final String title;
  final int total;
  final TextStyle titleStyle, totalStyle;

  CardItem(
      {this.icon, this.title, this.total, this.titleStyle, this.totalStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 80.0,
            child: icon == null ? Icon(Icons.apps) : icon,
          ),
          SizedBox(
            width: 20,
          ),
          SizedBox(
            width: 60.0,
            child: Text(
              '$total',
              style: totalStyle == null ? Styles.pinkBoldSmall : totalStyle,
            ),
          ),
          Text(
            title,
            style: titleStyle == null ? Styles.blackBoldSmall : titleStyle,
          ),
        ],
      ),
    );
  }
}

class BagList extends StatelessWidget {
  final List<AssociationBag> activeBags;
  final ScrollController scrollController;
  final AnimationController animationController;

  BagList(
      {@required this.activeBags,
      this.scrollController,
      @required this.animationController});

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    });
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ListView.builder(
            itemCount: activeBags == null ? 0 : activeBags.length,
            controller: scrollController,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: AssocCard(
                  elevation: 4.0,
                  animationController: animationController,
                  color: getRandomPastelColor(),
                  bag: activeBags.elementAt(index),
                ),
              );
            }),
      ),
    );
  }
}
