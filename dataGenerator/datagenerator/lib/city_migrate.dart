import 'dart:convert';
import 'dart:io';

import 'package:aftarobotlibrary/data/citydto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/util/city_map_search.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:datagenerator/country_gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_document_picker/flutter_document_picker.dart';

class CityMigrator extends StatefulWidget {
  @override
  _CityMigratorState createState() => _CityMigratorState();
}

class _CityMigratorState extends State<CityMigrator>
    implements
        CountryListener,
        CountryListListener,
        CityListener,
        SnackBarListener {
  List<CountryDTO> countries;
  List<CityDTO> cities = List();
  ScrollController scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  int counter = 0;
  String mTitle;
  bool isBusy = false;
  @override
  void initState() {
    super.initState();
    _getCountries();
  }

  void _getCountries() async {
    setState(() {
      if (countries != null) {
        countries.clear();
      }
    });
    print('_CityMigratorState._getCountries --------------------------');
    await CountryGenerator.generateCountries(this);
    countries = await CountryGenerator.getCountries();
    print('countries found: ${countries.length}');
    setState(() {});
  }

  void _pickImportFile() async {
    if (isBusy) return;
    //open picker
    FlutterDocumentPickerParams params = FlutterDocumentPickerParams(
      allowedFileExtensions: ['csv'],
      invalidFileNameSymbols: ['/'],
    );

    final path = await FlutterDocumentPicker.openDocument(params: params);
    print('picked file: $path');
    // picked file: /data/user/0/com.aftarobot.datagenerator/cache/cities.csv

    if (path == null) {
      isBusy = false;
      return;
    }
    File csvFile = new File(path);
    bool fileExists = await csvFile.exists();
    if (fileExists) {
      print('_CityMigratorState._pickImportFile - we have a file!');
      var len = await csvFile.length();
      print('##################### file length: $len');
      isBusy = true;
      Stream<List<int>> stream = csvFile.openRead();
      stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        var strings = line.split(',');
        var name = strings.elementAt(1);
        var prov = strings.elementAt(2);
        var lat = strings.elementAt(3);
        var lng = strings.elementAt(4);
        CityDTO city = CityDTO(
            cityID: getKey(),
            name: name,
            provinceName: prov,
            latitude: double.parse(lat),
            longitude: double.parse(lng),
            date: DateTime.now().millisecondsSinceEpoch,
            countryID: country.countryID,
            countryName: country.name);
        cities.add(city);
        setState(() {
          counter++;
        });

//        print('${lineNumber++} - $name $prov $lat $lng');
      }).onDone(() {
        isBusy = false;
        print(
            '\n\n_CityMigratorState._pickImportFile -------- ########### COMPLETED import, ${cities.length} cities ready to rumble!!!');
        _migrateCities();
      });
    }
  }

  void _showDialog() {
    if (isBusy) return;
    showDialog(
        context: context,
        builder: (_) => new AlertDialog(
              title: new Text(
                "Import Cities CSV File",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor),
              ),
              content: Container(
                height: 120.0,
                child: Column(
                  children: <Widget>[
                    Text(
                      country.name,
                      style: Styles.blackBoldMedium,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                          'Do you want to import cities using a .csv file?'),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                FlatButton(
                  child: Text(
                    'NO',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20.0),
                  child: RaisedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (isBusy) {
                      } else {
                        _pickImportFile();
                      }
                    },
                    elevation: 4.0,
                    color: Colors.teal.shade500,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Start File Import',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ));
  }

  void _startCityMapSearch() {
    print('_CityMigratorState._startCityMapSearch ..........');
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => CityMapSearch()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text("AftaRobot Migrator"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _startCityMapSearch,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(160.0),
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20.0, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Text(
                        country == null
                            ? 'Migrating Country Cities'
                            : country.name,
                        style: Styles.whiteBoldLarge),
                  ],
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  RaisedButton(
                    elevation: 8.0,
                    color: Colors.purple,
                    onPressed: _migrateCities,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Migrate Cities',
                        style: Styles.whiteSmall,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20.0,
                  ),
                  Column(
                    children: <Widget>[
                      Text(
                        '$counter',
                        style: Styles.blackBoldReallyLarge,
                      ),
                      Text(
                        'Cities Imported',
                        style: Styles.blackSmall,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(
                height: 30.0,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.purple.shade200,
      ),
      backgroundColor: Colors.brown.shade50,
      body: countries == null
          ? Container(
              child: Center(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Countries loading ....',
                          style: Styles.blackBoldMedium),
                    ),
                  ],
                ),
              ),
            )
          : CountryList(
              countries: countries,
              scrollController: scrollController,
              isBusy: isBusy,
              listener: this,
            ),
    );
  }

  @override
  onCountry(CountryDTO country) {
    if (countries == null) {
      countries = List();
    }
    setState(() {
      countries.add(country);
    });
  }

  CountryDTO country;
  @override
  onCountryPicked(CountryDTO country) async {
    if (isBusy) return;
    this.country = country;
    print('\n\n_CityMigratorState.onCountryPicked -- ${country.name}');
    _showDialog();
  }

  void _migrateCities() async {
    if (cities == null || cities.isEmpty) {
      print(
          '_CityMigratorState._migrateCities --- NO CITIES to migrate. quitting ...');
      _errorSnack('Please import a country\'s cities first');
      return;
    }
    if (isBusy) return;
    if (country == null) {
      print('_CityMigratorState._migrateCities ---select country and ...');
      _errorSnack('Please select a country to import cities for');
      return;
    }
    setState(() {
      counter = 0;
      isBusy = true;
    });

    await CountryGenerator.copyCitiesToFirestore(
        cities: cities, country: country, listener: this);
    print(
        '_CityMigratorState._migrateCities --- CITY MIGRATION completed! Yay!!');
  }

  void _errorSnack(String message) {
    AppSnackbar.showErrorSnackbar(
        scaffoldKey: _key, message: message, listener: this, actionLabel: 'ok');
  }

  List<CityDTO> activeCities = List();
  @override
  onCity(CityDTO city) {
    print(
        '\n\n_CityMigratorState.onCity ......==============.......... $city #$counter');
    if (city == null) {
      setState(() {
        counter++;
      });
      return;
    }
    assert(country != null);
    if (country.cities == null) {
      country.cities = List();
    }
    country.cities.add(city);
    setState(() {
      activeCities.add(city);
      counter++;
    });
  }

  @override
  onCities(List<CityDTO> cities) {
    print(
        '\n\n_CityMigratorState.onCities .................. cities arrived: ${cities.length}');
    assert(country != null);
    if (country.cities == null) {
      country.cities = List();
    }
    country.cities.addAll(cities);
    setState(() {
      counter += cities.length;
      activeCities.addAll(cities);
    });
  }

  @override
  onActionPressed(int action) {
    // TODO: implement onActionPressed
    return null;
  }
}

class CountryCard extends StatelessWidget {
  final CountryDTO country;
  final Color color;
  final TextStyle style;
  final double elevation;
  final CountryListListener listener;

  CountryCard(
      {@required this.country,
      this.color,
      this.style,
      this.elevation,
      this.listener});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        listener.onCountryPicked(country);
      },
      child: Card(
        color: color == null ? Colors.white : color,
        elevation: elevation == null ? 2.0 : elevation,
        child: ListTile(
          leading: Icon(
            Icons.language,
            color: getRandomColor(),
          ),
          title: Text(
            country.name,
            style: style == null ? Styles.blackSmall : style,
          ),
          subtitle: Text(
            country.countryID,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

abstract class CountryListListener {
  onCountryPicked(CountryDTO country);
}

class CountryList extends StatelessWidget {
  final List<CountryDTO> countries;
  final ScrollController scrollController;
  final CountryListListener listener;
  final bool isBusy;
  CountryList(
      {this.countries, this.scrollController, this.listener, this.isBusy});

  void _ignore() {
    print('Listener is null. wtf??');
  }

  void onCountryPicked() {
    print('country has been picked, yay!');
    listener.onCountryPicked(country);
  }

  CountryDTO country;
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isBusy == null || isBusy == false) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOut,
        );
      } else {
        print('am not doin anythin, Boss!... youse busy ...');
      }
    });

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ListView.builder(
            itemCount: countries == null ? 0 : countries.length,
            controller: scrollController,
            itemBuilder: (BuildContext context, int index) {
              country = countries.elementAt(index);
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: GestureDetector(
                  onTap: listener == null ? _ignore : onCountryPicked,
                  child: CountryCard(
                    elevation: 4.0,
                    color: getRandomPastelColor(),
                    listener: listener,
                    style: Styles.brownBoldMedium,
                    country: countries.elementAt(index),
                  ),
                ),
              );
            }),
      ),
    );
  }
}
