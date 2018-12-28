import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/data/citydto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchList extends StatefulWidget {
  SearchList({Key key}) : super(key: key);

  @override
  _SearchListState createState() => new _SearchListState.searchListState();
}

class _SearchListState extends State<SearchList> {
  GoogleMapController _mapController;
  Widget appBarTitle = Text(
    "",
    style: TextStyle(color: Colors.white),
  );
  Icon actionIcon = Icon(
    Icons.search,
    color: Colors.white,
  );
  final key = GlobalKey<ScaffoldState>();
  final TextEditingController _searchTextEditingController =
      TextEditingController();
  List<CityDTO> _list;
  List<CityDTO> cities;
  bool _isSearching;
  String _searchText = "";
  String selectedSearchValue = "";

  _SearchListState.searchListState() {
    _searchTextEditingController.addListener(() {
      if (_searchTextEditingController.text.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchText = "";
        });
      } else {
        setState(() {
          _isSearching = true;
          _searchText = _searchTextEditingController.text;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _isSearching = true;
    _createCityList();
  }

  CityDTO city;
  void setMapStuff() {
    _mapController.updateMapOptions(GoogleMapOptions(
        zoomGesturesEnabled: true,
        myLocationEnabled: true,
        compassEnabled: true,
        mapType: MapType.normal));

    if (city == null) {
      print('_CityMapSearchState.setMapStuff -------- city is null. quit!');
      return;
    }
    _mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(city.latitude, city.longitude), zoom: 12.0)));
    _mapController.addMarker(MarkerOptions(
      position: LatLng(city.latitude, city.longitude),
//      icon: BitmapDescriptor.fromAsset('assets/computers.png'),
      zIndex: 4.0,
      infoWindowText: InfoWindowText('${city.name}', '${city.provinceName}'),
    ));
  }

  void _createCityList() async {
    cities = await LocalDB.getCities();
    _list = List();
    cities.forEach((city) {
      var res = city;
      _list.add(res);
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        key: key,
        appBar: buildBar(context),
        body: new Stack(
          children: <Widget>[
            GoogleMap(
              onMapCreated: (controller) {
                print('_ContactUsState.build ------ onMapCreated');
                _mapController = controller;
                setMapStuff();
              },
              options: GoogleMapOptions(
                myLocationEnabled: true,
                compassEnabled: true,
                zoomGesturesEnabled: true,
              ),
            ),
            _displaySearchResults(),
          ],
        ));
  }

  Widget _displaySearchResults() {
    if (_isSearching) {
      return new Align(alignment: Alignment.topCenter, child: getListView());
    } else {
      return new Align(alignment: Alignment.topCenter, child: Container());
    }
  }

  ListView getListView() {
    List<CityDTO> results = _buildSearchList();
    return ListView.builder(
      itemCount: _buildSearchList().isEmpty == null ? 0 : results.length,
      itemBuilder: (context, int index) {
        return SizedBox(
          width: 200.0,
          child: Card(
            child: ListTile(
              onTap: () {
                print(
                    '_SearchListState.searchList on fucking tapped! ${results.elementAt(index).name}');
                setState(() {
                  _isSearching = false;
                });
                city = results.elementAt(index);
                prettyPrint(
                    city.toJson(), '*********************** onTap, city:');
                setMapStuff();
              },
              title: Text(results.elementAt(index).name,
                  style: new TextStyle(fontSize: 18.0)),
              leading: Icon(Icons.search),
            ),
          ),
        );
      },
    );
  }

  List<CityDTO> _buildSearchList() {
    if (_searchText.isEmpty) {
      return _list.map((result) => result).toList();
    } else {
      List<CityDTO> _searchList = List();
      for (int i = 0; i < _list.length; i++) {
        CityDTO result = _list.elementAt(i);
        if ((result.name).toLowerCase().contains(_searchText.toLowerCase())) {
          _searchList.add(result);
        }
      }
      return _searchList.map((result) => result).toList();
    }
  }

  Widget buildBar(BuildContext context) {
    return new AppBar(
      centerTitle: true,
      title: appBarTitle,
      actions: <Widget>[
        new IconButton(
          icon: actionIcon,
          onPressed: () {
            _displayTextField();
          },
        ),

        // new IconButton(icon: new Icon(Icons.more), onPressed: _IsSearching ? _showDialog(context, _buildSearchList()) : _showDialog(context,_buildList()))
      ],
    );
  }

  void _displayTextField() {
    setState(() {
      if (this.actionIcon.icon == Icons.search) {
        this.actionIcon = new Icon(
          Icons.close,
          color: Colors.white,
        );
        this.appBarTitle = new TextField(
          autofocus: true,
          controller: _searchTextEditingController,
          style: new TextStyle(
            color: Colors.white,
          ),
        );

        _handleSearchStart();
      } else {
        _handleSearchEnd();
      }
    });
  }

  void _handleSearchStart() {
    setState(() {
      _isSearching = true;
    });
  }

  void _handleSearchEnd() {
    setState(() {
      this.actionIcon = new Icon(
        Icons.search,
        color: Colors.white,
      );
      this.appBarTitle = new Text(
        "",
        style: new TextStyle(color: Colors.white),
      );
      _isSearching = false;
      _searchTextEditingController.clear();
    });
  }
}
