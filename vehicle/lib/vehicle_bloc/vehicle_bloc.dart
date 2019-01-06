import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/api/sharedprefs.dart';
import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/geofence_event.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/vehicle_logdto.dart';
import 'package:aftarobotlibrary3/data/vehicledto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart';
import 'package:latlong/latlong.dart';

final VehicleAppBloc vehicleAppBloc = VehicleAppBloc();

//✅  🎾 🔵  📍   ℹ️
class VehicleAppBloc {
  VehicleAppBloc() {
    print('+++ ℹ️ +++  ++++++++++++++++++ initializing Vehicle App Bloc');
    _setBackgroundLocation();
    _initialize();
  }
  static const Radius = 5.0;
  FirebaseAuth auth = FirebaseAuth.instance;
  Firestore fs = Firestore.instance;

  static const geoQueryChannel = const MethodChannel('aftarobot/geoQuery');
  static const messageStream = const EventChannel('aftarobot/messages');
  StreamSubscription _messagesSubscription;

  StreamController<List<LandmarkDTO>> _landmarksController =
      StreamController.broadcast();
  StreamController<String> _nearbyMessagesController =
      StreamController.broadcast();
  StreamController<bg.Location> _locationController =
      StreamController.broadcast();
  StreamController<List<AssociationDTO>> _assocController =
      StreamController.broadcast();
  StreamController<List<VehicleDTO>> _vehicleController =
      StreamController.broadcast();

  final Distance distance = new Distance();

  bg.Location _currentLocation;
  bg.Location get currentLocation => _currentLocation;

  List<LandmarkDTO> _landmarks = List();
  List<LandmarkDTO> get landmarks => _landmarks;

  List<AssociationDTO> _associations = List();
  List<AssociationDTO> get associations => _associations;

  List<VehicleDTO> _vehicles = List();
  List<VehicleDTO> get vehicles => _vehicles;
  VehicleDTO _vehicle;
  VehicleDTO get vehicle => _vehicle;

  get landmarksStream => _landmarksController.stream;
  get nearbyMessageStream => _nearbyMessagesController.stream;
  get locationStream => _locationController.stream;
  get associationStream => _assocController.stream;
  get vehicleStream => _vehicleController.stream;

  void closeStreams() {
    _landmarksController.close();
    _nearbyMessagesController.close();
    _locationController.close();
    _vehicleController.close();
    _assocController.close();
  }

  Future setVehicleForApp(VehicleDTO vehicle) async {
    await Prefs.saveVehicle(vehicle);
    return null;
  }

  Future<VehicleDTO> getVehicleForApp() async {
    var v = await Prefs.getVehicle();
    return v;
  }

  VehicleDTO _appVehicle;
  get appVehicle => _appVehicle;

  void _initialize() async {
    print('### initialise - 🔵 - check if vehicle has been saved in Prefs');
    _appVehicle = await Prefs.getVehicle();
    if (_appVehicle == null) {
      print('###  ℹ️ App has no vehicle set up yet');
      await getAssociations();
    }
  }

  void _setBackgroundLocation() {
    // 1.  Listen to events (See docs for all 12 available events).
    bg.BackgroundGeolocation.onLocation(_onLocation);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChanged);
    bg.BackgroundGeolocation.onActivityChange(_onActivityChanged);
    bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    bg.BackgroundGeolocation.onGeofence(_onGeofenceEvent);

    // 2.  Configure the plugin
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 10.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: true,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            reset: true))
        .then((bg.State state) {
      print('## 📍 ODOMETER: ${state.odometer}');
      print('## 📍 state :: ${state.toMap()}');
    });

    //bg.BackgroundGeolocation.start();
    //bg.BackgroundGeolocation.startGeofences();
    print('### ✅ background location set. will start tracking ...');
  }

  _onGeofenceEvent(GeofenceEvent event) async {
    if (_vehicle == null) {
      print('\n---  ⚠️ vehicle is null, geofence event will not be recorded');
      return null;
    }
    print('\n\n+++  🎾 add geofence event to Firestore');
    var m = ARGeofenceEvent(
      vehicleID: _vehicle.vehicleID,
      vehicleReg: _vehicle.vehicleReg,
      make: _vehicle.vehicleType.make + " " + _vehicle.vehicleType.model,
      action: event.action,
      landmarkID: event.identifier,
      stringTimestamp: DateTime.now().toUtc().toIso8601String(),
      timestamp: event.location.timestamp,
      isMoving: event.location.isMoving,
      odometer: event.location.odometer,
      activityType: event.location.activity.type,
      confidence: event.location.activity.confidence,
    );

    await fs.collection('geofenceEvents').add(m.toJson());
    print('+++ 🔵 +++ geofence event recorded for ${_vehicle.vehicleReg}');
  }

  _onMotionChanged(bg.Location location) {
    print('&&&&&&&&&&&&&  ℹ️ onMotionChanged: location ${location.toMap()}');
    _currentLocation = location;
    _locationController.sink.add(location);
  }

  _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    print(
        '+++++++++++++++ _onConnectivityChange connected: ${event.connected}');
  }

  _onActivityChanged(bg.ActivityChangeEvent event) {
    print('#############  ℹ️ _onActivityChanged: ${event.toMap()}');
  }

  _onLocation(bg.Location location) {
    print('\n\n@@@@@@@@@@@ ✅  -- onLocation:  isMoving? ${location.isMoving}');
    print('${location.toMap()}');
    _currentLocation = location;
    _locationController.sink.add(location);
    _writeVehicleLocationLog();
  }

  _onProviderChange(ProviderChangeEvent event) {
    print('_onProviderChange --- ');
  }

  _writeVehicleLocationLog() async {
    print('### 📍📍 writing vehicle location log entry ......');
    if (_vehicle == null) {
      print('#### vehicle is null. not tracking ....');
    } else {
      var log = VehicleLogDTO(
        date: DateTime.now().toUtc().millisecondsSinceEpoch,
        stringDate: DateTime.now().toUtc().toIso8601String(),
        latitude: _currentLocation.coords.latitude,
        longitude: _currentLocation.coords.longitude,
        vehicleID: _vehicle.vehicleID,
        vehicle: _vehicle,
        vehicleLogID: getKey(),
      );
      await fs
          .collection('associations')
          .document(_vehicle.associationID)
          .collection('vehicles')
          .document(_vehicle.vehicleID)
          .collection('vehicleLogs')
          .add(log.toJson());
      print('### 🔵 vehicle location log has been written to Firestore');
    }
  }

  Future getAssociations() async {
    var qs = await fs
        .collection('associations')
        .orderBy('associationName')
        .getDocuments();
    _associations.clear();
    qs.documents.forEach((doc) {
      var ass = AssociationDTO.fromJson(doc.data);
      _associations.add(ass);
    });
    _assocController.sink.add(_associations);
    print('###  - 🔵 - associations found : ${_associations.length}');
  }

  Future<List<VehicleDTO>> getVehicles(String path) async {
    print('+++ getVehicles for association: $path');

    var qs = await fs.document(path).collection('vehicles').getDocuments();

    _vehicles.clear();
    qs.documents.forEach((doc) {
      var v = VehicleDTO.fromJson(doc.data);
      _vehicles.add(v);
    });

    _vehicleController.sink.add(_vehicles);
    print(
        '###  - 🔵 - vehicles found: ${_vehicles.length} for association $path');
    return _vehicles;
  }

  void _calculateDistancesBetweenLandmarks() {}
  void searchForLandmarks(
      {double latitude, double longitude, double radius}) async {
    print(
        '\n\n🔵  🔵  VehicleBloc: start geo query .... ........................');

    if (latitude == null) {
      latitude = _currentLocation.coords.latitude;
      longitude = _currentLocation.coords.longitude;
    }
    if (radius == null) {
      radius = Radius;
    }
    try {
      _landmarks.clear();
      var args = {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      };
      var result = await geoQueryChannel.invokeMethod(
          'findLandmarks', json.encode(args));
      print('\n\nVehicleBloc: Result back from geoQuery ....  ✅ ');

      List<dynamic> list = json.decode(result);
      print('. ✅ ... number of searched geoPoints returned: ${list.length}');

      list.forEach((t) {
        if (t is Map) {
          t.forEach((key, value) {
            _getLocatedLandmark(key);
          });
        }
      });
      bg.BackgroundGeolocation.startGeofences();
    } on PlatformException catch (e) {
      print('\nVehicleBloc: Why is the result coming back twice??????????? '
          '- will check for already located landmarks: ${_landmarks.length}');
      print(e);
      throw Exception(e);
    }
  }

  Future _getLocatedLandmark(String id) async {
    DocumentSnapshot ds = await fs.collection('landmarks').document(id).get();
    if (ds.exists) {
      var lm = LandmarkDTO.fromJson(ds.data);
      _landmarks.add(lm);
      _setGeoFence(lm);
      print(
          ' 🔵 ## LANDMARK ::: ✅  #${lm.rankSequenceNumber}  ${lm.landmarkName} ');
    }

    _landmarks.sort(
        (ascii, b) => ascii.rankSequenceNumber.compareTo(b.rankSequenceNumber));
    _landmarksController.sink.add(_landmarks);
  }

  void _setGeoFence(LandmarkDTO landmark) async {
    print('+++ ℹ️ adding geofence for ${landmark.landmarkName}');
    bg.BackgroundGeolocation.addGeofence(Geofence(
        identifier: landmark.landmarkID,
        radius: 200.0,
        latitude: landmark.latitude,
        longitude: landmark.longitude,
        notifyOnDwell: true,
        notifyOnEntry: true,
        notifyOnExit: true));

    print('+++ ✅ +++ geofence added for ${landmark.landmarkName}');
  }

  void listenForCommuterMessages() {
    print('+++  🔵 starting message channel .......');
    try {
      _messagesSubscription =
          messageStream.receiveBroadcastStream().listen((message) {
        print('### - 🔵 - message received :: ${message.toString()}');
        print('### - 📍 - place arriving message on the stream');
        //todo check if this is from a commuter
        _nearbyMessagesController.sink.add(message.toString());
      });
    } on PlatformException {
      _messagesSubscription.cancel();
      print(
          'Things went south in a hurry, Jack!  ⚠️ ⚠️ Message listening not so hot ..');
    }
  }

  void signInAnonymously() async {
    print('📍 checking current user ..... 📍 ');
    var user = await auth.currentUser();

    if (user == null) {
      print('ℹ️ signing in ..... .......');
      user = await auth.signInAnonymously();
    } else {
      print('User already signed in: 🔵 🔵 🔵 ');
    }
  }

  void publishMessage() {
    print('+++ publishMessage ');
  }
}
