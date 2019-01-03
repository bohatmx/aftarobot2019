import 'package:crashtest/beacons/beacon_api.dart';
import 'package:crashtest/beacons/google_data/advertisedid.dart';
import 'package:crashtest/beacons/google_data/beacon.dart';
import 'package:crashtest/ui/beacon_registration.dart';
import 'package:crashtest/util/functions.dart';
import 'package:crashtest/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

enum MyPermissionGroup {
  bluetooth,
}

class BeaconScanner extends StatefulWidget {
  @override
  _BeaconScannerState createState() => _BeaconScannerState();
}

class _BeaconScannerState extends State<BeaconScanner>
    implements SnackBarListener {
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();
  bool isScanStarted = false;
  Beacon beacon;
  List<EstimoteBeacon> estimoteBeacons = List();

  @override
  void initState() {
    super.initState();
    _checkPermission();
    googleBeaconBloc.getRegistryBeacons();
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

  void _startBeaconScan() async {
    print('\n\n################ ️ℹ️ ℹ️ startBeaconScan .....................');
    try {
      isScanStarted = true;
      googleBeaconBloc.startBeaconScan();
    } on PlatformException {
      print('️ ⚠️ ️ ⚠️ ️ ⚠️  We have an issue with beacon scanning, Senor!');
    }
    return null;
  }

  void _cancelScan() {
    print('------------- cancel beacon scan ----------------');
    googleBeaconBloc.stopScan();
    isScanStarted = false;
    _showSnackBar(message: 'Scanning stopped', color: Colors.white);
  }

  void _startRegistration(EstimoteBeacon eb) {
    print(
        '\n\n############################################# _startRegistration');
    beacon = Beacon(
      advertisedId: AdvertisedId(id: eb.advertisedId, type: 'EDDYSTONE'),
      status: 'ACTIVE',
      description: 'AftaRobot Vehicle Beacon',
      expectedStability: 'ROVING',
    );
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => BeaconRegistration(beacon: beacon)));
  }

  _showSnackBar({String message, Color color}) {
    AppSnackbar.showSnackbar(
      backgroundColor: Colors.black,
      textColor: color == null ? Colors.white : color,
      message: message,
      scaffoldKey: _key,
    );
  }

  void _checkIfBeaconRegistered(EstimoteBeacon eb) {
    bool isFound = false;
    googleBeaconBloc.beacons.forEach((b) {
      if (b.advertisedId.id == eb.advertisedId) {
        isFound = true;
      }
    });
    if (!isFound) {
      _showConfirmDialog(eb);
    } else {
      AppSnackbar.showErrorSnackbar(
          scaffoldKey: _key,
          message: 'Beacon already registered',
          listener: this,
          actionLabel: 'close');
    }
  }

  void _showConfirmDialog(EstimoteBeacon eb) {
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text(
                "Beacon Registration",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
              ),
              content: Container(
                height: 120.0,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                          'Do you want to register this beacon on the Google registry?'),
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
                      _startRegistration(eb);
                    },
                    elevation: 4.0,
                    color: Colors.teal.shade500,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Start Registration',
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

  EstimoteBeacon estimoteBeacon;
  int count = 0;
  @override
  Widget build(BuildContext context) {
    count = googleBeaconBloc.estimoteBeacons.length;
    return StreamBuilder(
        initialData: googleBeaconBloc.estimoteBeacons,
        stream: googleBeaconBloc.estimoteBeaconStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            estimoteBeacons = snapshot.data;
            print(
                '️ 🔵 ℹ️ bringing beacons from the bloc: ${estimoteBeacons.length}');
          }
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
                    child: GestureDetector(
                      onTap: () {
                        _checkIfBeaconRegistered(
                            estimoteBeacons.elementAt(index));
                      },
                      child: Card(
                        elevation: 4,
                        color: getRandomPastelColor(),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: ListTile(
                            leading: Icon(Icons.bluetooth_connected,
                                color: Colors.blue.shade800, size: 28),
                            title: Text(
                                '${estimoteBeacons.elementAt(index).beaconName}',
                                style: Styles.blackBoldSmall),
                            subtitle: Text(
                              '${estimoteBeacons.elementAt(index).advertisedId}',
                              style: Styles.greyLabelSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
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
                  icon: Icon(Icons.bluetooth_searching,
                      size: 40, color: Colors.blue),
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
        });
  }

  @override
  onActionPressed(int action) {
    // TODO: implement onActionPressed
    return null;
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
