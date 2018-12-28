import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/api/list_api.dart';
import 'package:aftarobotlibrary/data/citydto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class CityMapSearch extends StatefulWidget {
  final LandmarkDTO landmark;
  final RouteDTO route;

  CityMapSearch({this.landmark, this.route});

  @override
  _CityMapSearchState createState() => _CityMapSearchState();
}

class _CityMapSearchState extends State<CityMapSearch>
    implements CitySearchBoxListener {
  GoogleMapController _mapController;
  GlobalKey<AutoCompleteTextFieldState<CityDTO>> _autoCompleteKey =
      new GlobalKey();
  List<CityDTO> cities;
  CityDTO city;
  RouteDTO route;
  double mLatitude, mLongitude;
  Location _location = new Location();
  Map<String, double> _startLocation;
  TextEditingController _textEditingController = TextEditingController();
  bool _permission = false;
  String error;
  double bottomHeight;
  bool mapIsReady = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    if (widget.landmark != null) {
      _getRoute();
    }
  }

  void _getRoute() async {
    print('_CityMapSearchState._getRoute ......................');
    try {
      if ((widget.landmark.routeID != null)) {
        route = await ListAPI.getRouteByID(widget.landmark.routeID);
        prettyPrint(route.toJson(), '################### ROUTE:');
        _setRouteMarkers(route);
      }
    } catch (e) {
      print(e);
    }
  }

  initPlatformState() async {
    print('_ContactUsState.initPlatformState ..............................');
    Map<String, double> location;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      _permission = await _location.hasPermission();
      location = await _location.getLocation();
      print(
          '_ContactUsState.initPlatformState permission: $_permission location: $location');
      error = null;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'Permission denied';
      } else if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error =
            'Permission denied - please ask the user to enable it from the app settings';
      }

      location = null;
    }

    if (location != null) {}
    setState(() {
      _startLocation = location;
    });
  }

  void _setRouteMarkers(RouteDTO mRoute) {
    print('_CityMapSearchState._setRouteMarkers ****************************');
    if (!mapIsReady) {
      print('_CityMapSearchState._setRouteMarkers ------ map is NOT ready');
      return;
    }
    try {
      mRoute.spatialInfos.forEach((si) {
        _mapController.animateCamera(CameraUpdate.newCameraPosition(
            CameraPosition(
                target:
                    LatLng(si.fromLandmark.latitude, si.fromLandmark.longitude),
                zoom: 12.0)));

        _mapController.addMarker(MarkerOptions(
          position: LatLng(si.fromLandmark.latitude, si.fromLandmark.longitude),
          icon: BitmapDescriptor.fromAsset('assets/computers.png'),
          zIndex: 4.0,
          infoWindowText: InfoWindowText('${si.fromLandmark.landmarkName}',
              '${si.fromLandmark.routeName}'),
        ));
      });
    } catch (e) {
      print(e);
    }
  }

  void controlMap() {
    _mapController.updateMapOptions(GoogleMapOptions(
        zoomGesturesEnabled: true,
        myLocationEnabled: true,
        compassEnabled: true,
        mapType: MapType.normal));

    if (city == null && widget.landmark == null) {
      print('_CityMapSearchState.setMapStuff -------- city is null. quit!');
      return;
    }
    if (city != null) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target: LatLng(city.latitude, city.longitude), zoom: 12.0)));
      _mapController.addMarker(MarkerOptions(
        position: LatLng(city.latitude, city.longitude),
        icon: BitmapDescriptor.fromAsset('assets/computers.png'),
        zIndex: 4.0,
        infoWindowText: InfoWindowText('${city.name}', '${city.provinceName}'),
      ));
    }
    if (widget.landmark != null) {
      _mapController.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(
              target:
                  LatLng(widget.landmark.latitude, widget.landmark.longitude),
              zoom: 12.0)));
      _mapController.addMarker(MarkerOptions(
        position: LatLng(widget.landmark.latitude, widget.landmark.longitude),
        icon: BitmapDescriptor.fromAsset('assets/computers.png'),
        zIndex: 4.0,
        infoWindowText: InfoWindowText('${widget.landmark.landmarkName}',
            '${widget.landmark.routeName} - ${widget.landmark.rankSequenceNumber}'),
      ));
    }
  }

  bool showMap = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('City Map Search'),
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: (controller) {
              print('_ContactUsState.build ------ onMapCreated');
              _mapController = controller;
              mapIsReady = true;
              if (widget.route != null) {
                _setRouteMarkers(widget.route);
              } else {
                controlMap();
              }
            },
            options: GoogleMapOptions(
              myLocationEnabled: true,
              compassEnabled: true,
              zoomGesturesEnabled: true,
            ),
          ),
          CitySearchBox(
            listener: this,
          ),
        ],
      ),
    );
  }

  void _onPressed() {
    print('_CityMapSearch._onPressed ...');
//    Navigator.push(
//      context,
//      new MaterialPageRoute(builder: (context) => IntroPageView(items: sampleItems, user: user)),
//    );
  }

  int toggle = 0;
  void _onMapTypeToggle() {
    if (toggle == null) {
      toggle = 0;
    } else {
      if (toggle == 0) {
        toggle = 1;
      } else {
        if (toggle == 1) {
          toggle = 2;
        } else {
          if (toggle == 2) {
            toggle = 0;
          }
        }
      }
    }
    switch (toggle) {
      case 0:
        _doNormalMap();
        break;
      case 1:
        _doTerrainMap();
        break;
      case 2:
        _doSatelliteMap();
        break;
    }
  }

  void _doTerrainMap() {
    _mapController.updateMapOptions(GoogleMapOptions(
        zoomGesturesEnabled: true,
        myLocationEnabled: true,
        compassEnabled: true,
        mapType: MapType.terrain));
  }

  void _doSatelliteMap() {
    _mapController.updateMapOptions(GoogleMapOptions(
        zoomGesturesEnabled: true,
        myLocationEnabled: true,
        compassEnabled: true,
        mapType: MapType.satellite));
  }

  void _doNormalMap() {
    _mapController.updateMapOptions(GoogleMapOptions(
        zoomGesturesEnabled: true,
        myLocationEnabled: true,
        compassEnabled: true,
        mapType: MapType.normal));
  }

  @override
  onCityPicked(CityDTO city) {
    print(
        '\n\n_CityMapSearchState.onCityPicked +++++++++ city selected: ${city.name} -- YEBO!!!!!');
    this.city = city;
    controlMap();
  }

  @override
  onError(String message) {
    // TODO: implement onError
    return null;
  }
}

abstract class CitySearchBoxListener {
  onCityPicked(CityDTO city);
  onError(String message);
}

class CitySearchBox extends StatefulWidget {
  final CitySearchBoxListener listener;
  final TextStyle textStyle;
  final Icon icon;

  CitySearchBox({this.listener, this.textStyle, this.icon});

  @override
  _CitySearchBoxState createState() => _CitySearchBoxState();
}

class _CitySearchBoxState extends State<CitySearchBox> {
  List<CityDTO> cities, filteredCities;
  ScrollController scrollController = ScrollController();
  TextEditingController textEditingController = TextEditingController();
  GlobalKey<AutoCompleteTextFieldState<CityDTO>> _globalKey = GlobalKey();
  bool toggle = false;
  CityDTO city;
  @override
  void initState() {
    super.initState();
    _getCities();
  }

  void _getCities() async {
    print('\n\n_CitySearchBoxState._getCities  ++++++ get all cities ....');
    var start = DateTime.now();
    try {
      cities = await LocalDB.getCities();
      print(
          '_CitySearchBoxState._getCities  - local city cache has: ${cities.length}');
      cities = await ListAPI.getSouthAfricanCities(forceRefresh: true);
      var end = DateTime.now();
      print(
          '_CitySearchBoxState._getCities - city shit took ${end.difference(start).inMilliseconds} '
          'milliseconds, cities: ${cities.length}');
    } catch (e) {
      widget.listener.onError(e.message);
    }
    setState(() {});
  }

  void _findCitiesFromText(String query) {
    print('_CitySearchBoxState._findCitiesFromText, .. find $query');
    setState(() {
      filteredCities = null;
    });
    filteredCities = List();
    for (int i = 0; i < cities.length; i++) {
      CityDTO city = cities.elementAt(i);
      if ((city.name).toLowerCase().contains(query.toLowerCase())) {
        filteredCities.add(city);
      }
    }
    print(
        '_CitySearchBoxState._findCitiesFromText ############## filteredCities|: ${filteredCities.length}');
    if (filteredCities.isNotEmpty) {
      setState(() {
        toggle = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        '_CitySearchBoxState.build ************* REBUILD *************** ${DateTime.now().toUtc().toIso8601String()}');
    if (filteredCities != null) {
      print(
          '_CitySearchBoxState.build ************* REBUILD, filteredCities: ${filteredCities.length} ${widget.listener}');
    } else {
      print(
          '_CitySearchBoxState.build ------------------- <<<< filtered is NULL, we are not searching ...!${DateTime.now().toUtc().toIso8601String()}');
    }
    return cities == null
        ? Container()
        : Column(
            children: <Widget>[
              AutoCompleteTextField<CityDTO>(
                key: _globalKey,
                keyboardType: TextInputType.text,
                suggestions: cities,
                itemFilter: (item, query) {
                  return item.name
                      .toLowerCase()
                      .startsWith(query.toLowerCase());
                },
                itemBuilder: (context, item) {
                  return CitySearchCard(
                    city: item,
                  );
                },
                itemSubmitted: (CityDTO data) {
                  _tellCaller(data);
                },
                itemSorter: (CityDTO a, CityDTO b) {
                  return a.name.compareTo(b.name);
                },
                decoration: InputDecoration(
                    hintText: 'Tap here to search cities ...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(4.0)),
                    )),
              ),
            ],
          );
  }

  void _tellCaller(CityDTO data) {
    print('_CitySearchBoxState._tellCaller');
    prettyPrint(data.toJson(),
        '############################# SELECTED CITY: passing to listener');
    widget.listener.onCityPicked(data);
  }
}

class CitySearchCard extends StatelessWidget {
  final CityDTO city;

  CitySearchCard({this.city});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      color: Colors.brown.shade50,
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Icon(Icons.search),
          ),
          Text(city.name),
        ],
      ),
    );
  }
}
