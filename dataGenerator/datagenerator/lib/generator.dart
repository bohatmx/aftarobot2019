import 'dart:math';

import 'package:aftarobotlibrary/api/data_api.dart';
import 'package:aftarobotlibrary/data/admindto.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';

abstract class GeneratorListener {
  onEvent(Msg msg);
  onError(String message);
  onRecordAdded();
}

class Generator {
  static Firestore fs = Firestore.instance;
  static GeneratorListener generatorListener;
  static List<VehicleTypeDTO> carTypes = List(), existingCarTypes = List();
  static List<VehicleDTO> cars = List(), existingCars = List();
  static List<UserDTO> users = List(), existingUsers = List();
  static List<AssociationDTO> asses = List(), existingAsses = List();
  static List<AdminDTO> admins = List();

  static Future getExistingData(GeneratorListener listener) async {
    listener.onEvent(Msg(
        style: Styles.blackBoldMedium,
        icon: Icon(Icons.apps),
        message: 'Existing Data'));

    var qs0 = await fs.collection('vehicleTypes').getDocuments();
    for (var mdoc in qs0.documents) {
      existingCarTypes.add(VehicleTypeDTO.fromJson(mdoc.data));
    }
    listener.onEvent(Msg(
        style: Styles.blackBoldSmall,
        icon: Icon(Icons.apps),
        message: 'Vehicle Types: ${existingCarTypes.length}'));

    var qs1 = await fs.collection('associations').getDocuments();
    for (var doc in qs1.documents) {
      existingAsses.add(AssociationDTO.fromJson(doc.data));
      var qs1a =
          await doc.reference.collection('administrators').getDocuments();
      for (var doc2 in qs1a.documents) {
        admins.add(AdminDTO.fromJson(doc2.data));
      }
      listener.onEvent(Msg(
          style: Styles.blackBoldSmall,
          icon: Icon(Icons.apps),
          message: 'Administrators: ${admins.length}'));

      var qs1b = await doc.reference.collection('vehicles').getDocuments();
      for (var doc2 in qs1b.documents) {
        existingCars.add(VehicleDTO.fromJson(doc2.data));
      }
      listener.onEvent(Msg(
          style: Styles.blackBoldSmall,
          icon: Icon(Icons.apps),
          message: 'Vehicles: ${existingCars.length}'));
    }

    listener.onEvent(Msg(
        style: Styles.blackBoldSmall,
        icon: Icon(Icons.apps),
        message: 'Associations: ${existingAsses.length}'));

    var qs3 = await fs.collection('users').getDocuments();
    for (var mdoc in qs3.documents) {
      users.add(UserDTO.fromJson(mdoc.data));
    }
    listener.onEvent(Msg(
        style: Styles.blackBoldSmall,
        icon: Icon(Icons.apps),
        message: 'Users: ${users.length}'));
  }

  static Future generate(GeneratorListener listener) async {
    generatorListener = listener;
    var start = DateTime.now();
    print('\n\nGenerator.generate ################ --------- ');
    generatorListener.onEvent(Msg(
        message: 'AR Data Generation',
        style: Styles.blackBoldMedium,
        icon: Icon(Icons.apps, color: getRandomColor())));
    var result = await _generateAssociations();
    if (result == false) {
      generatorListener.onEvent(Msg(
          message: 'Failed to write',
          style: Styles.pinkBoldSmall,
          icon: Icon(
            Icons.error,
            color: Colors.pink,
          )));

      return null;
    }

    generatorListener.onEvent(Msg(
        message: 'Added ${asses.length} associations',
        style: Styles.pinkBoldSmall,
        icon: Icon(Icons.apps)));
    generatorListener.onEvent(Msg(
        message: 'Generating car types',
        style: Styles.blackBoldMedium,
        icon: Icon(Icons.airport_shuttle)));

    generatorListener.onEvent(Msg(
        message: 'Added ${carTypes.length} car types',
        style: Styles.pinkBoldSmall,
        icon: Icon(Icons.apps)));
    generatorListener.onEvent(Msg(
        message: 'Generating users',
        style: Styles.blackBoldMedium,
        icon: Icon(Icons.people)));

    for (var ass in asses) {
      await _generateUsers(ass);
    }
    generatorListener.onEvent(Msg(
        message: 'Added ${asses.length} users',
        style: Styles.pinkBoldSmall,
        icon: Icon(Icons.people)));

    generatorListener.onEvent(Msg(
        message: 'Generating cars ...',
        style: Styles.blackBoldMedium,
        icon: Icon(Icons.airport_shuttle)));

    var mCnt = 0;
    print(
        '\nGenerator.generate .... searching ${users.length} for Owners ........so they can buy cars!');
    for (var owner in users) {
      if (owner.userType == DataAPI.OWNER) {
        mCnt++;
        print(
            'Generator.generate - ************ #$mCnt - this user is an Owner; will be buying cars! ${owner.name} - id: ${owner.associationID}');
        var ass = _findAssociation(owner);
        if (ass != null) {
          print(
              'Generator.generate: #$mCnt - this Owner belongs to: ${ass.associationName}');
          await _generateVehicles(ass, owner);
        } else {
          print(
              '\n\n\nGenerator.generate ------------------------> Association not found, userType may be a problem');
        }
      }
    }

    generatorListener.onEvent(Msg(
        message: 'Added ${cars.length} vehicles',
        style: Styles.pinkBoldSmall,
        icon: Icon(Icons.airport_shuttle)));
    var end = DateTime.now();
    generatorListener.onEvent(Msg(
        message: '** Done generating associations **',
        style: Styles.tealBoldLarge,
        icon: Icon(
          Icons.ac_unit,
          color: getRandomColor(),
        )));

    //TODO - migrate all routes and landmarks

    generatorListener.onEvent(Msg(
        message:
            'Generation complete. Elapsed ${end.difference(start).inMinutes} minutes',
        style: Styles.purpleMedium,
        icon: Icon(
          Icons.alarm,
          color: Colors.purple,
        )));

    return null;
  }

  static AssociationDTO _findAssociation(UserDTO user) {
    prettyPrint(user.toJson(),
        '@@@@@@@@@@ user ${user.name} looking for associationID::: ${user.associationID} - ${user.associationName} from ${asses.length} associations');
    for (var ass in asses) {
      print(
          'Generator.findAssociation ....... searching association:: ${ass.associationID} - ${ass.associationName}');
      if (ass.associationID == user.associationID) {
        return ass;
      }
    }

    print('Generator.findAss -------------- FAILED to find Owners Association');
    return null;
  }

  static Future _generateAssociations() async {
    print(
        '\n\nGenerator._generateAssociations - ################### starting ...');
    generatorListener.onEvent(Msg(
        message: 'Generating associations, starting at: ${DateTime.now()}',
        style: Styles.blackBoldSmall,
        icon: Icon(
          Icons.apps,
          color: getRandomColor(),
        )));
    var list = _getAssocAdmins();
    generatorListener.onEvent(Msg(
        message: 'Generating associations: ${list.length}  :)',
        style: Styles.blackSmall,
        icon: Icon(
          Icons.apps,
          color: getRandomColor(),
        )));
    try {
      int cnt = 0;
      for (var aa in list) {
        var res = await DataAPI.addAssociation(
            association: aa.association, admin: aa.admin);
        asses.add(res);
        cnt++;
        generatorListener.onEvent(Msg(
          message: '${aa.association.associationName}',
          style: Styles.blackBoldSmall,
          icon: Icon(Icons.add_shopping_cart),
        ));
        generatorListener.onRecordAdded();
      }
      return true;
    } catch (e) {
      print(e);
      generatorListener.onError(e.toString());
      return false;
    }
  }

  static Future _generateVehicles(AssociationDTO ass, UserDTO owner) async {
    print(
        'Generator.generateVehicles ####################### ${ass.associationName} - ${owner.name}');
    generatorListener.onEvent(Msg(
        message: '${ass.associationName} - ${owner.name} cars',
        style: Styles.pinkBoldSmall,
        icon: Icon(
          Icons.airport_shuttle,
          color: Colors.black,
        )));

    var count = rand.nextInt(10);
    if (count < 2) {
      count = 5;
    }
    for (var i = 0; i < count; i++) {
      var veh = _getRandomVehicle(ass: ass, owner: owner, list: carTypes);
      veh.assocPath = ass.path;
      veh.ownerPath = owner.path;
      var res = await DataAPI.addVehicle(veh);
      cars.add(res);
      generatorListener.onRecordAdded();
      generatorListener.onEvent(Msg(
          message:
              '${veh.vehicleReg} ${veh.vehicleType.make} ${veh.vehicleType.model}',
          style: Styles.blackSmall,
          icon: Icon(
            Icons.airport_shuttle,
            color: getRandomColor(),
          )));
    }
    generatorListener.onEvent(Msg(
        message: 'Finished vehicle generation',
        style: Styles.blackBoldSmall,
        icon: Icon(
          Icons.airport_shuttle,
          color: getRandomColor(),
        )));
    return null;
  }

  static Future _generateUsers(AssociationDTO ass) async {
    generatorListener.onEvent(Msg(
        message: '${ass.associationName} Users',
        style: Styles.pinkBoldSmall,
        icon: Icon(
          Icons.people,
          color: Colors.black,
        )));

    var countOwners = rand.nextInt(5);
    if (countOwners < 3) {
      countOwners = 3;
    }
    var countDrivers = rand.nextInt(20);
    if (countDrivers < 5) {
      countDrivers = 10;
    }
    var countAssocAdmin = rand.nextInt(3);
    if (countAssocAdmin < 1) {
      countAssocAdmin = 1;
    }
    var countMarsh = rand.nextInt(5);
    if (countMarsh < 2) {
      countMarsh = 2;
    }
    var countPat = rand.nextInt(5);
    if (countPat < 2) {
      countPat = 2;
    }
    try {
      await _handleUser(countOwners, ass, DataAPI.OWNER_DESC, DataAPI.OWNER);
      generatorListener.onEvent(Msg(
          message: 'Owners added: $countOwners',
          style: Styles.pinkBoldSmall,
          icon: Icon(
            Icons.pan_tool,
            color: Colors.black,
          )));

      await _handleUser(countDrivers, ass, DataAPI.DRIVER_DESC, DataAPI.DRIVER);
      generatorListener.onEvent(Msg(
          message: 'Drivers added: $countDrivers',
          style: Styles.pinkBoldSmall,
          icon: Icon(
            Icons.alarm,
            color: Colors.black,
          )));
      await _handleUser(
          countAssocAdmin, ass, DataAPI.ASSOC_ADMIN_DESC, DataAPI.ASSOC_ADMIN);
      generatorListener.onEvent(Msg(
          message: 'Admins added: $countAssocAdmin',
          style: Styles.pinkBoldSmall,
          icon: Icon(
            Icons.edit,
            color: Colors.black,
          )));
      await _handleUser(countMarsh, ass, DataAPI.MARSHAL_DESC, DataAPI.MARSHAL);
      generatorListener.onEvent(Msg(
          message: 'Marshals added: $countMarsh',
          style: Styles.pinkBoldSmall,
          icon: Icon(
            Icons.accessibility_new,
            color: Colors.black,
          )));
      await _handleUser(
          countPat, ass, DataAPI.PATROLLER_DESC, DataAPI.PATROLLER);
    } catch (e) {
      generatorListener.onError('Failed to add user: $e');
      return null;
    }
    generatorListener.onEvent(Msg(
        message: 'Finished ${ass.associationName} users: $countOwners',
        style: Styles.purpleBoldSmall,
        icon: Icon(
          Icons.people,
          color: getRandomColor(),
        )));
    return null;
  }

  static Future _handleUser(int countOwners, AssociationDTO ass,
      String description, int userType) async {
    for (var i = 0; i < countOwners; i++) {
      await _processOneUser(
          ass: ass, i: i, description: description, userType: userType);
    }
  }

  static Future _processOneUser(
      {AssociationDTO ass, int i, String description, int userType}) async {
    var m = _getRandomUser(ass);
    m.userType = userType;
    m.userID = getKey();
    m.userDescription = description;
    var res = await DataAPI.registerUser(m);
    users.add(res);
    generatorListener.onRecordAdded();
    generatorListener.onEvent(Msg(
        message: 'Added: #${i + 1} - ${m.name}',
        style: Styles.blackSmall,
        icon: Icon(
          Icons.person_add,
          color: Colors.black,
        )));
  }

  static List<String> assNames = [
    'Brits',
    'Madibeng',
    'Schoemansville',
    'Mokopane',
    'Pecanwood',
    'Fourways',
    'Lanseria',
    'Randburg',
    'Bryanston',
    'Modderfontein',
    'Midrand',
    'Atteridgeville',
    'Kosmos',
    'Cosmo City',
    'SunningHill',
    'Fordsburg',
    'Downtown',
    'Pretoria East',
    'Pretoria West',
    'Mamelodi',
    'Mshenguville',
    'Soweto',
    'Dobsonville',
    'Krugersdorp',
    'Rustenburg',
    'Machadodorp',
    'Broederstroom',
    'Dainfern Ridge',
    'Lonehill',
    'Johannesburg'
  ];
  static List<String> midNames = [
    'Taxi',
    'Transport',
    'Mobility',
    'Taxi',
    "Taxi",
    'Cab',
    'Transport',
    'Taxi',
    'Transport',
    'Taxi',
    'Taxi',
    'Transport',
    'Mobility',
    'Taxi',
    "Taxi",
    'Cab',
    'Transport',
    'Taxi',
    'Transport',
    'Taxi',
  ];
  static List<String> endNames = [
    'Association',
    'Organisation',
    'Association',
    'Union',
    'Association',
    'Group',
    'Union',
    'Organisation',
    'Union',
    'Group',
    'Organisation',
    'Group',
    'Association',
    'Association',
  ];
  static List<AssocAdminBag> _getAssocAdmins() {
    List<AssocAdminBag> list = List();
    var name1 = assNames.elementAt(rand.nextInt(assNames.length - 1)) +
        ' ' +
        midNames.elementAt(rand.nextInt(midNames.length - 1)) +
        ' ' +
        endNames.elementAt(rand.nextInt(endNames.length - 1));

    var ass1 = AssociationDTO(
        associationID: getKey(),
        associationName: name1,
        stringDate: getUTCDate(),
        date: getUTCDateInt(),
        cityName: 'Hartebeestpoort',
        countryName: 'South Africa',
        phone: '+27926557899',
        status: 'Active');
    var det = _getRandomDetails();
    var adm1 = UserDTO(
      associationID: ass1.associationID,
      cellphone: det.phone,
      userID: getKey(),
      name: det.name,
      dateRegistered: getUTCDateInt(),
      email: det.email,
      password: det.password,
    );
    list.add(AssocAdminBag(admin: adm1, association: ass1));

    var det2 = _getRandomDetails();
    var name2 = assNames.elementAt(rand.nextInt(assNames.length - 1)) +
        ' ' +
        midNames.elementAt(rand.nextInt(midNames.length - 1)) +
        ' ' +
        endNames.elementAt(rand.nextInt(endNames.length - 1));
    var ass2 = AssociationDTO(
        associationID: getKey(),
        associationName: name2,
        stringDate: getUTCDate(),
        date: getUTCDateInt(),
        cityName: 'Fourways',
        countryName: 'South Africa',
        phone: '+27926557891',
        status: 'Active');
    var adm2 = UserDTO(
      associationID: ass2.associationID,
      cellphone: det2.phone,
      userID: getKey(),
      name: det2.name,
      dateRegistered: getUTCDateInt(),
      email: det2.email,
      password: det2.password,
    );
    list.add(AssocAdminBag(admin: adm2, association: ass2));

    var det3 = _getRandomDetails();
    var name3 = assNames.elementAt(rand.nextInt(assNames.length - 1)) +
        ' ' +
        midNames.elementAt(rand.nextInt(midNames.length - 1)) +
        ' ' +
        endNames.elementAt(rand.nextInt(endNames.length - 1));
    var ass3 = AssociationDTO(
        associationID: getKey(),
        associationName: name3,
        stringDate: getUTCDate(),
        date: getUTCDateInt(),
        cityName: 'Brits',
        countryName: 'South Africa',
        phone: det3.phone,
        status: 'Active');
    var adm3 = UserDTO(
      associationID: ass3.associationID,
      cellphone: det3.phone,
      userID: getKey(),
      name: det3.name,
      dateRegistered: getUTCDateInt(),
      email: det3.email,
      password: det3.password,
    );
    list.add(AssocAdminBag(admin: adm3, association: ass3));
    var name4 = assNames.elementAt(rand.nextInt(assNames.length - 1)) +
        ' ' +
        midNames.elementAt(rand.nextInt(midNames.length - 1)) +
        ' ' +
        endNames.elementAt(rand.nextInt(endNames.length - 1));
    var ass4 = AssociationDTO(
        associationID: getKey(),
        associationName: name4,
        stringDate: getUTCDate(),
        date: getUTCDateInt(),
        cityName: 'Hartebeestpoort',
        countryName: 'South Africa',
        phone: '+27926557896',
        status: 'Active');
    var det4 = _getRandomDetails();
    var adm4 = UserDTO(
      associationID: ass4.associationID,
      cellphone: det4.phone,
      userID: getKey(),
      name: det4.name,
      dateRegistered: getUTCDateInt(),
      email: det4.email,
      password: det4.password,
    );
    list.add(AssocAdminBag(admin: adm4, association: ass4));
    var det5 = _getRandomDetails();
    var name5 = assNames.elementAt(rand.nextInt(assNames.length - 1)) +
        ' ' +
        midNames.elementAt(rand.nextInt(midNames.length - 1)) +
        ' ' +
        endNames.elementAt(rand.nextInt(endNames.length - 1));
    var ass5 = AssociationDTO(
        associationID: getKey(),
        associationName: name5,
        stringDate: getUTCDate(),
        date: getUTCDateInt(),
        cityName: 'Hartebeestpoort',
        countryName: 'South Africa',
        phone: '+27926557898',
        status: 'Active');
    var adm5 = UserDTO(
      associationID: ass5.associationID,
      cellphone: det5.phone,
      userID: getKey(),
      name: det5.name,
      dateRegistered: getUTCDateInt(),
      email: det5.email,
      password: det5.password,
    );
    list.add(AssocAdminBag(admin: adm5, association: ass5));
    return list;
  }
}

class AssocAdminBag {
  AssociationDTO association;
  UserDTO admin;

  AssocAdminBag({this.association, this.admin});
}

class Msg {
  final TextStyle style;
  final String message;
  final Icon icon;

  Msg({this.style, this.message, this.icon});
}

String getUTCDate() {
  initializeDateFormatting();
  String now = new DateTime.now().toUtc().toIso8601String();
  return now;
}

int getUTCDateInt() {
  initializeDateFormatting();
  var now = new DateTime.now().toUtc().millisecondsSinceEpoch;
  return now;
}

String getKey() {
  var uuid = new Uuid();
  String key = uuid.v1();
  return key;
}

Details _getRandomDetails() {
  var fName = firstNames.elementAt(rand.nextInt(firstNames.length - 1));
  var lName = lastNames.elementAt(rand.nextInt(lastNames.length - 1));
  var fullName = fName + ' ' + lName;
  var email = fName.toLowerCase() +
      '.' +
      lName.toLowerCase() +
      '${rand.nextInt(100)}' +
      '@aftarobot.co.za';
  var mm = email.replaceAll(' ', '');
  var password = 'pass123';
  var details = Details(
    name: fullName,
    password: password,
    email: mm,
    phone: _getRandomPhone(),
  );
  return details;
}

String _getRandomPhone() {
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

class Details {
  String name, email, phone, password;

  Details({this.name, this.email, this.phone, this.password});
}

Random rand = Random(DateTime.now().millisecondsSinceEpoch);
String getRandomRegistration() {
  var p1 = alphaBet.elementAt(rand.nextInt(alphaBet.length - 1));
  var p2 = alphaBet.elementAt(rand.nextInt(alphaBet.length - 1));

  var p3 = numbers.elementAt(rand.nextInt(numbers.length - 1));
  var p4 = numbers.elementAt(rand.nextInt(numbers.length - 1));
  var p5 = numbers.elementAt(rand.nextInt(numbers.length - 1));

  var p6 = alphaBet.elementAt(rand.nextInt(alphaBet.length - 1));
  var p7 = alphaBet.elementAt(rand.nextInt(alphaBet.length - 1));

  var plate = p1 + p2 + " " + p3 + p4 + p5 + ' ' + p6 + p7 + ' GP';
  return plate;
}

UserDTO _getRandomUser(AssociationDTO ass) {
  var details = _getRandomDetails();
  UserDTO user = UserDTO(
      email: details.email,
      password: details.password,
      name: details.name,
      associationID: ass.associationID,
      associationName: ass.associationName,
      activeFlag: true,
      cellphone: details.phone,
      address: '333 Some Random Street, Random City 00067, ZA');
  return user;
}

VehicleDTO _getRandomVehicle(
    {AssociationDTO ass, UserDTO owner, List<VehicleTypeDTO> list}) {
  var car = VehicleDTO(
    associationName: ass.associationName,
    associationID: ass.associationID,
    status: 'Active',
    date: getUTCDateInt(),
    vehicleID: getKey(),
    vehicleReg: getRandomRegistration(),
    vehicleType: _getRandomType(list),
  );

  return car;
}

VehicleTypeDTO _getRandomType(List<VehicleTypeDTO> list) {
  var vt = list.elementAt(rand.nextInt(list.length - 1));
  return vt;
}

List<String> alphaBet = [
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'J',
  "K",
  'L',
  "M",
  'N',
  'P',
  'Q',
  "R",
  'S',
  'T',
  'V',
  "W",
  'X',
  "Z"
];
List<String> numbers = [
  '1',
  '3',
  '4',
  3.toString(),
  '5',
  4.toString(),
  '6',
  7.toString(),
  8.toString(),
  9.toString(),
  1.toString(),
  2.toString(),
  3.toString(),
  1.toString(),
  2.toString(),
];
List<String> firstNames = [
  'Jimmy',
  'Lesego',
  'Mpho',
  'Vusi',
  'Francis',
  'Nothando',
  'Njabulo',
  "Harold",
  'Poppie',
  'Cynthia',
  'Steve',
  'Papi',
  'Thomas',
  'Earl',
  'Anthony',
  'Johan',
  "David",
  'Musapa',
  'JJ',
  'Fanie',
  "Hlubi",
  'Jerry'
      'Oupa',
  'John',
  'Piet',
  'Bernard',
  'Ntini',
  'Bra Johnny',
  'Judge',
  'Innocent',
  'Privilege',
  'Tommy'
      'Phineas',
  'Magezi',
  'Benjamin',
  'Sonny',
  'Robert',
  'Sam',
  "Rock",
  'Samuel',
  'Clive',
  'Rory',
  'Ntutule',
  'Vusi',
  'Vuyani',
  'Melvin',
  'Andrew',
  'Skinny',
  'Johannes',
  'Eric'
];
List<String> lastNames = [
  'Mathebula',
  'Baloyi',
  "Nkuna",
  'Pieterse',
  'Charles',
  'vanRensburg',
  'Rose',
  'Harkney',
  'Smith',
  'Jones',
  'Kolobe',
  'Marumulane',
  'Nkoane',
  'Marivate',
  'Khumalo',
  'Frankin',
  'Magubane',
  'Mashaba',
  'Thebe',
  'Mafura',
  'Mafutha',
  'Nkoweni',
  'Ndlovu',
  'Wisane',
  'Nghalalume',
  'Sono',
  'Sithole',
  'Mathebula',
  "Mathibe",
  'Maluleke',
  'Ringani',
  'Lamola',
  'Buthelezi',
  'Khuzwayo',
  'Nkosi',
  "Sibiya",
  'George',
  'Franklin',
  'Thulas',
  "Zondo",
  'Zebula',
  'Xaba',
  'Hlungwane',
  'Mathonsi',
  'Mathole',
  'Shilubane',
  "Elim",
  'Sibasa',
  'Chauke',
  'Bhengu',
  'Sibiya'
];
