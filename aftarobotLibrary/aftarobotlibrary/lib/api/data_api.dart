import 'dart:convert';

import 'package:aftarobotlibrary/data/admindto.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:http/http.dart' as http;

class AssociationAPIBag {
  AssociationDTO association;
  AdminDTO administrator;

  AssociationAPIBag({this.association, this.administrator});

  AssociationAPIBag.fromJson(Map data) {
    this.administrator = AdminDTO.fromJson(data['administrator']);
    this.association = AssociationDTO.fromJson(data['association']);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'association': association.toJson(),
        'administrator': administrator.toJson(),
      };
}

class DataAPI {
  static const URL =
      'https://us-central1-aftarobot2019-dev1.cloudfunctions.net/';
  static const ADD_ASSOCIATION_URL = URL + 'addAssociation',
      ADD_VEHICLE_TYPE = URL + 'addVehicleType',
      ADD_VEHICLE = URL + 'addVehicle',
      ADD_COUNTRY = URL + 'addCountry',
      ADD_LANDMARK = URL + 'addLandmark',
      ADD_ROUTE = URL + 'addRoute',
      REGISTER_USER = URL + 'registerUser';
  static List<String> countries = [
    'South Africa',
    'Mozambique',
    'Namibia',
    'eSwatini',
    'Zimbabwe',
    'Tanzania',
    'Kenya',
    'Botswana',
    'Angola',
    'Uganda',
    'Malawi',
    'Zambia',
    'Lesotho'
  ];

  static Future<UserDTO> registerUser(UserDTO user) async {
    prettyPrint(user.toJson(), '######### User about to register::::');
    var map = {
      'user': user.toJson(),
    };

    print('DataAPI.registerUser : sending to cloud function ..');
    prettyPrint(map, "############ map;");
    var res = await _callCloudFunction(REGISTER_USER, map);
    print('DataAPI.registerUser, result: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var userResult = UserDTO.fromJson(map1);
      prettyPrint(userResult.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ USER:');
      return userResult;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future<List<CountryDTO>> addCountries() async {
    List<CountryDTO> list = List();
    for (var name in countries) {
      var cntry = await addCountry(CountryDTO(
        name: name,
        status: 'Active',
        date: DateTime.now().millisecondsSinceEpoch,
      ));
      list.add(cntry);
    }

    return list;
  }

  static Future<CountryDTO> addCountry(CountryDTO country) async {
    var map = {
      'country': country.toJson(),
    };

    print('DataAPI.addCountry : sending to cloud function ..');
    prettyPrint(map, "############ map;");
    var res = await _callCloudFunction(ADD_VEHICLE_TYPE, map);
    print('DataAPI.addCountry, result: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var car = CountryDTO.fromJson(map1);
      prettyPrint(car.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ COUNTRY:');
      return car;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future<VehicleTypeDTO> addVehicleType(VehicleTypeDTO type) async {
    var map = {
      'vehicleType': type.toJson(),
    };

    print('DataAPI.addVehicleType : sending to cloud function ..');
    prettyPrint(map, "############ map;");
    var res = await _callCloudFunction(ADD_VEHICLE_TYPE, map);
    print('DataAPI.addVehicleType, result: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var car = VehicleTypeDTO.fromJson(map1);
      prettyPrint(car.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ VEHICLE TYPE:');
      return car;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future<VehicleDTO> addVehicle(VehicleDTO car) async {
    prettyPrint(car.toJson(), '\n############### vehicle to create:');
    var map = {
      'vehicle': car.toJson(),
    };

    var res = await _callCloudFunction(ADD_VEHICLE, map);
    print('\nDataAPI.addVehicle, result: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var car = VehicleDTO.fromJson(map1);
      prettyPrint(car.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ VEHICLE:');
      return car;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future<RouteDTO> addRoute(RouteDTO route) async {
    prettyPrint(route.toJson(), '\n############### route to create:');
    var map = {
      'route': route.toJson(),
    };

    var res = await _callCloudFunction(ADD_ROUTE, map);
    print('\nDataAPI.addRoute, result: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var mRoute = RouteDTO.fromJson(map1);
      prettyPrint(mRoute.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ ROUTE:');
      return mRoute;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future<UserDTO> addUser(UserDTO user) async {
    prettyPrint(user.toJson(), '\n############### user to create:');
    var map = {
      'user': user.toJson(),
    };

    var res = await _callCloudFunction(ADD_LANDMARK, map);
    print('\nDataAPI.landmark, result: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var mMark = UserDTO.fromJson(map1);
      prettyPrint(mMark.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ USER:');
      return mMark;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future<LandmarkDTO> addLandmark(LandmarkDTO landmark) async {
    prettyPrint(landmark.toJson(), '\n############### Landmark to create:');
    var map = {
      'landmark': landmark.toJson(),
    };

    var res = await _callCloudFunction(ADD_LANDMARK, map);
    print('\nDataAPI.landmark, result: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var mMark = LandmarkDTO.fromJson(map1);
      prettyPrint(mMark.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ LANDMARK:');
      return mMark;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future<AssociationDTO> addAssociation(
      {AssociationDTO association, UserDTO admin}) async {
    var map = {'association': association.toJson(), 'user': admin.toJson()};
    print('DataAPI.addAssociation : sending to cloud function ..');
    prettyPrint(map, "############ map;");
    var res = await _callCloudFunction(ADD_ASSOCIATION_URL, map);
    print('DataAPI.addAssociation, result: ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var ass = AssociationDTO.fromJson(map1['association']);
      prettyPrint(ass.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ ASSOCIATION:');
      var adm = AdminDTO.fromJson(map1['administrator']);
      prettyPrint(adm.toJson(), '\n\n@@@@@@@@@@@@@@@@@@@ ADMINISTRATOR:');

      return ass;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static const Map<String, String> headers = {
    'Content-type': 'application/json',
    'Accept': 'application/json',
  };

  static Future _callCloudFunction(String mUrl, Map bag) async {
    var start = DateTime.now();
    var client = new http.Client();
    var resp = await client
        .post(
      mUrl,
      body: json.encode(bag),
      headers: headers,
    )
        .whenComplete(() {
      client.close();
    });
    print(
        '\n\nDataAPI._callCloudFunction .... ################ BFN via Cloud Functions: statusCode: ${resp.statusCode}');
    print(
        '\n\nDataAPI._callCloudFunction .... ################ BFN via Cloud Functions: body:\n ${resp.body}');
    var end = DateTime.now();
    print(
        '\n\nDataAPI._callCloudFunction ################################# elapsed: ${end.difference(start).inSeconds} seconds\n\n');
    return resp;
  }

  static const int OWNER = 2,
      MARSHAL = 3,
      DRIVER = 4,
      PATROLLER = 5,
      COMMUTER = 6,
      ASSOC_ADMIN = 7,
      AFTAROBOT_STAFF = 8,
      RANK_MANAGER = 9,
      ROUTE_BUILDER = 10;

  static const String OWNER_DESC = "Owner",
      MARSHAL_DESC = "Marshal",
      DRIVER_DESC = "Driver",
      PATROLLER_DESC = "Patroller",
      COMMUTER_DESC = "Commuter",
      ASSOC_ADMIN_DESC = "Administrator",
      AFTAROBOT_STAFF_DESC = "AftaRobot Staff",
      RANK_MANAGER_DESC = "Rank Manager",
      ROUTE_BUILDER_DESC = "Route Builder";
}
