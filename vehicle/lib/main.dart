import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  StreamSubscription _beaconScanSubscription;
  static const beaconScanStream = const EventChannel('aftarobot/messages');
  List<String> messages = List();

  @override
  void initState() {
    super.initState();
    //_startMessageChannel();
  }

  void _startMessageChannel() {
    print('+++  🔵 starting message channel from the Flutter side');
    try {
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

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
