import 'dart:math';

import 'package:aftarobotlibrary3/api/data_api.dart';
import 'package:aftarobotlibrary3/api/file_util.dart';
import 'package:aftarobotlibrary3/api/list_api.dart';
import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/countrydto.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/data/userdto.dart';
import 'package:aftarobotlibrary3/data/vehicledto.dart';
import 'package:aftarobotlibrary3/data/vehicletypedto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:migrator4/generator.dart';

/*
  The Migrator, all Powerful, all Seeing!
 */
abstract class AftaRobotMigrationListener {
  onAssociationAdded(AssociationDTO association);
  onAssociationsAdded(List<AssociationDTO> associations);
  onVehicleAdded(VehicleDTO car);
  onVehiclesAdded(List<VehicleDTO> cars);
  onVehicleTypeAdded(VehicleTypeDTO car);
  onUserAdded(UserDTO user);
  onUsersAdded(List<UserDTO> users);
  onCountriesAdded(List<CountryDTO> countries);
  onRouteAdded(RouteDTO route);
  onLandmarkAdded(LandmarkDTO landmark);
  onLandmarksAdded(List<LandmarkDTO> landmarks);
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
    migrationListener
        .onGenericMessage('Clean up and debris removal started :)');

    var start = DateTime.now();

    await deleteEverything();
    var end1 = DateTime.now();
    var msg0 =
        'Debris and refuse collection complete. elapsed time: ${end1.difference(start).inSeconds} seconds';
    print('AftaRobotMigration.migrateOldAftaRobot: $msg0');
    migrationListener.onGenericMessage(msg0);
    var msg1 = 'Removing auth users to avoid auth collisions';
    print('AftaRobotMigration.migrateOldAftaRobot $msg1');
    migrationListener.onGenericMessage(msg1);
    try {
      await DataAPI.removeAuthUsers();
      await DataAPI.removeAuthUsers();
      migrationListener.onGenericMessage('STILL removing auth users ...');
      await DataAPI.removeAuthUsers();
      await DataAPI.removeAuthUsers();
      migrationListener.onGenericMessage('Done removing auth users');
    } catch (e) {
      var msg =
          'Something went wrong with auth user deletion. Going on regardless ... $e';
      migrationListener.onGenericMessage(msg);
    }
    var end2 = DateTime.now();
    var msg =
        'Auth user removal complete. elapsed time: ${end2.difference(start).inSeconds} seconds';
    print('\n\nAftaRobotMigration.migrateOldAftaRobot: $msg');
    migrationListener.onGenericMessage(msg);

    migrationListener.onGenericMessage('Adding countries ...');
    countries = await DataAPI.addCountries();
    migrationListener.onCountriesAdded(countries);

    List<AssociationDTO> assList = List();
    List<UserDTO> userList = List();
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
        assList.add(ass);
        var mEmail =
            ass.associationName.replaceAll(" ", '.').toLowerCase().trim() +
                rand.nextInt(99999).toString() +
                '@aftarobot.io';
        var adminUser = UserDTO(
            email: mEmail,
            password: 'pass123',
            cellphone: _getRandomPhone(),
            countryID: ass.countryID,
            name: ass.associationName,
            userType: DataAPI.ASSOC_ADMIN,
            userDescription: DataAPI.ASSOC_ADMIN_DESC);
        userList.add(adminUser);
        cnt++;
        print(
            '\nAftaRobotMigrationdex.migrateOldAftaRobot ------- association #$cnt ${ass.associationName} added to processing list');
      } else {
        print(
            '\nAftaRobotMigration.migrateOldAftaRobot IGNORING ${ass.associationName} - no Firestore for you!!');
      }
    }
    print(
        '\n\nAftaRobotMigrationdex.migrateOldAftaRobot, total associations: ${assList.length} ****************');

    var map = await DataAPI.addAssociations(
        associations: assList, adminUsers: userList);
    asses.addAll(map['associations']);
    users.addAll(map['users']);
    migrationListener.onAssociationsAdded(asses);

    //get vehicles
    await _generateCarTypes(za);
    await migrateCars();
    await migrateUsers();
    var routes = await _getFilteredRoutes();
    await migrateRoutes(routes: routes);
    migrationListener
        .onGenericMessage('Old AftaRobot data migration complete. Happy now?');
    migrationListener.onComplete();
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
      car.associationName = ass.associationName;
      assert(car.vehicleType != null);
    }
    var msg =
        'Migrating ${cars.length} vehicles to Firestore in PAGES of $MAX_DOCUMENTS each.!';
    print('\n\nAftaRobotMigration.migrateCars $msg');
    migrationListener.onGenericMessage(msg);
    await _pageCars(cars);
    migrationListener
        .onGenericMessage('All vehicles migrated: ${vehicles.length}');

    if (listener != null) {
      migrationListener.onComplete();
    }
    return null;
  }

  static Future _pageCars(List<VehicleDTO> cars) async {
    print(
        '\n\nAftaRobotMigration._pageCars .... breaking up ${cars.length} cars into multiple pages');
    var rem = cars.length % MAX_DOCUMENTS;
    var pages = cars.length ~/ MAX_DOCUMENTS;
    if (rem > 0) {
      pages++;
    }
    print(
        'AftaRobotMigration._pageCars: calculated: rem: $rem pages: $pages - is this fucking right????');
    List<VehiclePage> vehiclePages = List();
    int mainIndex = 0;
    for (var i = 0; i < pages; i++) {
      try {
        var vPage = VehiclePage();
        vPage.cars = List();
        for (var j = 0; j < MAX_DOCUMENTS; j++) {
          vPage.cars.add(cars.elementAt(mainIndex));
          mainIndex++;
        }
        vehiclePages.add(vPage);
        print(
            'AftaRobotMigration._pageCars page #${i + 1} has ${vPage.cars.length} cars, mainIndex: $mainIndex');
      } catch (e) {
        print(
            'AftaRobotMigration._pageCars ERROR  mainIndex: $mainIndex --- $e');
        var newIndex = (vehiclePages.length * MAX_DOCUMENTS);
        print(
            'AftaRobotMigration._pageCars ---------> last page starting index: $newIndex');
        var lastPage = VehiclePage();
        lastPage.cars = List();
        for (var i = newIndex; i < cars.length; i++) {
          lastPage.cars.add(cars.elementAt(i));
        }
        vehiclePages.add(lastPage);
//        throw Exception('Am fucked, need the last PAGE!!!!');
        print(
            'AftaRobotMigration._pageCars page #${i + 1} has ${lastPage.cars.length} cars, newIndex: $newIndex');
      }
    }
    print(
        'AftaRobotMigration._pageCars --- broke up cars into number of pages: ${vehiclePages.length} , mainIndex: $mainIndex');
    for (var mPage in vehiclePages) {
      var results = await DataAPI.addVehicles(mPage.cars);
      vehicles.addAll(results);
      migrationListener.onVehiclesAdded(results);
    }
  }

  static const MAX_DOCUMENTS = 30;
  static VehicleTypeDTO _getRandomVehicleType() {
    assert(vehicleTypes.isNotEmpty);
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
    var msg = 'Moving users is ONE FELL SWOOP!';
    print('\n\nAftaRobotMigration.migrateUsers $msg');
    migrationListener.onGenericMessage(msg);
    await _pageUsers(userList);
    migrationListener.onGenericMessage('All users migrated: ${users.length}');
    if (listener != null) {
      listener.onComplete();
    }
    return userList;
  }

  static const MAX_USERS = 10;
  static Future _pageUsers(List<UserDTO> userList) async {
    print(
        '\n\nAftaRobotMigration._pageUsers .... breaking up ${userList.length} users into multiple pages');
    var rem = userList.length % MAX_USERS;
    var pages = userList.length ~/ MAX_USERS;
    if (rem > 0) {
      pages++;
    }
    print(
        'AftaRobotMigration._pageUsers: calculated: rem: $rem pages: $pages - is this fucking right????');
    List<UserPage> userPages = List();
    int mainIndex = 0;
    for (var i = 0; i < pages; i++) {
      try {
        var vPage = UserPage();
        vPage.users = List();
        for (var j = 0; j < MAX_USERS; j++) {
          vPage.users.add(userList.elementAt(mainIndex));
          mainIndex++;
        }
        userPages.add(vPage);
        print(
            'AftaRobotMigration._pageUsers page #${i + 1} has ${vPage.users.length} users, mainIndex: $mainIndex');
      } catch (e) {
        print(
            'AftaRobotMigration._pageUsers ERROR $e --  mainIndex: $mainIndex');
        var newIndex = (userPages.length * MAX_USERS);
        print(
            'AftaRobotMigration._pageUsers ---------> last page starting index: $newIndex');
        var lastPage = UserPage();
        lastPage.users = List();
        for (var i = newIndex; i < userList.length; i++) {
          lastPage.users.add(userList.elementAt(i));
        }
        userPages.add(lastPage);
//        throw Exception('Am fucked, need the last PAGE!!!!');
        print(
            'AftaRobotMigration._pageUsers page #${i + 1} has ${lastPage.users.length} users, newIndex: $newIndex');
      }
    }
    print(
        'AftaRobotMigration._pageUsers --- broke up users into number of pages:'
        ' ${userPages.length}, mainIndex: $mainIndex ... starting to dance .....');

    List<UserDTO> xUserList = List();
    for (var mPage in userPages) {
      var results = await DataAPI.addUsers(mPage.users);
      xUserList.addAll(results);
      migrationListener.onUsersAdded(results);
    }
    users.addAll(xUserList);
    migrationListener.onGenericMessage('${xUserList.length} users added OK');
    return null;
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
      print('AftaRobotMigration._writeAss -- DUPLICATE ASS ${ass.toJson()}');
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
    if (asses.isEmpty) {
      asses = await ListAPI.getAssociations();
    }
    var start = DateTime.now();
    for (var route in routes) {
      bool isFound = false;
      asses.forEach((ass) {
        if (ass.associationID == route.associationID) {
          isFound = true;
        }
      });
      if (isFound) {
        if (route.spatialInfos != null && route.spatialInfos.isNotEmpty) {
          route.countryName = 'South Africa';
          List<LandmarkDTO> landmarks = _getRouteLandmarks(route);
          route.spatialInfos.clear();
          var routeWithPath = await _writeRoute(route);
          if (routeWithPath != null) {
            landmarks.forEach((m) {
              m.routePath = routeWithPath.path;
            });
            print(
                '\nAftaRobotMigration.migrateRoutes @@@@@ write ${landmarks.length} landmarks'
                'for route: ${routeWithPath.name} - assoc: ${routeWithPath.associationName} path: ${routeWithPath.path}\n\n');
            await _writeLandmarks(landmarks);
          }
        } else {
          print(
              '\nAftaRobotMigration.migrateRoutes -- route with no spatials: ${route.name} from assoc: ${route.associationName}');
        }
      } else {
        print(
            'AftaRobotMigration.migrateRoutes - ******** Route does not belong in chosen assocs ${route.name} - ${route.associationName}');
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

  static const addGeoQueryLocationChannel =
      const MethodChannel('aftarobot/addGeoQueryLocation');

  static Future<List<LandmarkDTO>> _writeLandmarks(
      List<LandmarkDTO> marks) async {
    print(
        '\n\nAftaRobotMigration._writeLandmarks +++++++ writing batch of landmarks: ${marks.length}');
    var list = await DataAPI.addLandmarks(marks);
    print(
        '\n\nAftaRobotMigration._writeLandmarks +++++++ writing batch of landmarks to cache: ${marks.length}');
    for (var mark in list) {
      await LocalDB.saveLandmark(mark);
      print(
          'AftaRobotMigration._writeLandmarks - returned from LocalDB - was landmark ADDED ....?????');
    }
    migrationListener.onLandmarksAdded(list);
    return list;
  }

  void addGeoQueryLocation(LandmarkDTO landmark) async {
    print(
        ' 🔵  🔵  start ADD GEO QUERY LOCATION for : ${landmark.landmarkName} geo query location .... ........................');
    try {
      var args = {
        'latitude': landmark.latitude,
        'longitude': landmark.longitude,
        'landmarkID': landmark.landmarkID,
        'landmarkName': landmark.landmarkName,
      };
      var result = await addGeoQueryLocationChannel.invokeMethod(
          'addGeoQueryLocation', args);
      print('Result back from ADD GEO QUERY LOCATION  ....✅ ');
      print(result);
    } on PlatformException catch (e) {
      print(e);
    }
  }

  static List<LandmarkDTO> _getRouteLandmarks(RouteDTO route) {
    print(
        'AftaRobotMigration._getRouteLandmarks .... filter from spatials ...');
    List<LandmarkDTO> landmarks = List();
    Map<String, LandmarkDTO> map = Map();
    route.spatialInfos.forEach((si) {
      map[si.fromLandmark.landmarkID] = si.fromLandmark;
      map[si.toLandmark.landmarkID] = si.toLandmark;
    });

    map.forEach((key, landmark) {
      landmark.associationName = route.associationName;
      landmark.countryID = route.countryID;
      landmarks.add(landmark);
    });

    print(
        'AftaRobotMigration._getRouteLandmarks ******** filtered landmarks: ${landmarks.length}');
    return landmarks;
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
    return mRoute;
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

  static Future deleteEverything() async {
    print('\n\nAftaRobotMigration.deleteEverything ################## start');
    var start = DateTime.now();
    var d1 = await fs.collection('associations').getDocuments();
    print(
        'AftaRobotMigration.deleteEverything ------ deleting ${d1.documents.length} association documents ...');
    for (var doc in d1.documents) {
      var x = await doc.reference.collection('users').getDocuments();
      print(
          'AftaRobotMigration.deleteEverything ------ deleting ${x.documents.length} user documents ...');
      for (var mdoc in x.documents) {
        await mdoc.reference.delete();
      }
      var y = await doc.reference.collection('vehicles').getDocuments();
      print(
          'AftaRobotMigration.deleteEverything ------ deleting ${y.documents.length} car documents ...');
      for (var mdoc in x.documents) {
        await mdoc.reference.delete();
      }
      await doc.reference.delete();
    }
    print(
        'AftaRobotMigration.deleteEverything ******* assocs deleted: ${d1.documents.length}');

    var d4 = await fs.collection('vehicleTypes').getDocuments();
    print(
        'AftaRobotMigration.deleteEverything ------ deleting ${d4.documents.length} carType documents ...');
    for (var doc in d4.documents) {
      await doc.reference.delete();
    }
    print(
        'AftaRobotMigration.deleteEverything ******* car types deleted: ${d4.documents.length}');
    var d = await fs.collection('countries').getDocuments();
    for (var doc in d.documents) {
      await doc.reference.delete();
    }
    print(
        'AftaRobotMigration.deleteEverything ******* countries deleted: ${d.documents.length}');
    await deleteRoutesAndLandmarks();

    var end = DateTime.now();
    print('\nAftaRobotMigration.deleteEverything ***** COMPLETE! '
        'elapsed ${end.difference(start).inSeconds} seconds... ####################\n');
    return null;
  }

  static Future deleteRoutesAndLandmarks() async {
    print(
        '\n\nAftaRobotMigration.deleteRoutesAndLandmarks ################## start');
    var start = DateTime.now();
    var d3 = await fs.collection('routes').getDocuments();
    print(
        'AftaRobotMigration.deleteRoutesAndLandmarks ------ deleting ${d3.documents.length} route documents ...');
    for (var doc in d3.documents) {
      await doc.reference.delete();
    }
    print(
        'AftaRobotMigration.deleteRoutesAndLandmarks ******* routes deleted: ${d3.documents.length}');
    var d4 = await fs.collection('landmarks').getDocuments();
    print(
        'AftaRobotMigration.deleteRoutesAndLandmarks ------ deleting ${d4.documents.length} landmark documents ...');
    for (var doc in d4.documents) {
      await doc.reference.delete();
    }
    print(
        'AftaRobotMigration.deleteRoutesAndLandmarks ******* landmarks deleted: ${d4.documents.length}');
    var end = DateTime.now();
    print('\nAftaRobotMigration.deleteRoutesAndLandmarks ***** COMPLETE! '
        'elapsed ${end.difference(start).inSeconds} seconds... ####################\n');
    return null;
  }
}

class UserPage {
  List<UserDTO> users;
  int pageNumber;

  UserPage({this.users, this.pageNumber});
}

class VehiclePage {
  List<VehicleDTO> cars;
  int pageNumber;

  VehiclePage({this.cars, this.pageNumber});
}
