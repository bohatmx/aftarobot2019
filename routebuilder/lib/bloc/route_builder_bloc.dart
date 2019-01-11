import 'dart:async';

import 'package:aftarobotlibrary3/api/file_util.dart';
import 'package:aftarobotlibrary3/api/list_api.dart';
import 'package:aftarobotlibrary3/data/association_bag.dart';
import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/geofence_event.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/maps/snap_to_roads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart';
import 'package:meta/meta.dart';
import 'package:permission_handler/permission_handler.dart';

class RouteBuilderModel {
  List<RouteDTO> _routes = List();
  List<LandmarkDTO> _landmarks = List();
  List<ARLocation> _arLocations = List();
  List<ARLocation> _routePoints = List();
  List<VehicleGeofenceEvent> _geofenceEvents = List();
  List<AssociationDTO> _associations = List();
  List<AssociationBag> _associationBags = List();
  ARLocation _currentLocation;

  List<RouteDTO> get routes => _routes;
  List<LandmarkDTO> get landmarks => _landmarks;
  List<ARLocation> get arLocations => _arLocations;
  List<ARLocation> get routePoints => _routePoints;
  List<AssociationDTO> get associations => _associations;
  List<AssociationBag> get associationBags => _associationBags;
  List<VehicleGeofenceEvent> get geofenceEvents => _geofenceEvents;
  ARLocation get currentLocation => _currentLocation;

  void receiveRoutePoints(List<ARLocation> routePoints) {
    _routePoints = routePoints;
  }
}

/*
This class manages thd app's business logic and connects the model to a stream
*/
class RouteBuilderBloc {
  final StreamController<RouteBuilderModel> _appModelController =
      StreamController<RouteBuilderModel>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();
  final StreamController<bg.Location> _currentLocationController =
      StreamController<bg.Location>.broadcast();
  final StreamController<bg.GeofenceEvent> _geofenceEventController =
      StreamController<bg.GeofenceEvent>.broadcast();

  List<GeofenceEvent> _geofenceEvents = List();

  final RouteBuilderModel _appModel = RouteBuilderModel();
  final Firestore fs = Firestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bg.Location _currentLocation;
  bg.Location get currentLocation => _currentLocation;
  RouteBuilderModel get model => _appModel;
  closeStream() {
    _appModelController.close();
    _errorController.close();
    _currentLocationController.close();
    _geofenceEventController.close();
  }

  get appModelStream => _appModelController.stream;
  get currentLocationStream => _currentLocationController.stream;
  get geofenceEventStream => _geofenceEventController.stream;

  RouteBuilderBloc() {
    printLog('\n\n\n 🔵  🔵  🔵  🔵  🔵 RouteBuilderBloc initializing ...');
    _initialize();
  }
  static const GEOFENCE_PROXIMITY_RADIUS = 5000, DISTANCE_FILTER = 10.0;
  _initialize() async {
    await _signIn();
    _setBackgroundLocation();

    await getRoutes();
    await getLandmarks();
  }

  Future _signIn() async {
    //todo - to be replaced by proper authentication
    printLog(
        '\n### ℹ️ sign in anonymously ...(to be replaced by real auth code)');
    var user = await _auth.currentUser();
    if (user == null) {
      await _auth.signInAnonymously();
    } else {
      printLog(' ✅ User already authenticated');
    }
    return null;
  }

  Future<bool> requestPermission() async {
    print('\n\n######################### requestPermission');
    try {
      Map<PermissionGroup, PermissionStatus> permissions =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.location]);
      print(permissions);
      permissions.values.forEach((perm) {
        printLog('check for perm:: Permission status: $perm');
      });
      print("\n########### permission request for location is:  ✅ ");
      return true;
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> checkPermission() async {
    print('\n\n######################### checkPermission');
    try {
      PermissionStatus locationPermission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.location);

      if (locationPermission == PermissionStatus.denied) {
        return false;
      } else {
        print(
            "***************** location permission status is:  ✅  ✅ $locationPermission");
        return true;
      }
    } catch (e) {
      print(e);
      throw e;
    }
    return false;
  }

  void _setBackgroundLocation() {
    printLog('📍 setting background location config\n');
    bg.BackgroundGeolocation.onLocation(_onLocation);
    bg.BackgroundGeolocation.onMotionChange(_onMotionChanged);
    bg.BackgroundGeolocation.onActivityChange(_onActivityChanged);
    bg.BackgroundGeolocation.onProviderChange(_onProviderChange);
    bg.BackgroundGeolocation.onConnectivityChange(_onConnectivityChange);
    _setGeofencing();

    // 2.  Configure the plugin
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: DISTANCE_FILTER,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: true,
            geofenceProximityRadius: GEOFENCE_PROXIMITY_RADIUS,
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
    printLog('\n\n+++  🎾 process geofence event');
    _geofenceEvents.add(event);
    _geofenceEventController.sink.add(event);
  }

  _onMotionChanged(bg.Location location) {
    printLog('&&&&&&&&&&&&&  ℹ️ onMotionChanged: location ${location.toMap()}');
    _currentLocation = location;
    _currentLocationController.sink.add(location);
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
          '\n\n\n✅ ✅   -- onLocation:  VEHICLE IS MOVING? ${location.isMoving}   ✅ ✅\n\n');
    } else {
      printLog('\n\n🎾  -- onLocation:  vehicle is stationary?\n');
    }
    _currentLocation = location;
    _currentLocationController.sink.add(location);
  }

  _onProviderChange(ProviderChangeEvent event) {
    printLog('_onProviderChange --- ');
  }

  Future getRoutes() async {
    printLog('### ℹ️  getRoutes: getting ALL routes in Firestore ..........\n');
    var routes = await ListAPI.getRoutes();

    printLog(' 📍 adding model with routes to model and stream sink ...');
    _appModel.routes.clear();
    _appModel.routes.addAll(routes);
    _appModelController.sink.add(_appModel);
    printLog('++++ ✅  routes retrieved: ${routes.length}\n');
    return _appModel.routes;
  }

  Future getLandmarks() async {
    printLog(
        '### ℹ️  getLandmarks: getting ALL landmarks in Firestore ..........\n');
    var marks = await ListAPI.getLandmarks();

    printLog(' 📍 adding model with landmarks to model and stream sink ...');
    _appModel.landmarks.clear();
    _appModel.landmarks.addAll(marks);
    _appModelController.sink.add(_appModel);
    printLog('++++ ✅  landmarks retrieved: ${marks.length}\n');
    return _appModel.landmarks;
  }

  getRoutePoints({String routeID}) async {
    printLog('### ℹ️  getRoutePoints getting route points ..........');
    var qs = await fs
        .collection('rawRoutePoints')
        .document(routeID)
        .collection('points')
        .getDocuments();
    qs.documents.forEach((doc) {
      var point = ARLocation.fromJson(doc.data);
      _appModel.arLocations.add(point);
    });
    _appModelController.sink.add(_appModel);
  }

  Future<int> addRoutePoints({List<ARLocation> points, RouteDTO route}) async {
    printLog(
        '#### ℹ️ ℹ️  - adding collected points to route: ${route.name} - ${route.associationName}');

    var start = DateTime.now();
    int count = 0;
    try {
      for (var point in points) {
        point.date = DateTime.now().toUtc().toIso8601String();
        var ref = await fs
            .collection('routePoints')
            .document(route.routeID)
            .collection('points')
            .add(point.toJson());
        count++;
        printLog(
            '#### ℹ️ ℹ️  route point written to Firestore: ${ref.path} 📍 #$count added');
      }

      _appModel.receiveRoutePoints(points);
      _appModelController.sink.add(_appModel);
      var end = DateTime.now();
      printLog(
          '\n#### ✅ ✅ ✅   ${points.length} route points written to Firestore for ${route.name}'
          ' -  📍 elapsed time: ${end.difference(start).inSeconds} seconds.');
      return 0;
    } catch (e) {
      print('⚠️ ⚠️ ⚠️  $e');
      throw e;
    }
  }

  addRawRoutePoint(ARLocation location) async {
    printLog('#### ℹ️ ℹ️  processing route point. adding utc date');
    location.date = DateTime.now().toUtc().toIso8601String();
    location.uid = getKey();
    try {
      await LocalDB.saveARLocation(location: location);
      var ref = await fs
          .collection('rawRoutePoints')
          .document(location.routeID)
          .collection('points')
          .add(location.toJson());

      printLog(
          '#### ℹ️ ℹ️  collected AR location written to Firestore: ${ref.path} 📍 add to stream sink');
      _appModel.arLocations.add(location);
      _appModelController.sink.add(_appModel);
    } catch (e) {
      print('⚠️ ⚠️ ⚠️  $e');
    }
  }

  deleteRoutePoint(ARLocation location) async {
    print('#### ️️ ⚠️ deleting route point');
    try {
      await LocalDB.deleteARLocations();
      var ref = await fs
          .collection('rawRoutePoints')
          .document(location.routeID)
          .collection('points')
          .where('uid', isEqualTo: location.uid)
          .getDocuments()
          .then((data) {
        if (data.documents.isNotEmpty) {
          data.documents.first.reference.delete();
          print(
              '#### ⚠️  collected AR location deleted from Firestore: 📍 tell stream sink');
          _appModel.arLocations.remove(location);
          _appModelController.sink.add(_appModel);
        }
      });
    } catch (e) {
      print('⚠️ ⚠️ ⚠️  $e');
      throw e;
    }
  }

  deleteRoutePoints({String routeID}) async {
    print('#### ️️ ⚠️ deleting ALL route points at $routeID');
    try {
      await LocalDB.deleteARLocations();
      await fs.collection('rawRoutePoints').document(routeID).delete();
      print(
          '#### ⚠️  collected AR locations deleted from Firestore: 📍 tell stream sink');
      _appModel.arLocations.clear();
      _appModelController.sink.add(_appModel);
    } catch (e) {
      print('⚠️ ⚠️ ⚠️  $e');
    }
  }

  addGeofenceEvent(VehicleGeofenceEvent event) async {
    printLog('#### ℹ️ ℹ️  adding geofence event');
    try {
      var ref = await fs
          .collection('geofenceEvents')
          .document(event.landmarkID)
          .collection('points')
          .add(event.toJson());

      printLog(
          '#### ℹ️  ✅  geoefenceEvent location written to Firestore: ${ref.path} 📍 add to stream sink');
      _appModel.geofenceEvents.add(event);
      _appModelController.sink.add(_appModel);
    } catch (e) {
      print('⚠️ ⚠️ ⚠️  $e');
    }
  }

  Timer timer;
  int timerDuration = 10;

  startRoutePointCollectionTimer(
      {@required RouteDTO route, @required int collectionSeconds}) {
    collectRawRoutePoint(route);

    timer = Timer.periodic(Duration(seconds: collectionSeconds), (mt) {
      printLog(
          "⚠️  timer triggered for $collectionSeconds seconds :: - get GPS location and save");
      collectRawRoutePoint(route);
    });
  }

  ARLocation prevLocation;
  Future collectRawRoutePoint(RouteDTO route) async {
    printLog(
        'getGPSLocation ############# getLocation starting ..............');
    var c = await bg.BackgroundGeolocation.getCurrentPosition();
    var arLoc = ARLocation(
      routeID: route == null ? null : route.routeID,
      latitude: c.coords.latitude,
      longitude: c.coords.longitude,
      accuracy: c.coords.accuracy,
      activity:
          Activity(confidence: c.activity.confidence, type: c.activity.type),
      battery:
          Battery(level: c.battery.level, isCharging: c.battery.isCharging),
      altitude: c.coords.altitude,
      date: DateTime.now().toUtc().toIso8601String(),
      heading: c.coords.heading,
      isMoving: c.isMoving,
      odometer: c.odometer,
      speed: c.coords.speed,
      uid: c.uuid,
    );

    assert(arLoc.latitude != null);
    if (prevLocation != null) {
      if (arLoc.latitude == prevLocation.latitude &&
          arLoc.longitude == prevLocation.longitude) {
        print('########## 📍  📍 DUPLICATE location .... ignored ');
      } else {
        addRawRoutePoint(arLoc);
      }
    } else {
      addRawRoutePoint(arLoc);
    }
    prevLocation = arLoc;
    return c;
  }

  stopRoutePointCollectionTimer() {
    if (timer == null) {
      print('---------- timer is null. ⚠️  ---- quit.');
      return;
    } else {
      print("### ⚠️  ⚠️  ⚠️   - cancelling timer");
      timer.cancel();
      timer = null;
    }
  }
}

final routeBuilderBloc = RouteBuilderBloc();
