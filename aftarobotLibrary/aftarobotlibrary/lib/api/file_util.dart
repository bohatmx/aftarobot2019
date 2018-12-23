import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aftarobotlibrary/data/citydto.dart';
import 'package:path_provider/path_provider.dart';

class LocalDB {
  static File jsonFile;
  static Directory dir;
  static bool fileExists;

  static Future<int> saveCities(Cities cities) async {
    try {
      Map map = cities.toJson();
      String mJSON = json.encode(map);
      dir = await getApplicationDocumentsDirectory();
      jsonFile = new File(dir.path + "/country-cities.json");
      fileExists = await jsonFile.exists();
      if (fileExists) {
        print('\nLocalDB_saveCities  ## file exists ...writing cities file');
        jsonFile.writeAsString(mJSON);
        return 0;
      } else {
        print(
            'LocalDB_saveCities ## file does not exist ...creating and writing cities file');
        var file = await jsonFile.create();
        await file.writeAsString(json.encode(map));
        print(
            'LocalDB.saveCities ${jsonFile.path} has been written to local cache');
        return 0;
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<List<CityDTO>> getCities() async {
    print('LocalDB.getCities -- ################## starting ...');
    try {
      dir = await getApplicationDocumentsDirectory();
      jsonFile = new File(dir.path + "/country-cities.json");
      fileExists = await jsonFile.exists();

      if (fileExists) {
        var string = await jsonFile.readAsString();
        var map = json.decode(string);
        Cities cities = Cities.fromJson(map);
        print(
            'LocalDB.getCities: ******* found ${cities.cities.length} cities in local cache');
        return cities.cities;
      } else {
        throw Exception('File does not exist');
      }
    } catch (e) {
      print('LocalDB.getCities - ERROR  - ERROR  - ERROR  - ERROR ');
      print(e);
      throw e;
    }
  }
}

class Cities {
  List<CityDTO> cities;
  Cities(this.cities);

  Cities.fromJson(Map data) {
    print('Cities.fromJson -- starting ...');
    List map = data['cities'];
    this.cities = List();
    map.forEach((m) {
      var city = CityDTO.fromJson(m);
      cities.add(city);
    });
    print(
        '\n\n\nCities.fromJson --- ############### parsed ${cities.length} cities. are we ok?');
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
    print('\n\n\n################################# : Cities.toJson: \n$map');
    return map;
  }
}
