import 'package:aftarobotlibrary/api/data_api.dart';
import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/data/citydto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

abstract class CountryListener {
  onCountry(CountryDTO country);
}

abstract class CityListener {
  onCity(CityDTO city);
  onCities(List<CityDTO> cities);
}

class CountryGenerator {
  static Firestore fs = Firestore.instance;
  static FirebaseDatabase fb = FirebaseDatabase.instance;

  static Future<List<CityDTO>> getCountryCities(String countryPath) async {
    List<CityDTO> list = List();
    var start = DateTime.now();
    var qs = await fs.document(countryPath).collection('cities').getDocuments();
    qs.documents.forEach((doc) {
      var map = doc.data;
      list.add(CityDTO.fromJson(map));
    });

    await LocalDB.saveCities(Cities(list));
    print(
        '\n\n\nCountryGenerator.getCountryCities +++++++++++ cached ${list.length} cities in local cache');
    var end = DateTime.now();
    print(
        'CountryGenerator.getCountryCities ########### found ${list.length} - elapsed ${end.difference(start).inSeconds}');
    return list;
  }

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
        var mCountry = await addCountry(country);
        listener.onCountry(mCountry);
        list.add(mCountry);
      }
    } catch (e) {
      print(e);
      throw e;
    }
    return list;
  }

  static List<CityDTO> countryCities = List(), newCities = List();

  static Future<List<CityDTO>> copyCitiesToFirestore(
      {List<CityDTO> cities, CountryDTO country, CityListener listener}) async {
    var start = DateTime.now();
    print(
        '\n\n\nCountryGenerator.copyCitiesToFirestore -- #################### start loading cities');
    var qs =
        await fs.document(country.path).collection('cities').getDocuments();
    qs.documents.forEach((doc) {
      countryCities.add(CityDTO.fromJson(doc.data));
    });
    print(
        "@@@@@@@@@@@@@@ existing cities found on Firestore: ${countryCities.length}\n\n");
    int badCnt = 0, goodCnt = 0;
    List<CityDTO> citiesToCopy = List();

    for (var city in cities) {
      city.countryID = country.countryID;
      city.countryName = country.name;
      city.countryPath = country.path;
      var isFound = false;
      countryCities.forEach((cc) {
        if (cc.name == city.name) {
          if (cc.provinceName == city.provinceName) {
            isFound = true;
          }
        }
      });
      var isFound2 = false;
      newCities.forEach((cc) {
        if (cc.name == city.name) {
          if (cc.provinceName == city.provinceName) {
            isFound2 = true;
          }
        }
      });

      if (!isFound && !isFound2) {
        citiesToCopy.add(city);
        goodCnt++;
      } else {
        badCnt++;
        listener.onCity(null);
      }
    }
    print(
        'CountryGenerator.copyCitiesToFirestore: ############# completed filtering, good: $goodCnt bad: $badCnt');
    print(
        '## starting _pageCities to arrange cities in batches of $MAX_CITY_DOCUMENTS to cut down calls');

    var results = await _breakCitiesIntoBatches(
        mCities: citiesToCopy, listener: listener);
    //save cities on disk
    print(
        '\n\n############ saving cities on disk ${results.length}. ... Migration almost done :):)');
    await LocalDB.saveCities(Cities(results));
    var end = DateTime.now();
    print(
        '\n\nCountryGenerator.copyCitiesToFirestore: COMPLETED: elapsed: ${end.difference(start).inMinutes}');
    return results;
  }

  static Future<List<CityDTO>> _breakCitiesIntoBatches(
      {List<CityDTO> mCities, CityListener listener}) async {
    print(
        '\n\nCountryGenerator.___breakCitiesIntoBatches .... breaking up ${mCities.length} cities into multiple batches\n\n');
    var rem = mCities.length % MAX_CITY_DOCUMENTS;
    var pages = mCities.length ~/ MAX_CITY_DOCUMENTS;
    if (rem > 0) {
      pages++;
    }
    print(
        'CountryGenerator.__pageCities: calculated: remainder: $rem batches: $pages - is this fucking right????');
    List<CityDTO> results = List();
    List<CityPage> cityPages = List();
    int mainIndex = 0;
    for (var i = 0; i < pages; i++) {
      try {
        var vPage = CityPage();
        vPage.cities = List();
        for (var j = 0; j < MAX_CITY_DOCUMENTS; j++) {
          vPage.cities.add(mCities.elementAt(mainIndex));
          mainIndex++;
        }
        cityPages.add(vPage);
        print(
            'CountryGenerator.__pageCities page #${i + 1} has ${vPage.cities.length} cars, mainIndex: $mainIndex');
      } catch (e) {
        _getLastPage(mainIndex, e, cityPages, mCities, i);
      }
    }
    print(
        '\n\n\nCountryGenerator.__pageCities --- broke up cities into number of pages: ${cityPages.length} , MAX_DOCUMENTS: $MAX_CITY_DOCUMENTS');

    var pageSuccessCount = 1;
    for (var mPage in cityPages) {
      var resultCities = await DataAPI.addCities(cities: mPage.cities);
      print(
          'CountryGenerator._pageCities ++++++ cities added to Firestore: ${resultCities.length} - batch #$pageSuccessCount of $pages');
      newCities.addAll(resultCities);
      results.addAll(resultCities);
      listener.onCities(resultCities);
      pageSuccessCount++;
    }

    return results;
  }

  static void _getLastPage(int mainIndex, e, List<CityPage> cityPages,
      List<CityDTO> mCities, int i) {
    print('CountryGenerator._getLastPage ERROR  mainIndex: $mainIndex --- $e');
    var newIndex = (cityPages.length * MAX_CITY_DOCUMENTS);
    print(
        'CountryGenerator._getLastPage ---------> last page starting index: $newIndex');
    var lastPage = CityPage();
    lastPage.cities = List();
    for (var i = newIndex; i < mCities.length; i++) {
      lastPage.cities.add(mCities.elementAt(i));
    }
    cityPages.add(lastPage);
    print(
        'CountryGenerator._getLastPage page #${i + 1} has ${lastPage.cities.length} cities, newIndex: $newIndex');
  }

  static const MAX_CITY_DOCUMENTS = 100;
  static Future<CityDTO> _addCity({CityDTO city, CountryDTO country}) async {
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
        newCities.add(city);
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
    return null;
  }

  static Future<CountryDTO> addCountry(CountryDTO country) async {
    try {
      var qs = await fs
          .collection('countries')
          .where('name', isEqualTo: country.name)
          .getDocuments();

      if (qs == null || qs.documents == null || qs.documents.isEmpty) {
        print(
            'CountryGenerator.addCountry - no country found - should go write country');

        var ref0 = await fs.collection('countries').add(country.toJson());
        country.path = ref0.path;
        await ref0.setData(country.toJson());
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

class CityPage {
  List<CityDTO> cities;

  CityPage({this.cities});
}
