import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vehicle/vehicle_bloc/vehicle_bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: 'VehicleApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
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
  VehicleAppBloc bloc = vehicleBloc;

  @override
  void initState() {
    super.initState();
    _signIn();
    _startMessageChannel();
  }

  void _signIn() async {
    bloc.signInAnonymously();
  }

  void _executeGeoQuery() async {
    print(' 🔵  🔵  start geo query .... ........................');
    try {
      bloc.searchForLandmarks(-25.760506499999998, 27.852598, 12);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  void _startMessageChannel() {
    print(
        '+++  🔵 starting message channel and geoQuery from the Flutter side');
    try {
      bloc.listenForCommuterMessages();
    } on PlatformException {
      print(
          'Things went south in a hurry, Jack!  ⚠️ ⚠️ Message listening not so hot ..');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: bloc.landmarksStream,
        initialData: bloc.landmarks,
        builder: (context, snapshot) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: _executeGeoQuery,
                ),
              ],
            ),
            body: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: Card(
                      child: ListTile(
                        leading: Icon(Icons.message),
                        title: Text(
                          messages.elementAt(index),
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }),

            floatingActionButton: FloatingActionButton(
              onPressed: _executeGeoQuery,
              tooltip: 'Start Message Channel',
              child: Icon(Icons.settings),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          );
        });
  }
}
