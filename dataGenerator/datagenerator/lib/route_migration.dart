import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

abstract class RouteMigrationListener {
  onRouteAdded(RouteDTO route);
  onLandmarkAdded(LandmarkDTO landmark);
  onComplete(int routes, int landmarks);
}

abstract class AssociationMigrationListener {
  onAssociationAdded(AssociationDTO ass);
  onVehicleAdded(VehicleDTO car);
}

/*
var config = {
    apiKey: "AIzaSyC5-hoDv-8lveX0VQwp2-nNitkvNThjJ9o",
    authDomain: "aftarobot-production.firebaseapp.com",
    databaseURL: "https://aftarobot-production.firebaseio.com",
    projectId: "aftarobot-production",
    storageBucket: "aftarobot-production.appspot.com",
    messagingSenderId: "158116619777"
  };
 */
class RouteMigration {
  static final FirebaseOptions options = FirebaseOptions(
      projectID: 'aftarobot-production',
      databaseURL: "https://aftarobot-production.firebaseio.com",
      storageBucket: "aftarobot-production.appspot.com",
      apiKey: 'AIzaSyC5-hoDv-8lveX0VQwp2-nNitkvNThjJ9o',
      googleAppID: 'aftarobot-production');

  static Firestore fs = Firestore.instance;
  static Future<List<RouteDTO>> getOldRoutes() async {
    print(
        'RouteMigration.getOldRoutes ++++ ###################### start databases ..........');

    final FirebaseApp app = await FirebaseApp.configure(
      name: 'oldAftaRobotProd',
      options: options,
    );
    assert(app != null);
    List<RouteDTO> list = List();
    FirebaseDatabase firebaseDatabase = FirebaseDatabase(app: app);

    DataSnapshot dataSnapshot2 =
        await firebaseDatabase.reference().child('routes').once();

    int cnt = 0;
    for (var value in dataSnapshot2.value.values) {
      RouteDTO route = RouteDTO.fromJson(value);
      list.add(route);
      cnt++;
      print('RouteMigration.getOldRoutes ------- route #$cnt added to list');
    }
    print(
        '\n\nRouteMigration.getOldRoutes, total routes: ${list.length} ****************');
    return list;
  }

  static int assCnt = 0;
  static List<AssociationDTO> asses = List();
  static Future migrateAssociations(
      AssociationMigrationListener listener) async {
    //assocs, users,vehicles, routes
    final FirebaseApp app = await FirebaseApp.configure(
      name: 'oldAftaRobotProd',
      options: options,
    );
    assert(app != null);
    List<AssociationDTO> list = List();
    FirebaseDatabase firebaseDatabase = FirebaseDatabase(app: app);

    DataSnapshot dataSnapshot2 =
        await firebaseDatabase.reference().child('associations').once();

    int cnt = 0;

    for (var value in dataSnapshot2.value.values) {
      AssociationDTO ass = AssociationDTO.fromJson(value);
      ass.countryID = '45fcec60-e440-11e8-920a-0b3f720a7372';
      list.add(ass);
      cnt++;
      print(
          'RouteMigration.migrateAssociations ------- association #$cnt added to list');
    }
    print(
        '\n\nRouteMigration.migrateAssociations, total associations: ${list.length} ****************');

    for (var ass in list) {
      await processAss(ass, listener);
    }
    //get vehicles
    List<VehicleDTO> cars = List();
    DataSnapshot dataSnapshot3 =
        await firebaseDatabase.reference().child('vehicles').once();
    for (var value in dataSnapshot3.value.values) {
      cars.add(VehicleDTO.fromJson(value));
    }
    print('RouteMigration.migrateAssociations: ${asses.length} asses in list');
    for (var car in cars) {
      if (car.associationID == null) {
        print(
            'RouteMigration.migrateAssociations -- car is FUCKED. no associationID ${car.toJson()}');
      } else {
        AssociationDTO ass;
        asses.forEach((a) {
          if (car.associationID == a.associationID) {
            ass = a;
          }
        });
        if (ass == null) {
          print(
              '\n\nRouteMigration.migrateAssociations ERROR ERROR - association not found fo car ${car.toJson()}');
          //throw Exception('Association in asses is NULL. Fuck!');
        } else {
          if (ass.path == null) {
            print(
                '\n\nRouteMigration.migrateAssociations -- ERROR ERROR - ass path is NULL! wtf?');
          } else {
            await processVehicle(listener: listener, ass: ass, car: car);
          }
        }
      }
    }
  }

  static Future<VehicleDTO> processVehicle(
      {VehicleDTO car,
      AssociationDTO ass,
      AssociationMigrationListener listener}) async {
    var qs = await fs
        .document(ass.path)
        .collection('vehicles')
        .where('vehicleReg', isEqualTo: car.vehicleReg)
        .getDocuments();
    if (qs.documents.isNotEmpty) {
      print('RouteMigration.processVehicle ------ car exists already');
      var v = VehicleDTO.fromJson(qs.documents.first.data);
      listener.onVehicleAdded(v);
      return v;
    }
    var mRef =
        await fs.document(ass.path).collection('vehicles').add(car.toJson());
    car.path = mRef.path;
    await mRef.setData(car.toJson());
    print(
        'RouteMigration.processVehicle --------- added car ${car.path} ${car.vehicleReg}');
    listener.onVehicleAdded(car);
    return car;
  }

  static Future<AssociationDTO> processAss(
      AssociationDTO ass, AssociationMigrationListener listener) async {
    var qs = await fs
        .collection('associations')
        .where('associationName', isEqualTo: ass.associationName)
        .getDocuments();
    if (qs.documents.isNotEmpty) {
      print('RouteMigration.processAss ------- assoc already exists');
      var m = AssociationDTO.fromJson(qs.documents.first.data);
      asses.add(m);
      listener.onAssociationAdded(m);
      return m;
    }
    var ref = await fs.collection('associations').add(ass.toJson());
    ass.path = ref.path;
    ref.setData(ass.toJson());
    assCnt++;
    asses.add(ass);
    print(
        'RouteMigration.migrateAssociations - association added: #$assCnt ${ass.associationName}');
    listener.onAssociationAdded(ass);
    return ass;
  }

  static int landmarkCount = 0, routeCount = 0;
  static RouteMigrationListener migrationListener;
  static Future migrateRoutes(
      {List<RouteDTO> routes, RouteMigrationListener listener}) async {
    print(
        '\nRouteMigration.migrateRoutes ############# migrating ${routes.length} routes to Firestore');
    migrationListener = listener;
    var start = DateTime.now();
    for (var route in routes) {
      await processRoute(route);

      if (route.spatialInfos.isNotEmpty) {
        for (var si in route.spatialInfos) {
          if (si.fromLandmark != null) {
            //write to landmark if it does not exist
            await processLandmark(si.fromLandmark);
          }
          if (si.fromLandmark != null) {
            //write to landmark if it does not exist
            await processLandmark(si.toLandmark);
          }
        }
      }
    }
    var end = DateTime.now();
    print(
        'RouteMigration.migrateRoutes -- COMPLETED, elapsed ${end.difference(start).inSeconds} seconds. '
        'processed $routeCount routes and $landmarkCount landmarks ');
    listener.onComplete(routeCount, landmarkCount);
    return 0;
  }

  static Future<RouteDTO> processRoute(RouteDTO route) async {
    var querySnap = await fs
        .collection('routes')
        .where('name', isEqualTo: route.name)
        .where('associationID', isEqualTo: route.associationID)
        .getDocuments();
    if (querySnap.documents.isNotEmpty) {
      print('\n\nRouteMigration.processRoute - route exists: ${route.name}');
      var m = RouteDTO.fromJson(querySnap.documents.first.data);
      migrationListener.onRouteAdded(m);
      return m;
    }
    var ref = await fs.collection('routes').add(route.toJson());
    route.path = ref.path;
    await ref.setData(route.toJson());

    routeCount++;
    print(
        '\nRouteMigration.processRoute -- ++++++ route #$routeCount added to Firestore: ${route.name}');
    migrationListener.onRouteAdded(route);
    return route;
  }

  static Future primeQueriesToGetIndexingLink(
      {LandmarkDTO landmark, RouteDTO route}) async {
    assert(landmark != null && route != null);
    try {
      await fs
          .collection('landmarks')
          .where('latitude', isEqualTo: landmark.latitude)
          .where('longitude', isEqualTo: landmark.longitude)
          .getDocuments();
      print(
          'RouteMigration.primeQueriesToGetIndexingLink ............ landmarks');
    } catch (e) {
      print(e);
    }

    try {
      await fs
          .collection('routes')
          .where('name', isEqualTo: route.name)
          .where('associationID', isEqualTo: route.associationID)
          .getDocuments();
      print('RouteMigration.primeQueriesToGetIndexingLink ............ routes');
      print('RouteMigration.primeQueriesToGetIndexingLink ............ done!');
    } catch (e) {
      print(e);
    }

    return 0;
  }

  static Future<bool> processLandmark(LandmarkDTO landmark) async {
    var querySnap = await fs
        .collection('landmarks')
        .where('latitude', isEqualTo: landmark.latitude)
        .where('longitude', isEqualTo: landmark.longitude)
        .getDocuments();
    if (querySnap.documents.isNotEmpty) {
      print(
          '\nRouteMigration.processLandmark - landmark exists: ${landmark.landmarkName}');
      var m = LandmarkDTO.fromJson(querySnap.documents.first.data);
      migrationListener.onLandmarkAdded(m);
      return false;
    }
    return await writeLandmark(landmark);
  }

  static Future<bool> writeLandmark(LandmarkDTO m) async {
    await fs.collection('landmarks').add(m.toJson());
    landmarkCount++;
    print(
        '\nRouteMigration.writeLandmark -- ++++++++++ landmark #$landmarkCount added to Firestore: ${m.landmarkName}');
    migrationListener.onLandmarkAdded(m);
    return true;
  }
}
