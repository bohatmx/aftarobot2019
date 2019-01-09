import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/api/sharedprefs.dart';
import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/geofence_event.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/vehicle_location.dart';
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

//✅  🎾 🔵  📍  ℹ️
class VehicleAppBloc {
  VehicleAppBloc() {
    printLog('+++ ℹ️ +++  ++++++++++++++++++ initializing Vehicle App Bloc');
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
  static const VEHICLE_SEARCH_MINUTES = 5; //radius in KM

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
  StreamController<List<VehicleLocation>> _vehicleLocationController =
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

  List<VehicleLocation> _vehicleLocations = List();
  List<VehicleLocation> get vehicleLocations => _vehicleLocations;

  get landmarksStream => _landmarksController.stream;
  get nearbyMessageStream => _nearbyMessagesController.stream;
  get locationStream => _locationController.stream;
  get associationStream => _assocController.stream;
  get vehicleStream => _vehicleController.stream;
  get geofenceEventStream => _arGeofenceController.stream;
  get vehicleLocationStream => _vehicleLocationController.stream;

  void closeStreams() {
    _landmarksController.close();
    _nearbyMessagesController.close();
    _locationController.close();
    _vehicleController.close();
    _assocController.close();
    _arGeofenceController.close();
    _vehicleLocationController.close();
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
    printLog(
        '\n### initialise - 🔵 - check if vehicle has been saved in Prefs\n');
    _appVehicle = await getVehicleForApp();
    if (_appVehicle == null) {
      printLog('###  ℹ️ App has no vehicle set up yet');
      await getAssociations();
    } else {
      printLog(
          '\n###   ℹ️ ℹ️ ℹ️ App has vehicle ${_appVehicle.vehicleReg} set up. Cool! Ready to Rumble !!  🔵 \n\n');
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
    bg.BackgroundGeolocation.onSchedule(_onVehicleLogSchedule);
    _setGeofencing();

    // 2.  Configure the plugin
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 10.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: true,
            geofenceProximityRadius: 5000,
            schedule: [
              '1-7 4:00-22:00', // Sun-Sat: 4:00am to 10:00pm
            ],
            logLevel: bg.Config.LOG_LEVEL_ERROR,
            reset: true))
        .then((bg.State state) {
      //not doing nuthin ...
    });

    printLog('### ✅ background location set. will start tracking ...\n');
  }

  _onVehicleLogSchedule(bg.State state) async {
    if (state.enabled) {
      printLog(
          '\n\n\n[onSchedule] 🔵 🔵 🔵 vehicle log scheduled. get location and add log to Firestore\n');
      BackgroundGeolocation.getCurrentPosition().then((loc) {
        _currentLocation = loc;
        _locationController.sink.add(_currentLocation);
        _writeVehicleLocationLog();
      });
    } else {
      printLog('\n\n[onSchedule]  🎾 scheduled stop tracking');
    }
  }

  _setGeofencing() async {
    printLog('+++ 🎾 setting up geofencing background listeners ...\n');

    bg.BackgroundGeolocation.onGeofence(_onGeofenceEvent);

    bg.BackgroundGeolocation.onGeofencesChange((changeEvent) {
      printLog('\n\n+++ ✅ ✅ ✅  List of ACTIVATED GEOFENCES\n\n');
      changeEvent.on.forEach((Geofence geofence) {
        //createGeofenceMarker(geofence)
        printLog('+++ 🔵  ${geofence.identifier}');
      });
      printLog("\n\n");

      printLog('\n\n⚠️ List of DE- ACTIVATED GEOFENCES\n\n');
      changeEvent.off.forEach((String identifier) {
        printLog('⚠️ $identifier ::  DE-ACTIVATED --');
      });
    });
  }

  _onGeofenceEvent(GeofenceEvent event) async {
    if (_appVehicle == null) {
      printLog(
          '\n---  ⚠️ vehicle is null, geofence event will not be recorded');
      return null;
    }
    printLog('\n\n+++  🎾 add geofence event to Firestore');
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

    LandmarkDTO landmark;
    _landmarks.forEach((m) {
      if (event.identifier == m.landmarkID) {
        landmark = m;
      }
    });
    //write geofence event to landmark
    await fs
        .document(landmark.path)
        .collection('geofenceEvents')
        .add(m.toJson());
    printLog(
        '+++ 🔵 +++ geofence event recorded for landmark: $name id: ${event.identifier} vehicle: ${_appVehicle.vehicleReg} action: ${m.action} at ${m.timestamp}');
    _geofenceEvents.add(m);
    _arGeofenceController.sink.add(_geofenceEvents);
  }

  _onMotionChanged(bg.Location location) {
    printLog('&&&&&&&&&&&&&  ℹ️ onMotionChanged: location ${location.toMap()}');
    _currentLocation = location;
    _locationController.sink.add(location);
  }

  _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    printLog(
        '+++++++++++++++ _onConnectivityChange connected: ${event.connected}');
  }

  _onActivityChanged(bg.ActivityChangeEvent event) {
    printLog('#############  ℹ️ _onActivityChanged: ${event.toMap()}');
  }

  _onLocation(bg.Location location) {
    if (location.isMoving) {
      printLog(
          '\n\n\n✅ ✅ ✅ ✅  -- onLocation:  VEHICLE IS MOVING? ${location.isMoving}  ✅ ✅ ✅ ✅\n\n');
    } else {
      printLog('\n\n🎾  -- onLocation:  vehicle is stationary?\n');
    }

    //printLog('${location.toMap()}');

    _currentLocation = location;
    _locationController.sink.add(location);
    _writeVehicleLocationLog();
  }

  _onProviderChange(ProviderChangeEvent event) {
    printLog('_onProviderChange --- ');
  }

  _writeVehicleLocationLog() async {
    printLog('\n\n\n### 📍📍 writing vehicle location log entry ......');
    if (_appVehicle == null) {
      printLog('#### vehicle is null. not tracking ....');
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

      printLog('### 🔵 vehicle location log has been written to Firestore: '
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
      printLog(
          '\n\n⚠️⚠️⚠️⚠️⚠️ _writeVehicleGeoLocation is BUSY! ... quit.\n\n');
      return;
    }
    printLog(
        '\n\n+++  🔵 VehicleAppBloc: writeVehicleLocation over the channel to the WildSide .......');
    var map = {
      'latitude': latitude,
      'longitude': longitude,
      'vehiclePath': _appVehicle.path,
    };
    var string = json.encode(map);
//    printLog(
//        "⚠️... sending $string to WildSide for vehicle location recording");
    try {
      isBusy = true;
      final String result = await vehicleLocationChannel.invokeMethod(
          'writeVehicleLocation', string);
      printLog('+++ 🔵 vehicle location request response :: $result');
      isBusy = false;
      isSearchingForLandmarks = false;
      searchForLandmarks(
        latitude: latitude,
        longitude: longitude,
        radius: GEO_QUERY_RADIUS,
      );
    } on PlatformException catch (e) {
      printLog(
          '\n\nThings went south in a hurry, Jack!  ⚠️ ⚠️ vehicleLocationChannel listening not so hot ..');
      printLog(e.toString());
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
    printLog('###  - 🔵 - associations found : ${_associations.length}');
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
    printLog('###  - 🔵 - associations found : ${list.length}');
    return list;
  }

  Future<List<VehicleDTO>> getVehicles(String path) async {
    printLog('+++ getVehicles for association: $path');

    var qs = await fs.document(path).collection('vehicles').getDocuments();

    _vehicles.clear();
    qs.documents.forEach((doc) {
      var v = VehicleDTO.fromJson(doc.data);
      _vehicles.add(v);
    });

    _vehicleController.sink.add(_vehicles);
    printLog(
        '###  - 🔵 - vehicles found: ${_vehicles.length} for association $path');
    return _vehicles;
  }

  static Future<List<VehicleDTO>> getVehiclesFirstTime(String path) async {
    printLog('+++ getVehicles for association: $path');
    Firestore fsx = Firestore.instance;
    var qs = await fsx.document(path).collection('vehicles').getDocuments();

    List<VehicleDTO> list = List();
    qs.documents.forEach((doc) {
      var v = VehicleDTO.fromJson(doc.data);
      list.add(v);
    });

    printLog(
        '###  - 🔵 - vehicles found: ${list.length} for association $path');
    return list;
  }

  void _calculateDistancesBetweenLandmarks() {}
  Future getCurrentLocation() async {
    printLog(
        '###  🎾 getCurrentLocation -- ............ and then search for landmarks ..............');
    //check location permission

    var isGood = await _checkPermission();
    if (isGood) {
      bg.Location location =
          await bg.BackgroundGeolocation.getCurrentPosition();
      _currentLocation = location;

      printLog(
          '############# searchForLandmarks: Should this be done here??????');
      searchForLandmarks(
          latitude: _currentLocation.coords.latitude,
          longitude: _currentLocation.coords.longitude,
          radius: GEO_QUERY_RADIUS);
    }
  }

  Future<bool> _requestPermission() async {
    printLog('\n\n######################### requestPermission');
    try {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.location]);
      printLog(permissions.toString());

      printLog("\n########### permission request for location is:  ✅ ");
      if (permissions.containsKey(PermissionGroup.location)) {
        if (permissions[PermissionGroup.location] == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
      }
      return false;
    } catch (e) {
      printLog(e);
      throw e;
    }
  }

  Future<bool> _checkPermission() async {
    printLog('\n\n######################### checkPermission');
    try {
      PermissionStatus locationPermission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.location);

      if (locationPermission == PermissionStatus.denied) {
        return await _requestPermission();
      } else {
        printLog(
            "***************** location permission status is:  ✅  ✅ $locationPermission");
        return true;
      }
    } catch (e) {
      printLog(e);
      return false;
    }
  }

  bool isSearchingForVehicleLocations = false;
  MethodChannel vehicleSearchChannel =
      MethodChannel('aftarobot/findVehicleLocations');

  Future searchForVehiclesAroundUs(
      {double latitude, double longitude, double radius, int minutes}) async {
    if (isSearchingForVehicleLocations) {
      printLog(
          '\nsearchForVehiclesAroundUs ⚠️ ⚠️ we are still busy .... sorry!');
      return null;
    }
    bg.Location location = await bg.BackgroundGeolocation.getCurrentPosition();
    _currentLocation = location;

    if (latitude == null || longitude == null) {
      await getCurrentLocation();
      latitude = _currentLocation.coords.latitude;
      longitude = _currentLocation.coords.longitude;
    }
    if (radius == null) {
      radius = GEO_QUERY_RADIUS;
    }
    if (minutes == null) {
      minutes = VEHICLE_SEARCH_MINUTES;
    }
    isSearchingForVehicleLocations = true;
    var searchRequest = {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'minutes': minutes
    };
    //use method channel to find vehicles around us ----
    printLog(
        '\n###  ⚠️ ⚠️ Find vehicles around us. Limit by time ...$minutes minutes.');
    try {
      var result = await vehicleSearchChannel.invokeMethod(
          'findVehicleLocations', json.encode(searchRequest));
      List<dynamic> mList = json.decode(result);
      _vehicleLocations.clear();
      mList.forEach((map) {
        var vl = VehicleLocation.fromJson(map);
        _vehicleLocations.add(vl);
      });
      _vehicleLocationController.sink.add(_vehicleLocations);
      printLog(
          '\n\n🔵 🔵 🔵 VEHICLES FOUND AROUND US: ${_vehicleLocations.length}\n');
      printLog(result);
      isSearchingForVehicleLocations = false;
    } on PlatformException catch (e) {
      isSearchingForVehicleLocations = false;
      printLog(e.toString());
    }
  }

  bool isSearchingForLandmarks = false;
  void searchForLandmarks(
      {double latitude, double longitude, double radius}) async {
    if (isSearchingForLandmarks) {
      printLog(
          '########## ⚠️⚠️⚠️⚠️ ... isSearchingForLandmarks : $isSearchingForLandmarks, quit!');
      return;
    }
    printLog(
        '\n\n🔵  🔵  VehicleBloc: start geo query .... ........................');
    isSearchingForLandmarks = true;
    if (_currentLocation == null) {
      await getCurrentLocation();
    }
    if (_currentLocation == null) {
      printLog(
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
      printLog('\n\nVehicleBloc: Result back from geoQuery ....  ✅ ');

      List<dynamic> list = json.decode(result);
      printLog('. ✅ ... number of searched geoPoints returned: ${list.length}');

      list.forEach((t) {
        if (t is Map) {
          t.forEach((key, value) {
            _getLocatedLandmark(key);
          });
        }
      });
      printLog("\n");
      bg.BackgroundGeolocation.startGeofences();
      isSearchingForLandmarks = false;
    } on PlatformException catch (e) {
      printLog('\nVehicleBloc: Why is the result coming back twice??????????? '
          '- will check for already located landmarks: ${_landmarks.length}');
      isSearchingForLandmarks = false;
      printLog(e.toString());
      throw Exception(e);
    }
  }

  Future _getLocatedLandmark(String id) async {
    DocumentSnapshot ds = await fs.collection('landmarks').document(id).get();
    if (ds.exists) {
      var lm = LandmarkDTO.fromJson(ds.data);
      _landmarks.add(lm);
      _addLandmarkGeoFence(lm);
    }

    _landmarks.sort(
        (ascii, b) => ascii.rankSequenceNumber.compareTo(b.rankSequenceNumber));
    _landmarksController.sink.add(_landmarks);
  }

  void _addLandmarkGeoFence(LandmarkDTO landmark) async {
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
      printLog(
          '+++ ℹ️ℹ️ℹ️ℹ️ℹ️ successful geofence set up: $ok :: ${landmark.landmarkID} - ${landmark.landmarkName}');
    });

    printLog(
        ' 🔵 ## LANDMARK GEOFENCE  ::: ✅  #${landmark.rankSequenceNumber}  ${landmark.landmarkName} is being set up ...');
  }

  void listenForCommuterMessages() {
    printLog('+++  🔵 starting commuter message channel .......');
    try {
      _messagesSubscription =
          messageStream.receiveBroadcastStream().listen((message) {
        printLog('### - 🔵 - message received :: ${message.toString()}');
        printLog('### - 📍 - place arriving message on the stream');
        //todo check if this is from a commuter
        _nearbyMessagesController.sink.add(message.toString());
      });
    } on PlatformException {
      _messagesSubscription.cancel();
      printLog(
          'Things went south in a hurry, Jack!  ⚠️ ⚠️ Message listening not so hot ..');
    }
  }

  Future signInAnonymously() async {
    printLog('📍 checking current user ..... 📍 ');
    var user = await auth.currentUser();
    if (user == null) {
      printLog('ℹ️ ############### signing in ..... .......');
      user = await auth.signInAnonymously();
      return null;
    } else {
      printLog('############## User already signed in: 🔵 🔵 🔵 ');
      return null;
    }
  }

  void publishMessage() {
    printLog('+++ publishMessage ');
  }

  static Future registerVehicleOnDevice(VehicleDTO v) async {
    printLog('### 📍📍--- registerVehicle ....... ${v.vehicleReg}');
    await Prefs.saveVehicle(v);
    printLog(
        '### 🔵 --- vehicle registered on device : ${v.vehicleReg} ... getting current location');
    return null;
  }
}
