import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/beacons/google_data/beacon.dart';
import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/vehicledto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import "package:googleapis_auth/auth_io.dart";
import "package:http/http.dart" as http;

final GoogleBeaconBloc googleBeaconBloc = GoogleBeaconBloc();

abstract class BeaconListener {
  onBeaconScanned(Beacon b);
}

class GoogleBeaconBloc {
  static const URL = 'https://proximitybeacon.googleapis.com/v1beta1/';
  static const Scopes = [
    'https://www.googleapis.com/auth/userlocation.beacon.registry'
  ];

  GoogleBeaconBloc() {
    initializeData();
    initializeAuthClient();
  }
  void initializeData() async {
    print('\n\n## Initialization of GoogleBeaconBloc data models ...🔵 🔵 🔵 ');
    await getAssociations();
    await getExistingBeacons();
    await getExistingBeacons();
    print('++ 🔵 🔵 🔵 Initialization complete.');
  }

  Firestore fs = Firestore.instance;
  StreamController<List<AssociationDTO>> _associationController =
      StreamController.broadcast();
  StreamController<List<VehicleDTO>> _vehicleController =
      StreamController.broadcast();
  StreamController<List<Beacon>> _beaconController =
      StreamController.broadcast();
  StreamController<List<EstimoteBeacon>> _estimoteBeaconController =
      StreamController.broadcast();

  List<VehicleDTO> _vehicles = List();
  List<VehicleDTO> get vehicles => _vehicles;

  List<AssociationDTO> _associations = List();
  List<AssociationDTO> get associations => _associations;

  List<Beacon> _beacons = List();
  List<Beacon> get beacons => _beacons;

  get beaconStream => _beaconController.stream;
  get estimoteBeaconStream => _estimoteBeaconController.stream;
  get associationStream => _associationController.stream;
  get vehicleStream => _vehicleController.stream;

  bool _isBusy = false;
  get isBusy => _isBusy;

  void closeStreams() {
    _associationController.close();
    _vehicleController.close();
    _beaconController.close();
    _estimoteBeaconController.close();
  }

  Future<Map> loadAsset() async {
    String keys = await rootBundle.loadString('assets/auth_client_keys.json');
    print('Authorized Client Keys:  🔵  🔵  - Ready to Rumble!!');
    var map = json.decode(keys);
    return map;
  }

  AccessCredentials _accessCredentials;
  http.Client _httpClient;

  Future<int> initializeAuthClient() async {
    print('️ℹ️ ℹ️  ️#################### initializeAuthClient .....');
//    if (_accessCredentials != null) {
//      print('************* we are using an existing authorised client!   ✅ ');
//      return 0;
//    }

    try {
      var map = await loadAsset();
      final accountCredentials = new ServiceAccountCredentials.fromJson(map);
      _httpClient = new http.Client();
      _accessCredentials = await obtainAccessCredentialsViaServiceAccount(
          accountCredentials, Scopes, _httpClient);
      if (_accessCredentials == null) {
        throw Exception('###### ERROR - unable to get access credentials');
      } else {
        print(
            'we got ourselvess an access token::🔵 🔵 🔵 ${_accessCredentials.accessToken.data} 🔵 🔵 🔵 ');
      }
      return 0;
    } catch (e) {
      print('⚠️ ⚠️ ⚠️  $e');
      if (_httpClient != null) {
        _httpClient.close();
      }
      throw e;
    }
    return 9;
  }

  Future<Beacon> registerBeacon(Beacon beacon) async {
    print('###### ️ ⚠️ registering beacon: ${beacon.toJson()}');
    var url = URL + 'beacons:register';
    try {
      var data = {
        'advertisedId': {
          'id': beacon.advertisedId.id,
          'type': 'EDDYSTONE',
        },
        'status': 'ACTIVE',
        'expectedStability': 'ROVING',
        'description': 'AftaRobot Vehicle Beacon',
      };
      var res = await _callGoogle(url: url, data: data);
      if (res['error'] != null) {
        throw Exception('Registry beacon already exists');
      } else {
        var b = Beacon.fromJson(json.decode(res));
        print(
            '###  ✅ beacon added to Google registry, returned: 🔵  🔵  ${b.toJson()}');
        var c = await _addRegisteredBeacon(b);
        _beacons.add(c);
        _beaconController.sink.add(_beacons);
        //get beacons from the Google registry
        await getRegistryBeacons();
        return c;
      }
    } catch (e) {
      print('⚠️  ⚠️  ⚠️  \n$e\n ⚠️  ⚠️  ⚠️ ');
      throw e;
    }
  }

  Future _addRegisteredBeacon(Beacon beacon) async {
    print('##### adding beacon to Firestore: ${beacon.toJson()}');

    DocumentReference ref = await fs.collection('beacons').add(beacon.toJson());
    beacon.path = ref.path;
    await ref.setData(beacon.toJson());
    print('###  ✅ beacon added to Firestore, path: ${beacon.path}');
  }

  Future<List<Beacon>> getRegistryBeacons() async {
    print('........ ⚠️ getting list of registry beacons');
    await initializeAuthClient();
    var url = URL + "beacons" + "?pageSize=1000&q=";
    var res = await _callGoogle(url: url);

    print(' ⚠️ ⚠️ check format of response: $res');
    List list = List<Beacon>();
    //todo - parse list
    var xx = json.decode(res);

    List<dynamic> maps = xx['beacons'];
    maps.forEach((m) {
      var b = Beacon.fromJson(m);
      if (b != null) {
        list.add(Beacon.fromJson(m));
      }
    });
    print(
        '### list of registered beacons direct from the registry:✅ ✅ ✅ ---> ${list.length}');
    int count = 0;
    list.forEach((m) {
      count++;
      prettyPrint(m.toJson(),
          'getRegistryBeacons ********* - 🔵 beacon #$count from the registry:');
    });
    return list;
  }

  Future _callGoogle({String url, Map data}) async {
    _isBusy = true;
    await initializeAuthClient();
    if (_accessCredentials == null) {
      _isBusy = false;
      throw Exception('️ ⚠️ ⚠️  We have no authorized _accessCredentials');
    }

    try {
      Map<String, String> headers = {
        'Content-type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ' + _accessCredentials.accessToken.data,
      };

      http.Response resp;
      if (data != null) {
        //POST request
        print('\n\n** ⚠️ .......... about to post beacon ..... ');
        resp = await _httpClient
            .post(
          url,
          body: json.encode(data),
          headers: headers,
        )
            .whenComplete(() {
          _httpClient.close();
        });
      } else {
        //GET request
        print('about to make a GET request.........');
        resp = await _httpClient.get(url, headers: headers);
      }
      if (resp == null) {
        throw new Exception(
            '--- ⚠️ ⚠️ response from $url ⚠️ ⚠️ is null. --- check!');
      }
      print(resp.body);
      print(
          'GoogleBeaconApi._callGoogle  ✅  .... ::::: statusCode: ${resp.statusCode} for $url');
      _isBusy = false;
      switch (resp.statusCode) {
        case 200:
          print('✅ ✅ Call to Google Beacon API successful. yo!');
          return resp.body;
          break;
        case 409:
          prettyPrint(json.decode(resp.body),
              '+++++++++++++++++++ ⚠️ ⚠️ existing registered, throwing a fit!');
          throw Exception('Beacon already registered');
          break;

        default:
          throw Exception(
              '⚠️ ⚠️ ⚠️  - We have a problem calling Google Beacon API, status: ${resp.statusCode} \n ${resp.body}');
          break;
      }
    } catch (e) {
      _isBusy = false;
      print('️ ⚠️ ⚠️ _callGoogle() -  problem calling Google - $e');
      throw e;
    }
  }

  Future<List<VehicleDTO>> getVehicles(String associationPath) async {
    _isBusy = true;
    var qs = await fs
        .document(associationPath)
        .collection('vehicles')
        .getDocuments();
    qs.documents.forEach((doc) {
      _vehicles.add(VehicleDTO.fromJson(doc.data));
    });
    _vehicleController.sink.add(_vehicles);
    print('ℹ️ ### found ${_vehicles.length} vehicles - 🔵 ');
    _isBusy = false;
    return _vehicles;
  }

  Future getAssociations() async {
    _isBusy = true;

    var qs = await fs.collection('associations').getDocuments();
    _associations.clear();
    qs.documents.forEach((doc) {
      _associations.add(AssociationDTO.fromJson(doc.data));
    });
    _associationController.sink.add(_associations);
    _vehicles.clear();
    for (var ass in _associations) {
      //prettyPrint(ass.toJson(), '###### ASSOCIATION: check path');
      await getVehicles(ass.path);
    }
    print('ℹ️ ### found ${_associations.length} associations - 🔵 ');
    _isBusy = false;
    return null;
  }

  Future<List<Beacon>> getExistingBeacons() async {
    _isBusy = true;
    var qs = await fs.collection('beacons').getDocuments();
    _beacons.clear();
    qs.documents.forEach((doc) {
      _beacons.add(Beacon.fromJson(doc.data));
    });
    _beaconController.sink.add(_beacons);
    print(
        'ℹ️ ### getExistingBeacons: found ${_beacons.length} beacons from Firestore - 🔵 ');
    _isBusy = false;
    return _beacons;
  }

  static const beaconScanStream = const EventChannel('aftarobot/beaconScan');

  StreamSubscription _beaconScanSubscription;
  List<EstimoteBeacon> _estimoteBeacons = List();
  get estimoteBeacons => _estimoteBeacons;

  int beaconCount = 0;
  //control beacon scan - find EDDYSTONE beacons around you
  void startBeaconScan(int limit) async {
    print('\n\n################ ️ℹ️ ℹ️ startBeaconScan .....................');
    beaconCount = 0;
    _estimoteBeacons.clear();
    _estimoteBeaconController.sink.add(_estimoteBeacons);
    try {
      _beaconScanSubscription =
          beaconScanStream.receiveBroadcastStream().listen((scanResult) {
        print(
            '################  🔵 --- receiveBroadcastStream: scanResult: $scanResult');
        Map map = json.decode(scanResult);
        var estimoteBeacon = EstimoteBeacon.fromJson(map);
        beaconCount++;
        //check if beacon already in list
        var isFound = false;
        _estimoteBeacons.forEach((b) {
          if (b.beaconName == estimoteBeacon.beaconName) {
            isFound = true;
          }
        });
        if (!isFound) {
          _estimoteBeacons.add(estimoteBeacon);
          _estimoteBeaconController.sink.add(_estimoteBeacons);
        }
        print(
            'my beacon scan result is a EstimoteBeacon! ******** ️ℹ️ ℹ️ streamed responses: ${estimoteBeacons.length}');
        if (beaconCount > limit) {
          stopScan();
        }
      }, onError: handleError);
    } on PlatformException {
      print('️ ⚠️ ️ ⚠️ ️ ⚠️  We have an issue with beacon scanning, Senor!');
    }
    return null;
  }

  void handleError(Object message) {
    print(
        '️ ⚠️ ️ ⚠️ ️ ⚠️  We have an issue with beacon scanning, Senor! $message\n\nWhat do we do now?\n\n');
  }

  void stopScan() {
    print('⚠️ ------------- stop beacon scan ---------------- 🔵 WORK DONE! ');
    _beaconScanSubscription.cancel();
    _beaconScanSubscription = null;
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
