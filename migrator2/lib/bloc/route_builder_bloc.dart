import 'dart:async';

import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/api/list_api.dart';
import 'package:aftarobotlibrary/data/association_bag.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/geofence_event.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/maps/snap_to_roads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:meta/meta.dart';

class RouteBuilderModel {
  List<RouteDTO> _routes = List();
  List<LandmarkDTO> _landmarks = List();
  List<ARLocation> _arLocations = List();
  List<ARGeofenceEvent> _geofenceEvents = List();
  List<AssociationDTO> _associations = List();
  List<AssociationBag> _associationBags = List();
  ARLocation _currentLocation;

  List<RouteDTO> get routes => _routes;
  List<LandmarkDTO> get landmarks => _landmarks;
  List<ARLocation> get arLocations => _arLocations;
  List<AssociationDTO> get associations => _associations;
  List<AssociationBag> get associationBags => _associationBags;
  List<ARGeofenceEvent> get geofenceEvents => _geofenceEvents;
  ARLocation get currentLocation => _currentLocation;

  Future initialize() async {
    print('### ℹ️  ℹ️  ℹ️  RouteBuilderBloc initializing');
    return null;
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
  final RouteBuilderModel _appModel = RouteBuilderModel();
  final Firestore fs = Firestore.instance;
  RouteBuilderBloc() {
    print('\n\n\n### ℹ️  ℹ️  ℹ️  RouteBuilderBloc initializing ...');
    _start();
  }
  _start() async {
    await _appModel.initialize();
    await getAssociationBags();
    print('\n\n############ adding model to stream sink ...');
  }

  RouteBuilderModel get model => _appModel;
  closeStream() {
    _appModelController.close();
    _errorController.close();
  }

  get stream => _appModelController.stream;

  getAssociationBags() async {
    print('### ℹ️  getAssociationBags getting bags ..........');
    var bags = await ListAPI.getAssociationBags();
    _appModel.associationBags.addAll(bags);
    _appModelController.sink.add(_appModel);
    print('++++ ✅  association bags retrieved ${bags.length}');
  }

  addRoutePoint(ARLocation location) async {
    print('#### ℹ️ ℹ️  processing route point. adding utc date');
    location.date = DateTime.now().toUtc().toIso8601String();
    location.uid = getKey();
    try {
      await LocalDB.saveARLocation(location: location);
      var ref = await fs
          .collection('rawRoutePoints')
          .document(location.routeID)
          .collection('points')
          .add(location.toJson());

      print(
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

  addGeofenceEvent(ARGeofenceEvent event) async {
    print('#### ℹ️ ℹ️  processing route point. adding utc date');
    //event.timestamp = DateTime.now().toUtc().toIso8601String();
    try {
      var ref = await fs
          .collection('geofenceEvents')
          .document(event.landmarkID)
          .collection('points')
          .add(event.toJson());

      print(
          '#### ℹ️ ℹ️  geoefenceEvent location written to Firestore: ${ref.path} 📍 add to stream sink');
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
    getGPSLocation(route);

    if (timer == null) {
      timer = Timer.periodic(Duration(seconds: collectionSeconds), (mt) {
        print(
            "%%%%%%%% ⚠️  timer triggered for 10 seconds :: - get GPS location and save");
        getGPSLocation(route);
      });
    } else {}
  }

  ARLocation prevLocation;
  Future getGPSLocation(RouteDTO route) async {
    print(
        '_LocationCollectorState ############# getLocation starting ..............');
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
    prettyPrint(arLoc.toJson(), 'ARLocation format ....  ⚠️   ⚠️   ⚠️   ⚠️  ');
    assert(arLoc.latitude != null);
    if (prevLocation != null) {
      if (arLoc.latitude == prevLocation.latitude &&
          arLoc.longitude == prevLocation.longitude) {
        print('########## 📍  DUPLICATE location .... ignored ');
      } else {
        addRoutePoint(arLoc);
      }
    } else {
      addRoutePoint(arLoc);
    }
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
