import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
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

  List<LandmarkDTO> landmarks = List();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: bloc.landmarksStream,
        initialData: bloc.landmarks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            landmarks = snapshot.data;
          }
          return Scaffold(
            appBar: AppBar(
              title: Text(landmarks.isNotEmpty
                  ? landmarks.elementAt(0).routeName
                  : 'AftaRobot Vehicle App'),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.location_on),
                  onPressed: _executeGeoQuery,
                ),
              ],
            ),
            backgroundColor: Colors.brown.shade100,
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: LandmarkList(
                landmarks: landmarks,
              ),
            ),

            floatingActionButton: FloatingActionButton(
              onPressed: _executeGeoQuery,
              tooltip: 'Start Message Channel',
              child: Icon(Icons.settings),
            ), // This trailing comma makes auto-formatting nicer for build methods.
          );
        });
  }
}

class LandmarkList extends StatelessWidget {
  final List<LandmarkDTO> landmarks;

  const LandmarkList({Key key, this.landmarks}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: landmarks == null ? 0 : landmarks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Card(
              elevation: 4,
              color: getRandomPastelColor(),
              child: ListTile(
                leading: Icon(
                  Icons.my_location,
                  color: getRandomColor(),
                ),
                title: Row(
                  children: <Widget>[
                    TrickleCounter(
                      total: 1765,
                      caption: 'Passengers',
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    Text(
                      landmarks == null
                          ? ""
                          : landmarks.elementAt(index).landmarkName,
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}

class LandmarkMap extends StatelessWidget {
  final List<LandmarkDTO> landmarks;

  const LandmarkMap({Key key, this.landmarks}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.purple.shade200,
      child: SizedBox(
        width: 200,
      ),
    );
  }
}

class TrickleCounter extends StatelessWidget {
  final int total;
  final String caption;
  final TextStyle totalStyle, captionStyle;

  const TrickleCounter(
      {Key key, this.total, this.caption, this.totalStyle, this.captionStyle})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          total == null ? '1048' : '$total',
          style: Styles.blueBoldLarge,
        ),
        Text(
          caption == null ? 'People' : caption,
          style: Styles.blackSmall,
        ),
      ],
    );
  }
}
