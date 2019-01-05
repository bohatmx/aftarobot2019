import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  StreamSubscription _beaconScanSubscription;
  static const beaconScanStream = const EventChannel('aftarobot/messages');
  static const geoQueryChannel = const MethodChannel('aftarobot/geoQuery');

  List<String> messages = List();
  VehicleBloc bloc = vehicleBloc;

  @override
  void initState() {
    super.initState();
    //_startMessageChannel();
    _signIn();
  }

  void _signIn() async {
    bloc.signInAnonymously();
  }

  void _testGeoQuery() async {
    print(' 🔵  🔵  start geo query .... ........................');
    try {
      var args = {
        'latitude': -25.760506499999998,
        'longitude': 27.852598,
        'radius': 5.0
      };
      var result = await geoQueryChannel.invokeMethod(
          'findLandmarks', json.encode(args));
      print('Result back from geoQuery .... ✅ ✅ ✅ ');
      List<dynamic> list = json.decode(result);
      print('. ✅ ... number of geoPoints returned: ${list.length}');
      List<String> landmarkIDs = List();

      list.forEach((t) {
        if (t is Map) {
          t.forEach((key, value) {
            print("++++++ landmarkID :::: $key ");
            landmarkIDs.add(key);
          });
        }
      });
      getLocatedLandmarks(landmarkIDs);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  void getLocatedLandmarks(List<String> ids) {
    Firestore fs = Firestore.instance;
    List<LandmarkDTO> landmarks = List();
    int count = 0;
    for (var id in ids) {
      fs.collection('landmarks').document(id).get().then((documentSnap) {
        if (documentSnap.exists) {
          var lm = LandmarkDTO.fromJson(documentSnap.data);
          landmarks.add(lm);
          count++;
          prettyPrint(lm.toJson(),
              ' 🔵  🔵  ############# LANDMARK::: #$count  🔵  🔵  ✅ ');
        }
      });
    }
    print(' ✅  We have ${landmarks.length} landmarks found in area search');
  }

  void _startMessageChannel() {
    print(
        '+++  🔵 starting message channel and geoQuery from the Flutter side');
    try {
      _testGeoQuery();
      _beaconScanSubscription =
          beaconScanStream.receiveBroadcastStream().listen((message) {
        print('### - 🔵 - message received :: ${message.toString()}');
        setState(() {
          messages.add(message.toString());
        });
      });
    } on PlatformException {
      _beaconScanSubscription.cancel();
      print(
          'Things went south in a hurry, Jack!  ⚠️ ⚠️ Message listening not so hot ..');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: _testGeoQuery,
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),

      floatingActionButton: FloatingActionButton(
        onPressed: _startMessageChannel,
        tooltip: 'Start Message Channel',
        child: Icon(Icons.settings),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
