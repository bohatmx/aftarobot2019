import 'package:aftarobotlibrary/data/citydto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datagenerator/generator.dart';
import 'package:firebase_database/firebase_database.dart';

abstract class CountryListener {
  onCountry(CountryDTO country);
}

abstract class CityListener {
  onCity(CityDTO city);
}

class CountryGenerator {
  static Firestore fs = Firestore.instance;
  static FirebaseDatabase fb = FirebaseDatabase.instance;

  static Future<List<CountryDTO>> getCountries() async {
    List<CountryDTO> list = List();
    try {
      var qs = await fs.collection('countries').orderBy('name').getDocuments();

      qs.documents.forEach((doc) {
        list.add(CountryDTO.fromJson(doc.data));
      });
      return list;
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static final List<String> stringList = [
    'South Africa',
    'Mozambique',
    'Lesotho',
    'Malawi',
    'Namibia',
    'Botswana',
    "Zimbabwe",
    'Angola',
    'Kenya',
    'Tanzania',
    'Zambia',
    'Uganda'
  ];
  static Future<List<CountryDTO>> generateCountries(
      CountryListener listener) async {
    List<CountryDTO> list = List();
    try {
      for (var name in stringList) {
        var country = CountryDTO(
          name: name,
          date: DateTime.now().millisecondsSinceEpoch,
          status: 'Active',
          countryID: getKey(),
        );
        await addCountry(country);
        listener.onCountry(country);
        list.add(country);
      }
    } catch (e) {
      print(e);
      throw e;
    }
    return list;
  }

  static Future<List<CityDTO>> addCities(
      {List<CityDTO> cities, CountryDTO country, CityListener listener}) async {
    print(
        'CountryGenerator.addCities -- #################### start loading cities');
    var start = DateTime.now();
    List<CityDTO> list = List();
    for (var city in cities) {
      var mCity = await addCity(country: country, city: city);
      list.add(mCity);
      listener.onCity(mCity);
    }
    var end = DateTime.now();
    print(
        '\n\nCountryGenerator.addCities: COMPLETED: elapsed: ${end.difference(start).inMinutes}');
    return list;
  }

  static Future<CityDTO> addCity({CityDTO city, CountryDTO country}) async {
    print('addCity ----------- ${country.name} - ${city.name}');
    int cnt = 0;
    try {
      var qs = await fs
          .collection('countries')
          .where('countryID', isEqualTo: country.countryID)
          .getDocuments();
      if (qs.documents.isNotEmpty) {
        var m = await qs.documents.first.reference
            .collection('cities')
            .add(city.toJson());
        city.path = m.path;
        await m.setData(city.toJson());
        cnt++;
        print(
            'CountryGenerator.addCity: #$cnt ${city.name}, ${city.provinceName} - added, path: ${m.path}');
        return city;
      } else {
        print(
            'CountryGenerator.addCity - ********** country ${country.name} not found');
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }

  static Future<CountryDTO> addCountry(CountryDTO country) async {
    try {
      var qs = await fs
          .collection('countries')
          .where('name', isEqualTo: country.name)
          .getDocuments();
      if (qs.documents.isEmpty) {
        await fs.collection('countries').add(country.toJson());
        print('### country added');
        return country;
      } else {
        print(
            'CountryGenerator.addCountry country ${country.name} exists already');
        return CountryDTO.fromJson(qs.documents.first.data);
      }
    } catch (e) {
      print(e);
      throw e;
    }
  }
}
/*
{-KTyxGqJXsRctHp9ztpW: {date: 1476377517226, latitude: 0, name: Lesotho, countryID: -KTyxGqJXsRctHp9ztpW, longitude: 0}, -KTyxMJ9ezgvpLJSRB79: {date: 1476377539617, latitude: 0, name: Namibia, countryID: -KTyxMJ9ezgvpLJSRB79, longitude: 0}, -KVQQAu9iFQjn0doksM1: {date: 1477928860012, latitude: 0, name: Botswana, countryID: -KVQQAu9iFQjn0doksM1, longitude: 0}, -KUm0hZ5Wg7UwCH_G5K8: {date: 1477234316948, latitude: 0, name: Ghana, countryID: -KUm0hZ5Wg7UwCH_G5K8, longitude: 0}, -KTyxEeQfOFzmbHREtFx: {date: 1476377508274, latitude: 0, name: Swaziland, countryID: -KTyxEeQfOFzmbHREtFx, longitude: 0}, -KVQM9tt3vhVQBG5jfds: {date: 1477927807322, latitude: 0, name: Sweden, countryID: -KVQM9tt3vhVQBG5jfds, longitude: 0}, -KTyxBZ1_tV4asRFzpy1: {date: 1476377495576, latitude: 0, name: South Africa, countryID: -KTyxBZ1_tV4asRFzpy1, longitude: 0}, -KUmaazYQr0N3kXP8vv5: {date: 1477243988889, latitude: 0, name: Kenya, countryID: -KUmaazYQr0N3kXP8vv5, longitude: 0}, -KsDgPMDOHMST8wuwzrF: {date: 1503485076985, latitude: 0, na
I/flutter ( 9634): ListAPI.filter, list of vehicle tyafricapes for Brits Taxi Group: 3
*/
