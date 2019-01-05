import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BeaconScanner extends StatefulWidget {
  @override
  _BeaconScannerState createState() => _BeaconScannerState();
}

class _BeaconScannerState extends State<BeaconScanner> {
  static const beaconScanStream = const EventChannel('aftarobot/beaconScan');
  GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  List<EstimoteBeacon> estimoteBeacons = List();
  StreamSubscription subscription;
  bool isScanStarted = false;
  int beaconCount = 0;

  @override
  void initState() {
    super.initState();
  }

  void _startBeaconScan() async {
    print('################ startBeaconScan .....................');
    setState(() {
      estimoteBeacons.clear();
      beaconCount = 0;
    });
    if (subscription == null) {
      beaconCount = 0;
      subscription =
          beaconScanStream.receiveBroadcastStream().listen((scanResult) {
        print(
            '################ --- receiveBroadcastStream: scanResult: $scanResult');
        beaconCount++;
        Map map = json.decode(scanResult);
        var estimoteBeacon = EstimoteBeacon.fromJson(map);
        //check if beacon already in list
        var isFound = false;
        estimoteBeacons.forEach((b) {
          if (b.beaconName == estimoteBeacon.beaconName) {
            isFound = true;
          }
        });
        if (!isFound) {
          setState(() {
            estimoteBeacons.add(estimoteBeacon);
          });
        }
        print(
            'my beacon scan result is a EstimoteBeacon! ******** streamed responses: ${beaconCount}');
        if (beaconCount > 80) {
          _cancelScan();
        }
        _key.currentState.removeCurrentSnackBar();
      });
      _showSnackBar(message: 'Scanning started', color: Colors.lightBlue);
    }

    return null;
  }

  void _cancelScan() {
    print('------------- cancel beacon scan ----------------');
    subscription.cancel();
    subscription = null;
    _showSnackBar(message: 'Scanning stopped', color: Colors.white);
  }

  _showSnackBar({String message, Color color}) {
    AppSnackbar.showSnackbar(
      backgroundColor: Colors.black,
      textColor: color == null ? Colors.white : color,
      message: message,
      scaffoldKey: _key,
    );
  }

  Widget _getBottom() {
    return PreferredSize(
      preferredSize: Size.fromHeight(200),
      child: Column(
        children: <Widget>[
          Text(
            'Scan Estimote Beacons',
            style: Styles.yellowBoldLarge,
          ),
          Text('Prepare to register beacons to AftaRobot',
              style: Styles.whiteSmall),
          SizedBox(
            height: 10,
          ),
          Column(
            children: <Widget>[
              Text('${estimoteBeacons.length}',
                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.w900)),
              Text('Beacons', style: Styles.whiteSmall),
              SizedBox(
                height: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('BeaconScanner'),
        bottom: _getBottom(),
        backgroundColor: Colors.indigo.shade400,
      ),
      body: ListView.builder(
        itemCount: estimoteBeacons.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12),
            child: Card(
              elevation: 2,
              color: getRandomPastelColor(),
              child: ListTile(
                leading: Icon(Icons.bluetooth_connected,
                    color: Colors.blue.shade800, size: 28),
                title: Text('${estimoteBeacons.elementAt(index).beaconName}',
                    style: Styles.blackBoldSmall),
                subtitle: Text(
                  '${estimoteBeacons.elementAt(index).advertisedId}',
                  style: Styles.greyLabelSmall,
                ),
              ),
            ),
          );
        },
      ),
      backgroundColor: Colors.brown.shade100,
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.list,
              size: 40,
            ),
            title: Text('List'),
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.cancel,
              size: 40,
              color: Colors.pink,
            ),
            title: Text('Stop Scan'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_searching, size: 40, color: Colors.blue),
            title: Text('Start Scan'),
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              _cancelScan();
              break;
            case 2:
              _startBeaconScan();
              break;
          }
        },
      ),
    );
  }
}

class EstimoteBeacon {
  String beaconName, advertisedId;
  EstimoteBeacon({this.beaconName, this.advertisedId});

  EstimoteBeacon.fromJson(Map map) {
    this.advertisedId = map['advertisedId'];
    this.beaconName = map['beaconName'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'beaconName': beaconName,
      'advertisedId': advertisedId,
    };
    return map;
  }
}
