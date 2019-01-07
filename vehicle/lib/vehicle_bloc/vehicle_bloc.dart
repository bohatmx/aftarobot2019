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
import 'package:permission_handler/permission_handler.dart';

//✅  🎾 🔵  📍   ℹ️
class VehicleAppBloc {
  VehicleAppBloc() {
    print('+++ ℹ️ +++  ++++++++++++++++++ initializing Vehicle App Bloc');
    _setBackgroundLocation();
    _initialize();
  }

  FirebaseAuth auth = FirebaseAuth.instance;
  Firestore fs = Firestore.instance;

  static const geoQueryChannel = const MethodChannel('aftarobot/geoQuery');
  static const messageStream = const EventChannel('aftarobot/messages');
  static const LOITERING_DELAY = 30000; //dwell in milliseconds :: 30 seconds
  static const GEOFENCE_RADIUS = 200.0; //radius in metres
  static const GEO_QUERY_RADIUS = 20.0; //radius in KM

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
  StreamController<List<ARGeofenceEvent>> _arGeofenceController =
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

  VehicleDTO _appVehicle;
  VehicleDTO get appVehicle => _appVehicle;

  List<ARGeofenceEvent> _geofenceEvents = List();
  List<ARGeofenceEvent> get geofenceEvents => _geofenceEvents;

  get landmarksStream => _landmarksController.stream;
  get nearbyMessageStream => _nearbyMessagesController.stream;
  get locationStream => _locationController.stream;
  get associationStream => _assocController.stream;
  get vehicleStream => _vehicleController.stream;
  get geofenceEventStream => _arGeofenceController.stream;

  void closeStreams() {
    _landmarksController.close();
    _nearbyMessagesController.close();
    _locationController.close();
    _vehicleController.close();
    _assocController.close();
    _arGeofenceController.close();
  }

  Future setVehicleForApp(VehicleDTO vehicle) async {
    await Prefs.saveVehicle(vehicle);
    _appVehicle = vehicle;
    return null;
  }

  Future<VehicleDTO> getVehicleForApp() async {
    var v = await Prefs.getVehicle();
    _appVehicle = v;
    return v;
  }

  void _initialize() async {
    print('### initialise - 🔵 - check if vehicle has been saved in Prefs');
    _appVehicle = await getVehicleForApp();
    if (_appVehicle == null) {
      print('###  ℹ️ App has no vehicle set up yet');
      await getAssociations();
    } else {
      print('###   ℹ️ ℹ️ ℹ️ App has vehicle ${_appVehicle.vehicleReg} set up.');
      await signInAnonymously();
      getCurrentLocation();
    }
  }

  void _setBackgroundLocation() {
    // 1.  Listen to events (See docs for all 12 available events).
    bg.BackgroundGeolocation.onLocation(_onLocation);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChanged);
    bg.BackgroundGeolocation.onActivityChange(_onActivityChanged);
    bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    _setGeofencing();

    // 2.  Configure the plugin
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 10.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: true,
            geofenceProximityRadius: 5000,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            reset: true))
        .then((bg.State state) {
      print('## 📍 ODOMETER: ${state.odometer}');
      print('## 📍 📍 BackgroundGeolocation state :: ${state.toMap()} 📍 📍 ');
    });

    //bg.BackgroundGeolocation.start();
    //bg.BackgroundGeolocation.startGeofences();
    print('### ✅ background location set. will start tracking ...');
  }

  _setGeofencing() async {
    print('+++  🎾 setting up geofencing background listeners ...');
    bg.BackgroundGeolocation.onGeofence(_onGeofenceEvent);
    bg.BackgroundGeolocation.onGeofencesChange((changeEvent) {
      print('\n\n +++  🔵 List of ACTIVATED GEOFENCES');
      changeEvent.on.forEach((Geofence geofence) {
        //createGeofenceMarker(geofence)
        print('+++ 🔵  ${geofence.toMap()} extras: ${geofence.extras}');
      });

      // Remove map circles
      changeEvent.off.forEach((String identifier) {
        //removeGeofenceMarker(identifier);
        print('\n\n +++  ⚠️ List of DE- ACTIVATED GEOFENCES');
        print(' ⚠️ $identifier -- DE-ACTIVATED ----------');
      });
    });
  }

  _onGeofenceEvent(GeofenceEvent event) async {
    if (_appVehicle == null) {
      print('\n---  ⚠️ vehicle is null, geofence event will not be recorded');
      return null;
    }
    print('\n\n+++  🎾 add geofence event to Firestore');
    var name;
    _landmarks.forEach((m) {
      if (m.landmarkID == event.identifier) {
        name = m.landmarkName;
      }
    });
    var m = ARGeofenceEvent(
      vehicleID: _appVehicle.vehicleID,
      vehicleReg: _appVehicle.vehicleReg,
      make: _appVehicle.vehicleType.make + " " + _appVehicle.vehicleType.model,
      action: event.action,
      landmarkID: event.identifier,
      landmarkName: name,
      stringTimestamp: DateTime.now().toUtc().toIso8601String(),
      timestamp: event.location.timestamp,
      isMoving: event.location.isMoving,
      odometer: event.location.odometer,
      activityType: event.location.activity.type,
      confidence: event.location.activity.confidence,
    );

    await fs.collection('geofenceEvents').add(m.toJson());
    print(
        '+++ 🔵 +++ geofence event recorded for landmark: $name id: ${event.identifier} vehicle: ${_appVehicle.vehicleReg} action: ${m.action} at ${m.timestamp}');
    _geofenceEvents.add(m);
    _arGeofenceController.sink.add(_geofenceEvents);
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
//
//    print('### ℹ️ ℹ️ start searching for nearby landmarks, radius: $Radius');
//    searchForLandmarks(
//      latitude: _currentLocation.coords.latitude,
//      longitude: _currentLocation.coords.longitude,
//      radius: Radius,
//    );
  }

  _onProviderChange(ProviderChangeEvent event) {
    print('_onProviderChange --- ');
  }

  _writeVehicleLocationLog() async {
    print('### 📍📍 writing vehicle location log entry ......');
    if (_appVehicle == null) {
      print('#### vehicle is null. not tracking ....');
    } else {
      var log = VehicleLogDTO(
        date: DateTime.now().toUtc().millisecondsSinceEpoch,
        stringDate: DateTime.now().toUtc().toIso8601String(),
        latitude: _currentLocation.coords.latitude,
        longitude: _currentLocation.coords.longitude,
        vehicleID: _appVehicle.vehicleID,
        vehicle: _appVehicle,
        vehicleLogID: getKey(),
      );

      var ref = await fs
          .document(_appVehicle.path)
          .collection('vehicleLogs')
          .add(log.toJson());

      print('\n\n\n### 🔵 vehicle location log has been written to Firestore: '
          '${ref.path} vehicle: ${_appVehicle.vehicleReg}\n\n');

      _writeVehicleGeoLocation(
          _currentLocation.coords.latitude, _currentLocation.coords.longitude);
    }
  }

  MethodChannel vehicleLocationChannel =
      MethodChannel("aftarobot/vehicleLocation");

  bool isBusy = false;
  void _writeVehicleGeoLocation(double latitude, double longitude) async {
    if (isBusy) {
      print('⚠️⚠️⚠️⚠️⚠️ _writeVehicleGeoLocation is BUSY! ... quit.');
      return;
    }
    print(
        '\n\n+++  🔵 VehicleAppBloc: writeVehicleLocation over the channel to the WildSide .......');
    var map = {
      'latitude': latitude,
      'longitude': longitude,
      'vehicleID': _appVehicle.vehicleID,
    };
    var string = json.encode(map);
    print("⚠️... sending $string to WildSide for vehicle location recording");
    try {
      isBusy = true;

      final String result = await vehicleLocationChannel.invokeMethod(
          'writeVehicleLocation', string);
      print('+++ 🔵 vehicle location request response :: $result');
      isBusy = false;
      isSearchingForLandmarks = false;
      searchForLandmarks(
        latitude: latitude,
        longitude: longitude,
        radius: 5.0,
      );
    } on PlatformException catch (e) {
      print(
          'Things went south in a hurry, Jack!  ⚠️ ⚠️ Message listening not so hot ..');
      print(e);
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

  static Future<List<AssociationDTO>> getAssociationsFirstTime() async {
    Firestore fs = Firestore.instance;
    var qs = await fs
        .collection('associations')
        .orderBy('associationName')
        .getDocuments();
    List<AssociationDTO> list = List();
    qs.documents.forEach((doc) {
      var ass = AssociationDTO.fromJson(doc.data);
      list.add(ass);
    });
    print('###  - 🔵 - associations found : ${list.length}');
    return list;
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

  static Future<List<VehicleDTO>> getVehiclesFirstTime(String path) async {
    print('+++ getVehicles for association: $path');
    Firestore fsx = Firestore.instance;
    var qs = await fsx.document(path).collection('vehicles').getDocuments();

    List<VehicleDTO> list = List();
    qs.documents.forEach((doc) {
      var v = VehicleDTO.fromJson(doc.data);
      list.add(v);
    });

    print('###  - 🔵 - vehicles found: ${list.length} for association $path');
    return list;
  }

  void _calculateDistancesBetweenLandmarks() {}
  Future getCurrentLocation() async {
    print(
        '###  🎾 getCurrentLocation -- ............ and then search for landmarks ..............');
    //check location permission

    var isGood = await _checkPermission();
    if (isGood) {
      bg.Location location =
          await bg.BackgroundGeolocation.getCurrentPosition();
      _currentLocation = location;

      print('############# searchForLandmarks: Should this be done here??????');
      searchForLandmarks(
          latitude: _currentLocation.coords.latitude,
          longitude: _currentLocation.coords.longitude,
          radius: GEO_QUERY_RADIUS);
    }
  }

  Future<bool> _requestPermission() async {
    print('\n\n######################### requestPermission');
    try {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.location]);
      print(permissions);

      print("\n########### permission request for location is:  ✅ ");
      if (permissions.containsKey(PermissionGroup.location)) {
        if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
      }
      return false;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  Future<bool> _checkPermission() async {
    print('\n\n######################### checkPermission');
    try {
      PermissionStatus locationPermission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.location);

      if (locationPermission == PermissionStatus.denied) {
        return await _requestPermission();
      } else {
        print(
            "***************** location permission status is:  ✅  ✅ $locationPermission");
        return true;
      }
    } catch (e) {
      print(e);
      return false;
    }
  }

  bool isSearchingForLandmarks = false;
  void searchForLandmarks(
      {double latitude, double longitude, double radius}) async {
    if (isSearchingForLandmarks) {
      print(
          '########## ⚠️⚠️⚠️⚠️ ... isSearchingForLandmarks : $isSearchingForLandmarks, quit!');
      return;
    }
    print(
        '\n\n🔵  🔵  VehicleBloc: start geo query .... ........................');
    isSearchingForLandmarks = true;
    if (_currentLocation == null) {
      await getCurrentLocation();
    }
    if (_currentLocation == null) {
      print(
          '\n\n########## ⚠️⚠️⚠️⚠️ --- _currentLocation is NULL! What the Fuck????\n\n');
      throw Exception('_currentLocation is NULL! What the Fuck????');
    }
    if (latitude == null) {
      latitude = _currentLocation.coords.latitude;
      longitude = _currentLocation.coords.longitude;
    }
    if (radius == null) {
      radius = GEO_QUERY_RADIUS;
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
      isSearchingForLandmarks = false;
    } on PlatformException catch (e) {
      print('\nVehicleBloc: Why is the result coming back twice??????????? '
          '- will check for already located landmarks: ${_landmarks.length}');
      isSearchingForLandmarks = false;
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
    print('\n\n+++ ℹ️ℹ️ℹ️ℹ️ℹ️  adding geofence for ${landmark.landmarkName}');

    bg.BackgroundGeolocation.addGeofence(Geofence(
            identifier: landmark.landmarkID,
            radius: GEOFENCE_RADIUS,
            latitude: landmark.latitude,
            longitude: landmark.longitude,
            loiteringDelay: LOITERING_DELAY,
            extras: {
              'landmarkName': landmark.landmarkName,
              'associationName': landmark.associationName,
            },
            notifyOnDwell: true,
            notifyOnEntry: false,
            notifyOnExit: false))
        .then((ok) {
      print('+++ ℹ️ℹ️ℹ️ℹ️ℹ️ successfule geofence set up: $ok');
    });

    print('+++ ✅ +++ geofence added for ${landmark.landmarkName}');
  }

  void listenForCommuterMessages() {
    print('+++  🔵 starting commuter message channel .......');
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

  Future signInAnonymously() async {
    print('📍 checking current user ..... 📍 ');
    var user = await auth.currentUser();

    if (user == null) {
      print('ℹ️ signing in ..... .......');
      user = await auth.signInAnonymously();
      return null;
    } else {
      print('User already signed in: 🔵 🔵 🔵 ');
      return null;
    }
  }

  void publishMessage() {
    print('+++ publishMessage ');
  }

  static Future registerVehicleOnDevice(VehicleDTO v) async {
    print('### 📍📍--- registerVehicle ....... ${v.vehicleReg}');
    await Prefs.saveVehicle(v);
    print(
        '### 🔵 --- vehicle registered on device : ${v.vehicleReg} ... getting current location');
    return null;
  }
}
