import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/citydto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:path_provider/path_provider.dart';

class LocalDB {
  static File jsonFile;
  static Directory dir;
  static bool fileExists;

  static Future<int> saveCity(CityDTO city) async {
    var m = await getCities();
    m.add(city);
    var e = Cities(m);
    print('LocalDB.saveCity - ${city.name} in new list : ${e.cities.length}');
    return await saveCities(e);
  }

  static Future<int> saveCities(Cities cities) async {
    try {
      if (cities.cities.isEmpty) {
        print(
            'LocalDB.saveCountries - NO CITIES FOR OLD MEN in here #####################');
        throw Exception('No cities found in Cities object');
      }
      Map map = cities.toJson();
      return await _writeFile(fileName: 'cities', map: map);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<CityDTO>> getCities() async {
    print('LocalDB.getCities -- ################## starting ...');
    try {
      var map = await _readFile('cities');
      if (map == null) {
        return List();
      }
      return Cities.fromJson(map).cities;
    } catch (e) {
      print('LocalDB.getCities - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      throw e;
    }
  }

  static Future<int> saveCountry(CountryDTO country) async {
    var m = await getCountries();
    m.add(country);
    var e = Countries(m);
    print(
        'LocalDB.saveCountry - ${country.name} in new list : ${e.countries.length}');
    return await saveCountries(e);
  }

  static Future<int> saveCountries(Countries countries) async {
    try {
      if (countries.countries.isEmpty) {
        print(
            'LocalDB.saveCountries - NO COUNTRIES FOR OLD MEN in here #####################');
        throw Exception('No countries found in Countries object');
      }
      Map map = countries.toJson();
      return await _writeFile(fileName: 'countriesData', map: map);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<CountryDTO>> getCountries() async {
    try {
      var map = await _readFile('countriesData');
      if (map == null) {
        return List();
      }
      var m = Countries.fromJson(map).countries;
      return m;
    } catch (e) {
      print('LocalDB.getCountries - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      return null;
    }
  }

  static Future<int> saveAssociation(AssociationDTO association) async {
    var m = await getAssociations();
    m.add(association);
    var e = Associations(m);
    print(
        'LocalDB.Association - ${association.associationName} in new list : ${e.associations.length}');
    return await saveAssociations(e);
  }

  static Future<int> saveAssociations(Associations associations) async {
    try {
      if (associations.associations.isEmpty) {
        print(
            'LocalDB.saveCountries - NO associations FOR OLD MEN in here #####################');
        throw Exception('No associations found in Associations object');
      }
      Map map = associations.toJson();
      return await _writeFile(fileName: 'AssociationsData', map: map);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<AssociationDTO>> getAssociations() async {
    try {
      var map = await _readFile('AssociationsData');
      if (map == null) {
        return List();
      }
      return Associations.fromJson(map).associations;
    } catch (e) {
      print('LocalDB.getAssociations - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      throw e;
    }
  }

  static Future<int> saveUser(UserDTO user) async {
    var m = await getUsers();
    m.add(user);
    var e = Users(m);
    print('LocalDB.saveUser - ${user.name} in new list : ${e.users.length}');
    return await saveUsers(e);
  }

  static Future<int> saveUsers(Users users) async {
    try {
      if (users.users.isEmpty) {
        print(
            'LocalDB.saveCountries - NO Users FOR OLD MEN in here #####################');
        throw Exception('No users found in Users object');
      }
      Map map = users.toJson();
      return await _writeFile(fileName: 'UsersData', map: map);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<UserDTO>> getUsers() async {
    try {
      var map = await _readFile('UsersData');
      if (map == null) {
        return List();
      }
      return Users.fromJson(map).users;
    } catch (e) {
      print('LocalDB.getUsers - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      throw e;
    }
  }

  static Future<int> saveVehicle(VehicleDTO car) async {
    var m = await getVehicles();
    m.add(car);
    var e = Vehicles(m);
    print(
        'LocalDB.saveVehicle - ${car.vehicleReg} in new list : ${e.vehicles.length}');
    return await saveVehicles(e);
  }

  static Future<int> saveVehicles(Vehicles cars) async {
    try {
      if (cars.vehicles.isEmpty) {
        print(
            'LocalDB.saveVehicles - NO Vehicles FOR OLD MEN in here #####################');
        throw Exception('No vehicles found in Vehicles object');
      }
      Map map = cars.toJson();
      return await _writeFile(fileName: 'VehiclesData', map: map);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<VehicleDTO>> getVehicles() async {
    try {
      var map = await _readFile('VehiclesData');
      if (map == null) {
        return List();
      }
      return Vehicles.fromJson(map).vehicles;
    } catch (e) {
      print('LocalDB.getVehicles - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      throw e;
    }
  }

  static Future<int> saveVehicleType(VehicleTypeDTO type) async {
    var m = await getVehicleTypes();
    m.add(type);
    var e = VehicleTypes(m);
    print(
        'LocalDB.saveVehicleType- ${type.make} ${type.model}  in new list : ${e.vehicleTypes.length}');
    return await saveVehicleTypes(e);
  }

  static Future<int> saveVehicleTypes(VehicleTypes types) async {
    try {
      if (types.vehicleTypes.isEmpty) {
        print(
            'LocalDB.saveCountries - NO VehicleTypes FOR OLD MEN in here #####################');
        throw Exception('No VehicleTypes found in VehicleTypes object');
      }
      Map map = types.toJson();
      return await _writeFile(fileName: 'VehicleTypesData', map: map);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<VehicleTypeDTO>> getVehicleTypes() async {
    try {
      var map = await _readFile('VehicleTypesData');
      if (map == null) {
        return List();
      }
      return VehicleTypes.fromJson(map).vehicleTypes;
    } catch (e) {
      print('LocalDB.getVehicleTypes - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      throw e;
    }
  }

  static Future<int> saveLandmark(LandmarkDTO mark) async {
    var m = await getLandmarks();
    m.add(mark);
    var e = Landmarks(m);
    print(
        'LocalDB.saveLandmark - ${mark.landmarkName} in new list : ${e.landmarks.length}');
    return await saveLandmarks(e);
  }

  static Future<int> saveLandmarks(Landmarks landmarks) async {
    try {
      if (landmarks.landmarks.isEmpty) {
        print(
            'LocalDB.saveCountries - NO Landmarks FOR OLD MEN in here #####################');
        throw Exception('No Landmarks found in Landmarks object');
      }
      Map map = landmarks.toJson();
      return await _writeFile(fileName: 'LandmarksData', map: map);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<LandmarkDTO>> getLandmarks() async {
    try {
      var map = await _readFile('LandmarksData');
      if (map == null) {
        return List();
      }
      return Landmarks.fromJson(map).landmarks;
    } catch (e) {
      print('LocalDB.getLandmarks - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      throw e;
    }
  }

  static Future<int> saveRoute(RouteDTO route) async {
    var m = await getRoutes();
    m.add(route);
    var e = Routes(m);
    print('LocalDB.saveRoute - ${route.name} in new list : ${e.routes.length}');
    return await saveRoutes(e);
  }

  static Future<int> saveRoutes(Routes routes) async {
    try {
      if (routes.routes.isEmpty) {
        print(
            'LocalDB.saveCountries - NO Routes FOR OLD MEN in here #####################');
        throw Exception('No routes found in Routes object');
      }
      Map map = routes.toJson();
      return await _writeFile(fileName: 'RoutesData', map: map);
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<RouteDTO>> getRoutes() async {
    try {
      var map = await _readFile('RoutesData');
      if (map == null) {
        return List();
      }
      return Routes.fromJson(map).routes;
    } catch (e) {
      print('LocalDB.getRoutes - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      throw e;
    }
  }

  ////////////
  static Future<int> _writeFile({Map map, String fileName}) async {
    try {
      String mJSON = json.encode(map);
      dir = await getApplicationDocumentsDirectory();
      jsonFile = new File(dir.path + "/" + fileName + '.json');
      fileExists = await jsonFile.exists();
      if (fileExists) {
        print('\nLocalDB__writeFile  ## file exists ...writing $fileName file');
        jsonFile.writeAsString(mJSON);
        return 0;
      } else {
        print(
            'LocalDB__writeFile ## file does not exist ...creating and writing $fileName file');
        var file = await jsonFile.create();
        await file.writeAsString(json.encode(map));
        print(
            'LocalDB._writeFile ${jsonFile.path} has been written to local cache');
        return 0;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  static Future<Map> _readFile(String fileName) async {
    try {
      dir = await getApplicationDocumentsDirectory();
      jsonFile = new File(dir.path + "/" + fileName + ".json");
      fileExists = await jsonFile.exists();

      if (fileExists) {
        var string = await jsonFile.readAsString();
        var map = json.decode(string);
        return map;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }
}

class Cities {
  List<CityDTO> cities;
  Cities(this.cities);

  Cities.fromJson(Map data) {
    List map = data['cities'];
    this.cities = List();
    map.forEach((m) {
      var city = CityDTO.fromJson(m);
      cities.add(city);
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = List();
    if (cities != null) {
      cities.forEach((city) {
        var cityMap = city.toJson();
        listOfMaps.add(cityMap);
      });
    }
    var map = {
      'cities': listOfMaps,
    };
    return map;
  }
}

class Countries {
  List<CountryDTO> countries;
  Countries(this.countries);

  Countries.fromJson(Map data) {
    List map = data['countries'];
    this.countries = List();
    map.forEach((m) {
      var c = CountryDTO.fromJson(m);
      countries.add(c);
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = List();
    countries.forEach((c) {
      var cMap = c.toJson();
      listOfMaps.add(cMap);
    });

    var map = {
      'countries': listOfMaps,
    };
    print('Countries.toJson ---- listOfMaps: ${listOfMaps.length}');
    return map;
  }
}

class Associations {
  List<AssociationDTO> associations;
  Associations(this.associations);

  Associations.fromJson(Map data) {
    List map = data['associations'];
    this.associations = List();
    map.forEach((m) {
      var ass = AssociationDTO.fromJson(m);
      associations.add(ass);
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = List();
    if (associations != null) {
      associations.forEach((ass) {
        var cMap = ass.toJson();
        listOfMaps.add(cMap);
      });
    }
    var map = {
      'associations': listOfMaps,
    };
    return map;
  }
}

class Users {
  List<UserDTO> users;
  Users(this.users);

  Users.fromJson(Map data) {
    List map = data['users'];
    this.users = List();
    map.forEach((m) {
      var ass = UserDTO.fromJson(m);
      users.add(ass);
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = List();
    if (users != null) {
      users.forEach((ass) {
        var cMap = ass.toJson();
        listOfMaps.add(cMap);
      });
    }
    var map = {
      'users': listOfMaps,
    };
    return map;
  }
}

class Vehicles {
  List<VehicleDTO> vehicles;
  Vehicles(this.vehicles);

  Vehicles.fromJson(Map data) {
    List map = data['vehicles'];
    this.vehicles = List();
    map.forEach((m) {
      var ass = VehicleDTO.fromJson(m);
      vehicles.add(ass);
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = List();
    if (vehicles != null) {
      vehicles.forEach((ass) {
        var cMap = ass.toJson();
        listOfMaps.add(cMap);
      });
    }
    var map = {
      'vehicles': listOfMaps,
    };
    return map;
  }
}

class VehicleTypes {
  List<VehicleTypeDTO> vehicleTypes;
  VehicleTypes(this.vehicleTypes);

  VehicleTypes.fromJson(Map data) {
    List map = data['vehicleTypes'];
    this.vehicleTypes = List();
    map.forEach((m) {
      var ass = VehicleTypeDTO.fromJson(m);
      vehicleTypes.add(ass);
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = List();
    if (vehicleTypes != null) {
      vehicleTypes.forEach((ass) {
        var cMap = ass.toJson();
        listOfMaps.add(cMap);
      });
    }
    var map = {
      'vehicleTypes': listOfMaps,
    };
    return map;
  }
}

class Landmarks {
  List<LandmarkDTO> landmarks;
  Landmarks(this.landmarks);

  Landmarks.fromJson(Map data) {
    List map = data['landmarks'];
    this.landmarks = List();
    map.forEach((m) {
      var ass = LandmarkDTO.fromJson(m);
      landmarks.add(ass);
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = List();
    if (landmarks != null) {
      landmarks.forEach((ass) {
        var cMap = ass.toJson();
        listOfMaps.add(cMap);
      });
    }
    var map = {
      'landmarks': listOfMaps,
    };
    return map;
  }
}

class Routes {
  List<RouteDTO> routes;
  Routes(this.routes);

  Routes.fromJson(Map data) {
    List map = data['routes'];
    this.routes = List();
    map.forEach((m) {
      var ass = RouteDTO.fromJson(m);
      routes.add(ass);
    });
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> listOfMaps = List();
    if (routes != null) {
      routes.forEach((ass) {
        var cMap = ass.toJson();
        listOfMaps.add(cMap);
      });
    }
    var map = {
      'routes': listOfMaps,
    };
    return map;
  }
}
