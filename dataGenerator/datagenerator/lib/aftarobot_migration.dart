import 'dart:math';

import 'package:aftarobotlibrary/api/data_api.dart';
import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/api/list_api.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datagenerator/generator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/*
  The Migrator, all Powerful, all Seeing!
 */
abstract class AftaRobotMigrationListener {
  onAssociationAdded(AssociationDTO ass);
  onVehicleAdded(VehicleDTO car);
  onVehicleTypeAdded(VehicleTypeDTO car);
  onUserAdded(UserDTO user);
  onCountriesAdded(List<CountryDTO> countries);
  onRouteAdded(RouteDTO route);
  onLandmarkAdded(LandmarkDTO landmark);
  onComplete();
  onGenericMessage(String message);
  onDuplicateRecord(String message);
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
    countries = await DataAPI.addCountries();

    await LocalDB.saveCountries(Countries(countries));
    print('AftaRobotMigration.addCountries - ${countries.length} added');
    return countries;
  }

  static Future<List<RouteDTO>> getOldRoutes() async {
    print(
        'AftaRobotMigrationdex.getOldRoutes ++++ ###################### start databases ..........');

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
      print(
          'AftaRobotMigrationdex.getOldRoutes ------- route #$cnt added to list');
    }
    print(
        '\n\nAftaRobotMigrationdex.getOldRoutes, total routes: ${list.length} ****************');
    return list;
  }

  static int assCnt = 0;
  static List<AssociationDTO> asses = List();
  static List<VehicleDTO> vehicles = List();
  /*
    Migrates all the old AftaRobot data from Firebase Realtime DB to Firestore
   */
  static Future<FirebaseDatabase> _getDatabase() async {
    final FirebaseApp app = await FirebaseApp.configure(
      name: 'oldAftaRobotProd',
      options: options,
    );
    assert(app != null);
    List<AssociationDTO> list = List();
    FirebaseDatabase firebaseDatabase = FirebaseDatabase(app: app);
    return firebaseDatabase;
  }

  static Future migrateOldAftaRobot(
      {AftaRobotMigrationListener listener}) async {
    print(
        '\n\n\n\nAftaRobotMigration.migrateOldAftaRobot ################### START MIGRATION !!!!');
    migrationListener = listener;
    migrationListener.onGenericMessage('AftaRobot data migration started ...');
    countries = await addCountries();
    listener.onCountriesAdded(countries);

    List<AssociationDTO> list = List();
    FirebaseDatabase firebaseDatabase = await _getDatabase();

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
            '\nAftaRobotMigrationdex.migrateOldAftaRobot ------- association #$cnt ${ass.associationName} added to processing list');
      } else {
        print(
            '\nAftaRobotMigration.migrateOldAftaRobot IGNORING ${ass.associationName} - no Firestore for you!!');
      }
    }
    print(
        '\n\nAftaRobotMigrationdex.migrateOldAftaRobot, total associations: ${list.length} ****************');

    for (var ass in list) {
      await _writeAss(ass);
    }
    //get vehicles
    await _generateCarTypes(za);
    await migrateCars();
    await migrateUsers();
    var routes = await _getFilteredRoutes();
    await migrateRoutes(routes: routes);
    listener
        .onGenericMessage('Old AftaRobot data migration complete. Happy now?');
    listener.onComplete();
    return null;
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

  static Future migrateCars({AftaRobotMigrationListener listener}) async {
    //get vehicles
    var firebaseDatabase = await _getDatabase();
    if (asses.isEmpty) {
      asses = await ListAPI.getAssociations();
      vehicleTypes = await ListAPI.getVehicleTypes();
      print(
          'AftaRobotMigration.migrateCars @@@@@@@@@ asses: ${asses.length} vehicleTypes: ${vehicleTypes.length}');
    }
    if (listener != null) {
      migrationListener = listener;
    }
    List<VehicleDTO> cars = List();
    DataSnapshot dataSnapshot3 =
        await firebaseDatabase.reference().child('vehicles').once();
    for (var value in dataSnapshot3.value.values) {
      var veh = VehicleDTO.fromJson(value);
      veh.vehicleID = getKey();
      //check if vehicle is from the associations we have

      bool isFound = false;
      asses.forEach((ass) {
        if (veh.associationID == ass.associationID) {
          veh.associationName = ass.associationName;
          veh.assocPath = ass.path;
          veh.countryID = ass.countryID;
          isFound = true;
        }
      });
      if (isFound) {
        cars.add(veh);
      }
    }
    print('AftaRobotMigrationdex._migrateCars: ${cars.length} cars in list');
    for (var car in cars) {
      AssociationDTO ass;
      asses.forEach((a) {
        if (car.associationID == a.associationID) {
          ass = a;
        }
      });

      car.vehicleType = _getRandomVehicleType();
      assert(car.vehicleType != null);
      await _writeVehicle(ass: ass, car: car);
    }
    migrationListener.onGenericMessage('All vehicles migrated: ${cars.length}');
    if (listener != null) {
      migrationListener.onComplete();
    }
    return null;
  }

  static VehicleTypeDTO _getRandomVehicleType() {
    assert(vehicleTypes.isNotEmpty);
    print('AftaRobotMigration._getRandomVehicleType');
    List<VehicleTypeDTO> list = List();
    VehicleTypeDTO type;
    try {
      vehicleTypes.forEach((t) {
        if (t.model.contains('Quantum')) {
          for (var i = 0; i < 20; i++) {
            list.add(t);
          }
        } else {
          list.add(t);
          list.add(t);
        }
      });
      list.shuffle();
      var index = rand.nextInt(list.length - 1);
      print(
          'AftaRobotMigration._getRandomVehicleType index $index list: ${list.length}');
      type = list.elementAt(index);
      return type;
    } catch (e) {
      print(e);
    }
    assert(type != null);
    prettyPrint(type.toJson(), '############ TYPE:');
    return type;
  }

  static Future<List<UserDTO>> migrateUsers(
      {AftaRobotMigrationListener listener}) async {
    //get vehicles
    FirebaseDatabase firebaseDatabase = await _getDatabase();
    if (listener != null) {
      migrationListener = listener;
    }
    if (asses.isEmpty) {
      asses = await ListAPI.getAssociations();
    }
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
        _checkEmailPassword(user);
        userList.add(user);
      }
    }
    print(
        'AftaRobotMigrationdex._migrateUsers: ${userList.length} users in list');
    for (var user in userList) {
      var mUser = await DataAPI.registerUser(user);
      if (mUser == null) {
        print(
            'AftaRobotMigration._migrateUsers DUPLICATE USER ${user.toJson()}');
        migrationListener.onDuplicateRecord('Duplicate ${user.toJson()}');
      } else {
        users.add(mUser);
        migrationListener.onUserAdded(mUser);
        await LocalDB.saveUser(mUser);
        print(
            'AftaRobotMigration._migrateUsers saved ${mUser.name} in local DB');
      }
    }
    migrationListener.onGenericMessage('All users migrated: ${users.length}');
    if (listener != null) {
      listener.onComplete();
    }
    return userList;
  }

  static _checkEmailPassword(UserDTO user) {
    if (isInDebugMode) {
      if (user.password == null) {
        user.password = 'pass123\$M';
      }
      if (user.password.length < 7) {
        user.password = 'pass123\$M';
      }
      var email = user.name.toLowerCase().replaceAll(' ', '') +
          rand.nextInt(99999).toString() +
          '@aftarobot.io';
      user.email = email;
    }
  }

  static List<VehicleTypeDTO> vehicleTypes = List();
  static Future<List<VehicleTypeDTO>> _generateCarTypes(
      CountryDTO country) async {
    var t1 = VehicleTypeDTO(
        capacity: 16,
        make: 'Toyota',
        model: 'Quantum',
        countryID: country.countryID,
        vehicleTypeID: getKey());
    var t2 = VehicleTypeDTO(
        capacity: 16,
        make: 'Toyota',
        model: 'ses\'Fikile',
        countryID: country.countryID,
        vehicleTypeID: getKey());
    var t3 = VehicleTypeDTO(
      capacity: 20,
      make: 'Nissan',
      model: 'E20',
      vehicleTypeID: getKey(),
      countryID: country.countryID,
    );
    var t4 = VehicleTypeDTO(
      capacity: 16,
      make: 'Toyota',
      model: 'HiAce',
      vehicleTypeID: getKey(),
      countryID: country.countryID,
    );
    var t5 = VehicleTypeDTO(
        capacity: 16,
        make: 'Nissan',
        model: 'Impendulo',
        countryID: country.countryID,
        vehicleTypeID: getKey());
    var t6 = VehicleTypeDTO(
        capacity: 16,
        make: 'Hyundai',
        model: 'H-1',
        countryID: country.countryID,
        vehicleTypeID: getKey());
    var t7 = VehicleTypeDTO(
        capacity: 16,
        make: 'Mercedes Benz',
        model: 'Vito',
        countryID: country.countryID,
        vehicleTypeID: getKey());
    var t8 = VehicleTypeDTO(
        capacity: 16,
        make: 'Volkswagen',
        model: 'Transporter',
        countryID: country.countryID,
        vehicleTypeID: getKey());
    var t9 = VehicleTypeDTO(
        capacity: 16,
        make: 'Volkswagen',
        model: 'Caravelle',
        countryID: country.countryID,
        vehicleTypeID: getKey());
    var t10 = VehicleTypeDTO(
        capacity: 16,
        make: 'Ford',
        model: 'Tourneo Custom',
        countryID: country.countryID,
        vehicleTypeID: getKey());
    try {
      var type1 = await DataAPI.addVehicleType(t1);
      vehicleTypes.add(type1);
      migrationListener.onVehicleTypeAdded(type1);

      var type2 = await DataAPI.addVehicleType(t2);
      vehicleTypes.add(type2);
      migrationListener.onVehicleTypeAdded(type2);

      var type3 = await DataAPI.addVehicleType(t3);
      vehicleTypes.add(type3);
      migrationListener.onVehicleTypeAdded(type3);

      var type4 = await DataAPI.addVehicleType(t4);
      vehicleTypes.add(type4);
      migrationListener.onVehicleTypeAdded(type4);

      var type5 = await DataAPI.addVehicleType(t5);
      vehicleTypes.add(type5);
      migrationListener.onVehicleTypeAdded(type5);

      var type6 = await DataAPI.addVehicleType(t6);
      vehicleTypes.add(type6);
      migrationListener.onVehicleTypeAdded(type6);

      var type7 = await DataAPI.addVehicleType(t7);
      vehicleTypes.add(type7);
      migrationListener.onVehicleTypeAdded(type7);

      var type8 = await DataAPI.addVehicleType(t8);
      vehicleTypes.add(type8);
      migrationListener.onVehicleTypeAdded(type8);

      var type9 = await DataAPI.addVehicleType(t9);
      vehicleTypes.add(type9);
      migrationListener.onVehicleTypeAdded(type9);

      var type10 = await DataAPI.addVehicleType(t10);
      vehicleTypes.add(type10);
      migrationListener.onVehicleTypeAdded(type10);

      await LocalDB.saveVehicleTypes(VehicleTypes(vehicleTypes));
      print(
          'AftaRobotMigration._generateCarTypes saved im LocalDB ${vehicleTypes.length}');
      migrationListener.onGenericMessage('All vehicle types loaded');
    } catch (e) {
      print(e);
      throw e;
    }

    return vehicleTypes;
  }

  static List<UserDTO> users = List();
  static Future<VehicleDTO> _writeVehicle(
      {VehicleDTO car, AssociationDTO ass}) async {
    assert(car.vehicleType != null);
    assert(ass != null);
    var veh = await DataAPI.addVehicle(car);
    if (veh == null) {
      print(
          'AftaRobotMigration._writeVehicle -- DUPLICATE VEHICLE ${car.toJson()}');
      migrationListener.onDuplicateRecord(
          'Duplicate ${car.vehicleReg} ${car.vehicleType.make} ${car.vehicleType.model}');
      return null;
    }
    print(
        'AftaRobotMigrationdex._writeVehicle --------- added car ${veh.path} - ${veh.vehicleReg}');
    vehicles.add(veh);
    migrationListener.onVehicleAdded(veh);
    await LocalDB.saveVehicle(car);
    print(
        'AftaRobotMigration._writeVehicle -- saved ${car.vehicleReg} in local cache');
    return veh;
  }

  Random random = Random();
  static Future<AssociationDTO> _writeAss(AssociationDTO ass) async {
    var mEmail = ass.associationName.replaceAll(" ", '.').toLowerCase().trim() +
        rand.nextInt(99999).toString() +
        '@aftarobot.io';
    var myAss = await DataAPI.addAssociation(
        association: ass,
        adminUser: UserDTO(
            email: mEmail,
            password: 'pass123',
            cellphone: _getRandomPhone(),
            countryID: ass.countryID,
            name: ass.associationName,
            userType: DataAPI.ASSOC_ADMIN,
            userDescription: DataAPI.ASSOC_ADMIN_DESC));
    if (myAss == null) {
      print(
          'AftaRobotMigration._writeVehicle -- DUPLICATE ASS ${ass.toJson()}');
      migrationListener
          .onDuplicateRecord('Duplicate ${ass.associationName} ${ass.path} ');
      return null;
    }
    print('AftaRobotMigration._processAss result: $myAss');
    asses.add(myAss);
    assCnt++;
    print(
        'AftaRobotMigrationdex.migrateAssociations - association added: #$assCnt ${myAss.associationName}');
    migrationListener.onAssociationAdded(myAss);
    await LocalDB.saveAssociation(ass);
    print(
        'AftaRobotMigration._writeAss -- saved ${ass.associationName} in local cache');
    return ass;
  }

  static String _getRandomPhone() {
    String p1 = '+27';
    var p3 = numbers.elementAt(rand.nextInt(numbers.length - 1));
    var p4 = numbers.elementAt(rand.nextInt(numbers.length - 1));

    var p5 = numbers.elementAt(rand.nextInt(numbers.length - 1));
    var p6 = numbers.elementAt(rand.nextInt(numbers.length - 1));
    var p7 = numbers.elementAt(rand.nextInt(numbers.length - 1));

    var p8 = numbers.elementAt(rand.nextInt(numbers.length - 1));
    var p9 = numbers.elementAt(rand.nextInt(numbers.length - 1));
    var p10 = numbers.elementAt(rand.nextInt(numbers.length - 1));
    var p11 = numbers.elementAt(rand.nextInt(numbers.length - 1));

    var x = p1 + p3 + p4 + p5 + p6 + p7 + p8 + p9 + p10 + p11;
    print('_getRandomPhone ################ $x');
    return x;
  }

  static int landmarkCount = 0, routeCount = 0;
  static AftaRobotMigrationListener migrationListener;
  static Future migrateRoutes(
      {List<RouteDTO> routes, AftaRobotMigrationListener mListener}) async {
    print(
        '\nAftaRobotMigrationdex.migrateRoutes ############# migrating ${routes.length} routes to Firestore');
    if (mListener != null) {
      migrationListener = mListener;
    }
    var start = DateTime.now();
    for (var route in routes) {
      await _writeRoute(route);

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
        'AftaRobotMigrationdex.migrateRoutes -- COMPLETED, elapsed ${end.difference(start).inSeconds} seconds. '
        'processed $routeCount routes and $landmarkCount landmarks ');
    migrationListener.onGenericMessage('All routes migrated: ${routes.length}');
    if (mListener != null) {
      mListener.onComplete();
    }
    return 0;
  }

  static Future<RouteDTO> _writeRoute(RouteDTO route) async {
    var mRoute = await DataAPI.addRoute(route);
    if (mRoute == null) {
      print(
          'AftaRobotMigration._writeRoute -- DUPLICATE ROUTE ${route.toJson()}');
      migrationListener
          .onDuplicateRecord('Duplicate: ${route.name} ${route.path}');
      return null;
    }
    routeCount++;
    print(
        '\nAftaRobotMigrationdex.processRoute -- ++++++ route #$routeCount added to Firestore: ${mRoute.name}');
    migrationListener.onRouteAdded(mRoute);
    await LocalDB.saveRoute(route);
    print('AftaRobotMigration._writeRoute saved ${route.name} in local cache');
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
          'AftaRobotMigrationdex.primeQueriesToGetIndexingLink ............ landmarks');
    } catch (e) {
      print(e);
    }

    try {
      await fs
          .collection('routes')
          .where('name', isEqualTo: route.name)
          .where('associationID', isEqualTo: route.associationID)
          .getDocuments();
      print(
          'AftaRobotMigrationdex.primeQueriesToGetIndexingLink ............ routes');
      print(
          'AftaRobotMigrationdex.primeQueriesToGetIndexingLink ............ done!');
    } catch (e) {
      print(e);
    }

    return 0;
  }

  static Future<LandmarkDTO> _writeLandmark(LandmarkDTO m) async {
    var mark = await DataAPI.addLandmark(m);
    if (mark == null) {
      print(
          'AftaRobotMigration._writeLandmark -- DUPLICATE LANDMARK: ${m.toJson()}');
      migrationListener
          .onDuplicateRecord('Duplicate: ${m.landmarkName} ${m.path} ');
      return null;
    }
    print('AftaRobotMigration._writeLandmark ... written ok');
    landmarkCount++;
    print(
        '\nAftaRobotMigration.writeLandmark -- ++++++++++ landmark #$landmarkCount added to Firestore: ${mark.landmarkName}');
    landmarks.add(mark);
    migrationListener.onLandmarkAdded(mark);
    await LocalDB.saveLandmark(mark);
    print(
        'AftaRobotMigration._writeLandmark saved in LocalDB: ${mark.landmarkName} in list ');
    return mark;
  }

  static List<LandmarkDTO> landmarks = List();
}
