import 'dart:convert';

import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:http/http.dart' as http;

/*
Something weird going on with intellij fucking up this file.
What the fucking hell???
 */
class DataAPI {
  static const URL =
      'https://us-central1-aftarobot2019-dev1.cloudfunctions.net/';
  static const ADD_ASSOCIATION_URL = URL + 'addAssociation',
      ADD_VEHICLE_TYPE = URL + 'addVehicleType',
      ADD_VEHICLE = URL + 'addVehicle',
      ADD_VEHICLES = URL + 'addVehicles',
      ADD_COUNTRY = URL + 'addCountry',
      ADD_LANDMARK = URL + 'addLandmark',
      ADD_LANDMARKS = URL + 'addLandmarks',
      ADD_ROUTE = URL + 'addRoute',
      CHECK_LOGS = URL + 'checkLogs',
      REGISTER_USERS = URL + 'registerUsers',
      REGISTER_USER = URL + 'registerUser';
  static List<String> countryNames = [
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
    var map = {
      'user': user.toJson(),
    };

    var res = await _callCloudFunction(REGISTER_USER, map);
    switch (res.statusCode) {
      case 200:
        try {
          var map1 = json.decode(res.body);
          var userResult = UserDTO.fromJson(map1);
          return userResult;
        } catch (e) {
          print(e);
          throw e;
        }
        break;
      case 201:
        return null;
      default:
        throw Exception(res.body);
        break;
    }
  }

  static Future<List<CountryDTO>> addCountries() async {
    List<CountryDTO> list = List();
    for (var name in countryNames) {
      var country = await addCountry(CountryDTO(
        name: name,
        status: 'Active',
        date: DateTime.now().millisecondsSinceEpoch,
      ));
      list.add(country);
    }
    print('DataAPI.addCountries, ################## countries: ${list.length}');
    return list;
  }

  static Future<CountryDTO> addCountry(CountryDTO country) async {
    var map = {
      'country': country.toJson(),
    };

    var res = await _callCloudFunction(ADD_COUNTRY, map);
    switch (res.statusCode) {
      case 200:
        try {
          var map1 = json.decode(res.body);
          var mCountry = CountryDTO.fromJson(map1);
          return mCountry;
        } catch (e) {
          print(e);
          throw Exception(e);
        }
        break;
      case 201:
        return null;
      default:
        throw Exception(res.body);
        break;
    }
  }

  static Future<VehicleTypeDTO> addVehicleType(VehicleTypeDTO type) async {
    var map = {
      'vehicleType': type.toJson(),
    };

    var res = await _callCloudFunction(ADD_VEHICLE_TYPE, map);
    switch (res.statusCode) {
      case 200:
        try {
          var map1 = json.decode(res.body);
          var car = VehicleTypeDTO.fromJson(map1);
          return car;
        } catch (e) {
          print(e);
          throw Exception(e);
        }
        break;
      case 201:
        return null;
      default:
        throw Exception(res.body);
        break;
    }
  }

  static Future<VehicleDTO> addVehicle(VehicleDTO car) async {
    var map = {
      'vehicle': car.toJson(),
    };

    var res = await _callCloudFunction(ADD_VEHICLE, map);
    switch (res.statusCode) {
      case 200:
        try {
          var map1 = json.decode(res.body);
          var car = VehicleDTO.fromJson(map1);
          return car;
        } catch (e) {
          print(e);
          throw Exception(e);
        }
        break;
      case 201:
        return null;
      default:
        throw Exception(res.body);
        break;
    }
  }

  static Future<RouteDTO> addRoute(RouteDTO route) async {
    var map = {
      'route': route.toJson(),
    };

    var res = await _callCloudFunction(ADD_ROUTE, map);
    switch (res.statusCode) {
      case 200:
        try {
          var map1 = json.decode(res.body);
          var mRoute = RouteDTO.fromJson(map1);
          return mRoute;
        } catch (e) {
          print(e);
          throw Exception(e);
        }
        break;
      case 201:
        return null;
      default:
        throw Exception(res.body);
        break;
    }
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
  }

  static Future<UserDTO> addUser(UserDTO user) async {
    var map = {
      'user': user.toJson(),
    };

    var res = await _callCloudFunction(REGISTER_USER, map);
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var mMark = UserDTO.fromJson(map1);
      return mMark;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future<List<LandmarkDTO>> addLandmarks(
      List<LandmarkDTO> landmarks) async {
    List<Map> maps = List();
    landmarks.forEach((m) {
      maps.add(m.toJson());
    });
    var map = {
      'landmarks': maps,
    };

    var res = await _callCloudFunction(ADD_LANDMARKS, map);
    switch (res.statusCode) {
      case 200:
        _processLandmarksResult(res);
        break;
      case 201:
        return List();
      default:
        throw Exception(res.body);
        break;
    }
    return _processLandmarksResult(res);
  }

  static Future<List<VehicleDTO>> addVehicles(List<VehicleDTO> vehicles) async {
    List<Map> maps = List();
    vehicles.forEach((m) {
      maps.add(m.toJson());
    });
    var map = {
      'vehicles': maps,
    };

    var res = await _callCloudFunction(ADD_VEHICLES, map);
    switch (res.statusCode) {
      case 200:
        return _processVehiclesResult(res);
        break;
      case 201:
        return List();
      default:
        throw Exception(res.body);
        break;
    }
  }

  static List<VehicleDTO> _processVehiclesResult(res) {
    List<VehicleDTO> mList = List();
    try {
      List<dynamic> list = json.decode(res.body);
      list.forEach((map1) {
        var v = VehicleDTO.fromJson(map1);
        mList.add(v);
      });

      return mList;
    } catch (e) {
      print(e);
      throw Exception('Unable to parse vehicles result');
    }
  }

  static Future<List<UserDTO>> addUsers(List<UserDTO> users) async {
    List<Map> maps = List();
    users.forEach((m) {
      maps.add(m.toJson());
    });
    var map = {
      'users': maps,
    };

    var res = await _callCloudFunction(REGISTER_USERS, map);
    switch (res.statusCode) {
      case 200:
        return _processUserssResult(res);
        break;
      case 201:
        return List();
      default:
        throw Exception(res.body);
        break;
    }
  }

  static List<LandmarkDTO> _processLandmarksResult(res) {
    List<LandmarkDTO> mList = List();
    try {
      List<dynamic> list = json.decode(res.body);
      list.forEach((map1) {
        LandmarkDTO mMark = LandmarkDTO.fromJson(map1);
        mList.add(mMark);
      });

      return mList;
    } catch (e) {
      print(e);
      throw Exception('Unable to parse landmarks result');
    }
  }

  static List<UserDTO> _processUserssResult(res) {
    List<UserDTO> mList = List();
    try {
      List<dynamic> list = json.decode(res.body);
      list.forEach((map1) {
        UserDTO mMark = UserDTO.fromJson(map1);
        mList.add(mMark);
      });

      return mList;
    } catch (e) {
      print(e);
      throw Exception('Unable to parse users result');
    }
  }

  static Future<LandmarkDTO> addLandmark(LandmarkDTO landmark) async {
    var map = {
      'landmark': landmark.toJson(),
    };

    var res = await _callCloudFunction(ADD_LANDMARK, map);
    switch (res.statusCode) {
      case 200:
        _processLandmarkResult(res);
        break;
      case 201:
        return null;
      default:
        throw Exception(res.body);
        break;
    }
    return _processLandmarkResult(res);
  }

  static LandmarkDTO _processLandmarkResult(res) {
    try {
      var map1 = json.decode(res.body);
      var mMark = LandmarkDTO.fromJson(map1);
      return mMark;
    } catch (e) {
      print(e);
      throw Exception('Unable to parse landmark result');
    }
  }

  static Future<AssociationDTO> addAssociation(
      {AssociationDTO association, UserDTO adminUser}) async {
    var map = {'association': association.toJson(), 'user': adminUser.toJson()};

    var res = await _callCloudFunction(ADD_ASSOCIATION_URL, map);
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    try {
      var map1 = json.decode(res.body);
      var ass = AssociationDTO.fromJson(map1['association']);
      var adm = UserDTO.fromJson(map1['user']);

      return ass;
    } catch (e) {
      print(e);
      throw Exception(e);
    }
  }

  static Future removeAuthUsers() async {
    var map = {"auth": "tigerKills", "debug": "true"};
    var res = await _callCloudFunction(CHECK_LOGS, map);
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }

    print('DataAPI.removeAuthUsers @@@@@@@ RESPONSE: ${res.body}');
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
        '\n\nDataAPI._callCloudFunction .... #### BFN via Cloud Functions: statusCode: ${resp.statusCode} for $mUrl');
//    print(
//        'DataAPI._callCloudFunction .... #### BFN via Cloud Functions: response body:\n ${resp.body}');
    var end = DateTime.now();
    print(
        'DataAPI._callCloudFunction ################################# elapsed: ${end.difference(start).inSeconds} seconds\n\n');
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

class AssociationAPIBag {
  AssociationDTO association;
  UserDTO user;

  AssociationAPIBag({this.association, this.user});

  AssociationAPIBag.fromJson(Map data) {
    this.user = UserDTO.fromJson(data['user']);
    this.association = AssociationDTO.fromJson(data['association']);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'association': association.toJson(),
        'user': user.toJson(),
      };
}
