import 'package:aftarobotlibrary/api/data_api.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datagenerator/generator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

abstract class RouteMigrationListener {
  onRouteAdded(RouteDTO route);
  onLandmarkAdded(LandmarkDTO landmark);
  onComplete();
}

abstract class AftaRobotMigrationListener {
  onAssociationAdded(AssociationDTO ass);
  onVehicleAdded(VehicleDTO car);
  onUserAdded(UserDTO user);
}

class AftaRobotMigration {
  static final FirebaseOptions options = FirebaseOptions(
      projectID: 'aftarobot-production',
      databaseURL: "https://aftarobot-production.firebaseio.com",
      storageBucket: "aftarobot-production.appspot.com",
      apiKey: 'AIzaSyC5-hoDv-8lveX0VQwp2-nNitkvNThjJ9o',
      googleAppID: 'aftarobot-production');

  static Firestore fs = Firestore.instance;
  static List<CountryDTO> countries;
  static Future<List<CountryDTO>> addCountries() async {
    List<CountryDTO> list = await DataAPI.addCountries();
    return list;
  }

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
  static List<VehicleDTO> vehicles = List();
  /*
    Migrates all the old AftaRobot data from Firebase Realtime DB to Firestore
   */
  static Future migrateOldAftaRobot(
      {AftaRobotMigrationListener listener,
      RouteMigrationListener routeMigrationListener}) async {
    print(
        '\n\n\n\nAftaRobotMigration.migrateOldAftaRobot ################### START MIGRATION !!!!');
    countries = await addCountries();

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
    CountryDTO za;
    countries.forEach((c) {
      if (c.name.contains('South Africa')) {
        za = c;
      }
    });

    for (var value in dataSnapshot2.value.values) {
      AssociationDTO ass = AssociationDTO.fromJson(value);
      if (ass.associationName.contains('Brits Taxi Association') ||
          ass.associationName.contains('Katlehong Peoples Taxi Association') ||
          ass.associationName.contains('Krugersdorp And District Taxi Union') ||
          ass.associationName
              .contains('Johannesburg Southern Suburbs Taxi Association') ||
          ass.associationName.contains('Inanda Taxi Owners Association')) {
        ass.countryID = za.countryID;
        ass.countryName = za.name;
        list.add(ass);
        cnt++;
        print(
            'RouteMigration.migrateOldAftaRobot ------- association #$cnt added to list');
      } else {
        print(
            'AftaRobotMigration.migrateOldAftaRobot IGNORING ${ass.associationName} - no Firestore for you!!');
      }
    }
    print(
        '\n\nRouteMigration.migrateOldAftaRobot, total associations: ${list.length} ****************');

    for (var ass in list) {
      await _processAss(ass, listener);
    }
    //get vehicles
    await _generateCarTypes();
    await _migrateCars(firebaseDatabase, listener);
    await _migrateUsers(firebaseDatabase, listener);
    var routes = await _getFilteredRoutes();
    await migrateRoutes(routes: routes, listener: routeMigrationListener);
  }

  static List<RouteDTO> routes = List();
  static Future<List<RouteDTO>> _getFilteredRoutes() async {
    var tempRoutes = await getOldRoutes();
    List<RouteDTO> filteredRoutes = List();
    tempRoutes.forEach((r) {
      asses.forEach((ass) {
        if (ass.associationID == r.associationID) {
          if (r.spatialInfos.length > 0) {
            filteredRoutes.add(r);
          }
        }
      });
    });
    routes = filteredRoutes;
    print(
        'AftaRobotMigration._getFilteredRoutes - filtered routes: ${filteredRoutes.length}');
    return filteredRoutes;
  }

  static Future _migrateCars(FirebaseDatabase firebaseDatabase,
      AftaRobotMigrationListener listener) async {
    //get vehicles
    List<VehicleDTO> cars = List();
    DataSnapshot dataSnapshot3 =
        await firebaseDatabase.reference().child('vehicles').once();
    for (var value in dataSnapshot3.value.values) {
      var veh = VehicleDTO.fromJson(value);
      //check if vehicle is from the associations we have
      bool isFound = false;
      asses.forEach((ass) {
        if (veh.associationID == ass.associationID) {
          isFound = true;
        }
      });
      if (isFound) {
        cars.add(veh);
      }
    }
    print('RouteMigration._migrateCars: ${cars.length} cars in list');
    for (var car in cars) {
      AssociationDTO ass;
      asses.forEach((a) {
        if (car.associationID == a.associationID) {
          ass = a;
        }
      });
      car.vehicleType = getQuantumType();
      await _processVehicle(listener: listener, ass: ass, car: car);
    }
    return null;
  }

  static VehicleTypeDTO getQuantumType() {
    VehicleTypeDTO type;
    vehicleTypes.forEach((t) {
      if (t.model.contains('Quantum')) {
        type = t;
      }
    });
    return type;
  }

  static Future<List<UserDTO>> _migrateUsers(FirebaseDatabase firebaseDatabase,
      AftaRobotMigrationListener listener) async {
    //get vehicles
    List<UserDTO> userList = List();
    DataSnapshot dataSnapshot3 =
        await firebaseDatabase.reference().child('users').once();
    for (var value in dataSnapshot3.value.values) {
      var user = UserDTO.fromJson(value);
      //check if user is from the associations we have
      bool isFound = false;
      asses.forEach((ass) {
        if (user.associationID == ass.associationID) {
          isFound = true;
        }
      });
      if (isFound) {
        userList.add(user);
      }
    }
    print('RouteMigration._migrateUsers: ${userList.length} users in list');
    for (var user in userList) {
      var mUser = await DataAPI.registerUser(user);
      users.add(mUser);
      listener.onUserAdded(mUser);
    }
    return userList;
  }

  static List<VehicleTypeDTO> vehicleTypes = List();
  static Future<List<VehicleTypeDTO>> _generateCarTypes() async {
    var t1 = VehicleTypeDTO(
        capacity: 16,
        make: 'Toyota',
        model: 'Quantum',
        vehicleTypeID: getKey());
    var t2 = VehicleTypeDTO(
        capacity: 16,
        make: 'Toyota',
        model: 'ses\'Fikile',
        vehicleTypeID: getKey());
    var t3 = VehicleTypeDTO(
        capacity: 20, make: 'Nissan', model: 'E20', vehicleTypeID: getKey());
    var t4 = VehicleTypeDTO(
        capacity: 16, make: 'Toyota', model: 'HiAce', vehicleTypeID: getKey());
    var t5 = VehicleTypeDTO(
        capacity: 16,
        make: 'Nissan',
        model: 'Impendulo',
        vehicleTypeID: getKey());

    try {
      var type1 = await DataAPI.addVehicleType(t1);
      vehicleTypes.add(type1);

      var type2 = await DataAPI.addVehicleType(t2);
      vehicleTypes.add(type2);

      var type3 = await DataAPI.addVehicleType(t3);
      vehicleTypes.add(type3);

      var type4 = await DataAPI.addVehicleType(t4);
      vehicleTypes.add(type4);

      var type5 = await DataAPI.addVehicleType(t5);
      vehicleTypes.add(type5);
    } catch (e) {
      print(e);
      throw e;
    }

    return vehicleTypes;
  }

  static List<UserDTO> users = List();
  static Future<VehicleDTO> _processVehicle(
      {VehicleDTO car,
      AssociationDTO ass,
      AftaRobotMigrationListener listener}) async {
    var veh = await DataAPI.addVehicle(car);
    print(
        'RouteMigration.processVehicle --------- added car ${veh.path} - ${veh.vehicleReg}');
    vehicles.add(veh);
    listener.onVehicleAdded(veh);
    return veh;
  }

  static Future<AssociationDTO> _processAss(
      AssociationDTO ass, AftaRobotMigrationListener listener) async {
    var mEmail = ass.associationName.replaceAll(" ", '.').toLowerCase().trim() +
        '@aftarobot.io';
    var res = await DataAPI.addAssociation(
        association: ass,
        adminUser: UserDTO(
            email: mEmail,
            password: 'pass123',
            cellphone: '+27719990000',
            countryID: ass.countryID,
            name: ass.associationName,
            userType: DataAPI.ASSOC_ADMIN,
            userDescription: DataAPI.ASSOC_ADMIN_DESC));
    print('AftaRobotMigration._processAss result: $res');
    asses.add(res);
    assCnt++;
    print(
        'RouteMigration.migrateAssociations - association added: #$assCnt ${res.associationName}');
    listener.onAssociationAdded(res);
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
      await _processRoute(route);

      if (route.spatialInfos.isNotEmpty) {
        for (var si in route.spatialInfos) {
          if (si.fromLandmark != null) {
            //write to landmark if it does not exist
            await _writeLandmark(si.fromLandmark);
          }
          if (si.fromLandmark != null) {
            //write to landmark if it does not exist
            await _writeLandmark(si.toLandmark);
          }
        }
      }
    }
    var end = DateTime.now();
    print(
        'RouteMigration.migrateRoutes -- COMPLETED, elapsed ${end.difference(start).inSeconds} seconds. '
        'processed $routeCount routes and $landmarkCount landmarks ');
    listener.onComplete();
    return 0;
  }

  static Future<RouteDTO> _processRoute(RouteDTO route) async {
    var mRoute = await DataAPI.addRoute(route);
    routeCount++;
    print(
        '\nRouteMigration.processRoute -- ++++++ route #$routeCount added to Firestore: ${mRoute.name}');
    migrationListener.onRouteAdded(mRoute);
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

  static Future<LandmarkDTO> _writeLandmark(LandmarkDTO m) async {
    var mark = await DataAPI.addLandmark(m);
    landmarkCount++;
    print(
        '\nRouteMigration.writeLandmark -- ++++++++++ landmark #$landmarkCount added to Firestore: ${mark.landmarkName}');
    landmarks.add(mark);
    migrationListener.onLandmarkAdded(mark);
    return mark;
  }

  static List<LandmarkDTO> landmarks = List();
}
