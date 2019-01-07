import 'package:aftarobotlibrary3/api/sharedprefs.dart';
import 'package:flutter/material.dart';
import 'package:vehicle/ui/landing_page.dart';
import 'package:vehicle/ui/register_vehicle.dart';
import 'package:vehicle/vehicle_bloc/vehicle_bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VehicleApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: "Raleway",
      ),
      home: MyHomePage(title: 'AftaRobot CarApp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

//(-25.760506499999998, 27.852598,
class _MyHomePageState extends State<MyHomePage> {
  List<String> messages = List();
  VehicleAppBloc bloc;

  @override
  void initState() {
    super.initState();
    checkVehicle();
  }

  bool isVehicleAvailable = false;

  void checkVehicle() async {
    print('########## ⚠️ ⚠️ check for app vehicle ...');
    var v = await Prefs.getVehicle();
    if (v == null) {
      print('########## ⚠️ ⚠️  vehicle has not been set up for the App ...');
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Registration()));
    } else {
      print(
          '\n\n🔵 🔵 🔵 _MyHomePageState: ############# CREATING NEW VehicleAppBloc 🔵 🔵 🔵 \n\n');
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => LandingPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AftaRobot Vehicle App'),
      ),
      backgroundColor: Colors.brown.shade100,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(),
      ),
    );
  }
}
