import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/data/geofence_event.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/vehicle_location.dart';
import 'package:aftarobotlibrary3/util/distance.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart';
import 'package:permission_handler/permission_handler.dart';

class CommuterBloc {
  static const GEO_QUERY_RADIUS = 5.0;
  static const LOITERING_DELAY = 30000; //dwell in milliseconds :: 30 seconds
  static const GEOFENCE_RADIUS = 200.0; //radius in metres
  static const VEHICLE_SEARCH_MINUTES = 5;
  StreamSubscription _messagesSubscription;
  static const messageStream = const EventChannel('aftarobot/messages');
  Firestore fs = Firestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  StreamController<List<LandmarkDTO>> _landmarkStreamController =
      StreamController<List<LandmarkDTO>>();
  StreamController<List<VehicleGeofenceEvent>>
      _vehicleGeofenceStreamController =
      StreamController<List<VehicleGeofenceEvent>>();
  StreamController<List<CommuterGeofenceEvent>>
      _commuterGeofenceStreamController =
      StreamController<List<CommuterGeofenceEvent>>();
  StreamController<List<VehicleLocation>> _vehiclesStreamController =
      StreamController<List<VehicleLocation>>();
  StreamController<String> _nearbyMessagesController =
      StreamController.broadcast();

  List<LandmarkDTO> _landmarks = List();
  List<LandmarkDTO> get landmarks => _landmarks;

  List<VehicleLocation> _vehicleLocations = List();
  List<VehicleLocation> get vehicleLocations => _vehicleLocations;

  List<VehicleGeofenceEvent> _vehicleGeofenceEvents = List();
  List<VehicleGeofenceEvent> get vehicleGeofenceEvents =>
      _vehicleGeofenceEvents;

  List<CommuterGeofenceEvent> _commuterGeofenceEvents = List();
  List<CommuterGeofenceEvent> get commuterGeofenceEvents =>
      _commuterGeofenceEvents;

  bg.Location _currentLocation;
  bg.Location get currentLocation => _currentLocation;

  MethodChannel vehicleLocationChannel =
      MethodChannel("aftarobot/findVehicleLocations");

  MethodChannel geoQueryChannel = MethodChannel("aftarobot/geoQuery");

  closeStreams() {
    _landmarkStreamController.close();
    _vehicleGeofenceStreamController.close();
    _vehiclesStreamController.close();
    _nearbyMessagesController.close();
    _commuterGeofenceStreamController.close();
  }

  get landmarksStream => _landmarkStreamController.stream;
  get nearbyMessageStream => _nearbyMessagesController.stream;
  get vehicleLocationStream => vehicleLocationStream.stream;
  get commuterGeofencesStream => _commuterGeofenceStreamController.stream;
  get vehicleGeofenceStream => _vehicleGeofenceStreamController.stream;

  CommuterBloc() {
    printLog(
        '\n\n🔵 🔵 🔵 🔵 .............. initializing CommuterBloc !! 🔴 🔴 🔴 🔴 \n\n');
    _initialize();
  }

  _initialize() async {
    var user = await auth.currentUser();
    if (user == null) {
      await auth.signInAnonymously();
    }
    printLog('🔵  user signed in ...  checking location permission 🔴 ');
    var ok = await _checkPermission();
    if (!ok) {
      ok = await _requestPermission();
      if (!ok) {
        throw Exception('Unable to continue without location permission');
      }
    }

    printLog(
        '✅ ✅ User authentication and location permission OK. Ready to Rumble!!');

    await getCurrentLocation();
    _setGeofencing();
    return user;
  }

  _setGeofencing() async {
    printLog('\n+++ 🎾 setting up geofencing background listeners ...\n');

    bg.BackgroundGeolocation.onGeofence(_onGeofenceEvent);
    bg.BackgroundGeolocation.onActivityChange(_onActivityChanged);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChanged);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    //todo - check frequency of location trigger - use judiciously
    bg.BackgroundGeolocation.onLocation(_onLocation);

    bg.BackgroundGeolocation.onGeofencesChange((changeEvent) {
      printLog('\n\n+++ ✅   List of ACTIVATED GEOFENCES\n\n');
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
    printLog('\n\n+++ 🎾 add geofence event to Firestore');
    var name;
    _landmarks.forEach((m) {
      if (m.landmarkID == event.identifier) {
        name = m.landmarkName;
      }
    });
    var m = CommuterGeofenceEvent(
      action: event.action,
      landmarkID: event.identifier,
      landmarkName: name,
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
    //write geofence event to landmark node
    await fs
        .document(landmark.path)
        .collection('commuterGeofenceEvents')
        .add(m.toJson());

    //write to top node
    await fs.collection('commuterGeofenceEvents').add(m.toJson());
    printLog(
        '+++ 🔵 geofence event recorded for commuter at landmark: $name id: ${event.identifier} action: ${m.action} at ${m.timestamp}');
    _commuterGeofenceEvents.add(m);
    _commuterGeofenceStreamController.sink.add(_commuterGeofenceEvents);
  }

  _onMotionChanged(bg.Location location) {
    printLog('🔴 ℹ️ onMotionChanged: location ${location.toMap()}');
    _currentLocation = location;
  }

  _onConnectivityChange(bg.ConnectivityChangeEvent event) {
    printLog(
        '+++++++++++++++ _onConnectivityChange connected: ${event.connected}');
  }

  _onActivityChanged(bg.ActivityChangeEvent event) {
    printLog('🔴 ℹ️ _onActivityChanged: ${event.toMap()}');
    if (event.activity == 'moving' && event.confidence > .8) {
      //todo - check for vehicle app via nearby messaging ... write commuterInVehicle
    }
  }

  _onLocation(bg.Location location) {
    if (location.isMoving) {
      printLog(
          '\n\n\n✅ ✅  -- onLocation:  Commuter IS IN VEHICLE and MOVING? ${location.isMoving}  ✅ ✅ \n\n');
      //todo - check for vehicle app via nearby messaging ...
      listenForTaxiMessages();
    } else {
      printLog('\n\n🎾  -- onLocation:  commuter is stationary?\n');
    }

    _currentLocation = location;
  }

  Future<bool> _requestPermission() async {
    printLog('\n\n🎾 ########## requestPermission');
    try {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.location]);
      printLog(permissions.toString());

      printLog("🎾 ########### permission request for location is:  ✅ ");
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
    printLog('\n\n🎾  ######################### checkPermission');
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

  Future<bg.Location> getCurrentLocation() async {
    _currentLocation = await bg.BackgroundGeolocation.getCurrentPosition();
    searchForLandmarks();
    //searchForVehiclesAroundUs();
    return _currentLocation;
  }

  bool isSearchingForVehicleLocations = false;
  Future<List<VehicleLocation>> searchForVehiclesAroundUs(
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
        '\n\n###  ⚠️ ⚠️ Find vehicles around us. Limit by time ...$minutes minutes.\n\n');
    try {
      var result = await vehicleLocationChannel.invokeMethod(
          'findVehicleLocations', json.encode(searchRequest));
      List<dynamic> mList = json.decode(result);
      _vehicleLocations.clear();
      mList.forEach((map) {
        var vl = VehicleLocation.fromJson(map);
        _vehicleLocations.add(vl);
      });
      _vehiclesStreamController.sink.add(_vehicleLocations);
      printLog(
          '\n\n🔵 🔵 🔵 VEHICLES FOUND AROUND US: ${_vehicleLocations.length}\n');
      printLog(result);
      isSearchingForVehicleLocations = false;
      return _vehicleLocations;
    } on PlatformException catch (e) {
      isSearchingForVehicleLocations = false;
      printLog(e.toString());
    }
    return _vehicleLocations;
  }

  bool isSearchingForLandmarks = false;
  Future<List<LandmarkDTO>> searchForLandmarks(
      {double latitude, double longitude, double radius}) async {
    if (isSearchingForLandmarks) {
      printLog(
          '########## ⚠️⚠️⚠️⚠️ ... isSearchingForLandmarks : $isSearchingForLandmarks, quit!');
      return _landmarks;
    }
    printLog(
        '\n\n🔵  🔵  VehicleBloc: start geo query .... ........................');
    isSearchingForLandmarks = true;
    if (_currentLocation == null) {
      await getCurrentLocation();
    }
    if (_currentLocation == null) {
      printLog(
          '\n\n########## ⚠️⚠️⚠️⚠️ --- _currentLocation is NULL! WTF????\n\n');
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
      printLog('\n\n🔴 CommuterBloc: Result back from geoQuery ....  ✅ ');

      List<dynamic> list = json.decode(result);
      printLog('. ✅ ... number of searched geoPoints returned: ${list.length}');

      List<String> ids = List();
      list.forEach((t) {
        if (t is Map) {
          t.forEach((key, value) {
            ids.add(key);
          });
        }
      });

      for (var id in ids) {
        await _getLocatedLandmark(id);
      }
      bg.BackgroundGeolocation.startGeofences();
      isSearchingForLandmarks = false;
      print(
          '########################## _landmarks :: ${_landmarks.length} - should be sorted');

      return _landmarks;
    } on PlatformException catch (e) {
      printLog('\nWhy is the result coming back twice??????????? '
          '- will check for already located landmarks: ${_landmarks.length}');
      isSearchingForLandmarks = false;
      printLog(e.toString());
      throw Exception(e);
    }
  }

  Future<List<LandmarkDTO>> getRouteLandmarks({String routeID}) async {
    List<LandmarkDTO> list = List();
    var qs = await fs
        .collection('landmarks')
        .where('routeID', isEqualTo: routeID)
        .getDocuments();
    qs.documents.forEach((doc) {
      var mark = LandmarkDTO.fromJson(doc.data);
      list.add(mark);
    });

    return list;
  }

  Future _getLocatedLandmark(String id) async {
    DocumentSnapshot ds = await fs.collection('landmarks').document(id).get();
    if (ds.exists) {
      var lm = LandmarkDTO.fromJson(ds.data);
      _landmarks.add(lm);
      await calculateAndSortByDistance(
          landmarks: _landmarks,
          latitude: _currentLocation.coords.latitude,
          longitude: _currentLocation.coords.longitude);
      _landmarkStreamController.sink.add(_landmarks);
      _addLandmarkGeoFence(lm);
    }
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

//    printLog(
//        ' 🔵 ## LANDMARK GEOFENCE  ::: ✅  #${landmark.rankSequenceNumber}  ${landmark.landmarkName} is being set up ...');
  }

  void listenForTaxiMessages() {
    printLog('+++  🔵 starting commuter message channel .......');
    try {
      _messagesSubscription =
          messageStream.receiveBroadcastStream().listen((message) {
        printLog('### - 🔵 - message received :: ${message.toString()}');
        printLog('### - 📍 - place arriving message on the stream');
        //todo check if this is from a taxi
        _nearbyMessagesController.sink.add(message.toString());
        _writeCommuterInVehicle();
      });
    } on PlatformException {
      _messagesSubscription.cancel();
      printLog(
          'Things went south in a hurry, Jack!  ⚠️ ⚠️ Message listening not so hot ..');
    }
  }

  Future _writeCommuterInVehicle() async {
    printLog(
        '🎾 _writeCommuterInVehicle :: commuter is moving !!! find vehicle via nearby messaging ....');
  }
}
