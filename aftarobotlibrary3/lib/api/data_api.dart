import 'dart:convert';

import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/citydto.dart';
import 'package:aftarobotlibrary3/data/countrydto.dart';
import 'package:aftarobotlibrary3/data/geofence_event.dart';
import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/data/userdto.dart';
import 'package:aftarobotlibrary3/data/vehicledto.dart';
import 'package:aftarobotlibrary3/data/vehicletypedto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/maps/snap_to_roads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

/*
Something weird going on with intellij fucking up this file.
What the fucking hell???
 */
class DataAPI {
  static const URL =
      'https://us-central1-aftarobot2019-dev3.cloudfunctions.net/';
  static const ADD_ASSOCIATION_URL = URL + 'addAssociation',
      ADD_ASSOCIATIONS_URL = URL + 'addAssociations',
      ADD_VEHICLE_TYPE = URL + 'addVehicleType',
      ADD_VEHICLE = URL + 'addVehicle',
      ADD_VEHICLES = URL + 'addVehicles',
      ADD_COUNTRY = URL + 'addCountry',
      ADD_COUNTRIES = URL + 'addCountries',
      ADD_CITIES = URL + 'addCities',
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
  static Firestore fs = Firestore.instance;

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

  static Future addARLocation(ARLocation location) async {
    var ref = await fs
        .collection('rawRoutePoints')
        .document(location.routeID)
        .collection('points')
        .add(location.toJson());
    print('#### ✅  ✅  ARLocation event written to Firestore : ${ref.path}');
    prettyPrint(location.toJson(), '##### addARLocation:');
    return ref;
  }

  static Future addGeofenceEvent(VehicleGeofenceEvent event) async {
    var ref = await fs
        .collection('geofenceEvents')
        .document(event.landmarkID)
        .collection('events')
        .add(event.toJson());
    print(
        '#### ✅  ✅  ARGeofenceEvent event written to Firestore : ${ref.path}');
    prettyPrint(event.toJson(), '##### ARGeofenceEvent:');
    return ref;
  }

  static Future<List<CountryDTO>> addCountries(
      {List<CountryDTO> countries}) async {
    List<CountryDTO> countryList = List();
    if (countries == null) {
      countryNames.forEach((c) {
        countryList.add(CountryDTO(
          name: c,
          date: DateTime.now().millisecondsSinceEpoch,
          status: 'Active',
          countryID: getKey(),
        ));
      });
    }
    countries = countryList;
    List<Map> maps = List();
    countries.forEach((c) {
      maps.add(c.toJson());
    });
    var map = {
      'countries': maps,
    };
    List<CountryDTO> mList = List();
    var res = await _callCloudFunction(ADD_COUNTRIES, map);
    switch (res.statusCode) {
      case 200:
        try {
          List<dynamic> map1 = json.decode(res.body);
          map1.forEach((m) {
            var mCountry = CountryDTO.fromJson(m);
            mList.add(mCountry);
          });
          print(
              'DataAPI.addCountries ######### returned ${mList.length} countries from function call');
          return mList;
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

  static Future<List<CityDTO>> addCities({List<CityDTO> cities}) async {
    print(
        '\n\nDataAPI.addCities ---------- receiving ${cities.length} cities for input to fuction');

    List<Map> maps = List();
    cities.forEach((c) {
      maps.add(c.toJson());
    });

    var map = {
      'cities': maps,
    };
    print(map);
    if (map['cities'] == null || map['cities'].isEmpty) {
      throw Exception('This is fucked, function input (cities) is NULL. WTF?');
    }
    List<CityDTO> mList = List();
    var res = await _callCloudFunction(ADD_CITIES, map);
    switch (res.statusCode) {
      case 200:
        try {
          List<dynamic> map1 = json.decode(res.body);
          map1.forEach((m) {
            var mCountry = CityDTO.fromJson(m);
            mList.add(mCountry);
          });
          print(
              'DataAPI.addCities ######### returned ${mList.length} cities from function call');
          return mList;
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
    //todo - call method on the wild side to set proper location, unless we learn how ...
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
      list.forEach((userMap) {
        UserDTO mUser = UserDTO.fromJson(userMap);
        mList.add(mUser);
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

  static Future<Map> addAssociations(
      {List<AssociationDTO> associations, List<UserDTO> adminUsers}) async {
    List<Map> assocMaps = List();
    associations.forEach((ass) {
      assocMaps.add(ass.toJson());
    });
    List<Map> userMaps = List();
    adminUsers.forEach((user) {
      userMaps.add(user.toJson());
    });
    var map = {'associations': assocMaps, 'users': userMaps};

    var res = await _callCloudFunction(ADD_ASSOCIATIONS_URL, map);
    print('DataAPI.addAssociations: RESULT:\n ${res.body}');
    if (res.statusCode != 200) {
      throw Exception(res.body);
    }
    List<AssociationDTO> mList = List();
    List<UserDTO> sList = List();
    try {
      List<dynamic> result = json.decode(res.body);
      result.forEach((map) {
        var ass = AssociationDTO.fromJson(map['association']);
        var adm = UserDTO.fromJson(map['user']);
        mList.add(ass);
        sList.add(adm);
      });

      return {
        'associations': mList,
        'users': sList,
      };
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
