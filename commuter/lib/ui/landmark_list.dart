import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:commuter/bloc/commuter_bloc.dart';
import 'package:commuter/ui/commuter_request_page.dart';
import 'package:commuter/ui/landmark_map.dart';
import 'package:flutter/material.dart';

class LandmarkList extends StatefulWidget {
  @override
  LandmarkListState createState() {
    return new LandmarkListState();
  }
}

class LandmarkListState extends State<LandmarkList> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  CommuterBloc _bloc = CommuterBloc();
  List<LandmarkDTO> _landmarks = List();
  @override
  void initState() {
    super.initState();
  }

  void _refresh() {
    _bloc.getCurrentLocation();
  }

  void _startRequestFromNearestLandmark() {
    printLog('_startRequestFromNearestLandmark');
    if (_landmarks.isEmpty) return;

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CommuterRequestPage(
                  landmark: _landmarks.elementAt(0),
                )));
  }

  Widget _buildSummaries() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Summary(
                total: _landmarks.length,
                caption: 'Landmarks',
              ),
              SizedBox(
                width: 20,
              ),
              Summary(
                total: 0,
                caption: 'Taxis Around',
              ),
              SizedBox(
                width: 20,
              ),
              Summary(
                total: 0,
                caption: 'Commuters',
              ),
            ],
          ),
          SizedBox(
            height: 40,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        initialData: _bloc.landmarks,
        stream: _bloc.landmarksStream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              printLog('🔵 ConnectionState.active set data from stream data');
              _landmarks = snapshot.data;
              break;
            case ConnectionState.waiting:
              printLog(' 🎾 onnectionState.waiting .......');
              break;
            case ConnectionState.done:
              printLog(' 🎾 ConnectionState.done ???');
              break;
            case ConnectionState.none:
              printLog(' 🎾 ConnectionState.none - do nuthin ...');
              break;
          }
          return Scaffold(
            key: _key,
            appBar: AppBar(
              title: Text('Taxi Landmarks Around Me'),
              bottom: _buildSummaries(),
              elevation: 16,
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: _refresh,
                ),
              ],
            ),
            backgroundColor: Colors.brown.shade100,
            body: ListView.builder(
                itemCount: _landmarks.length,
                itemBuilder: (context, index) {
                  return new LandmarkCard(
                    landmark: _landmarks.elementAt(index),
                    bloc: _bloc,
                  );
                }),
            bottomNavigationBar: BottomNavigationBar(
                onTap: (index) {
                  switch (index) {
                    case 0:
                      _startRequestFromNearestLandmark();
                      break;
                  }
                },
                items: _barItems),
          );
        });
  }

  List<BottomNavigationBarItem> _barItems = [
    BottomNavigationBarItem(
      title: Text('Request Taxi'),
      icon: Icon(Icons.airport_shuttle),
    ),
    BottomNavigationBarItem(
      title: Text('Ride Vouchers'),
      icon: Icon(Icons.cake),
    ),
    BottomNavigationBarItem(
      title: Text('Panic'),
      icon: Icon(
        Icons.dialpad,
        color: Colors.pink,
      ),
    ),
  ];
}

class LandmarkCard extends StatefulWidget {
  final LandmarkDTO landmark;
  final CommuterBloc bloc;
  LandmarkCard({@required this.landmark, @required this.bloc});

  @override
  LandmarkCardState createState() {
    return new LandmarkCardState();
  }
}

class LandmarkCardState extends State<LandmarkCard> {
  _startTaxiRequest() {}

  _searchForTaxis() {}

  final List<PopupMenuItem<String>> menuItems = List();

  _buildMenuItems() {
    menuItems.clear();
    menuItems.add(PopupMenuItem<String>(
      value: '',
      child: GestureDetector(
        onTap: _startTaxiRequest,
        child: Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(
              Icons.edit,
              color: getRandomColor(),
            ),
            title: Text('Request Taxi', style: Styles.blackSmall),
          ),
        ),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: '',
      child: GestureDetector(
        onTap: _searchForTaxis,
        child: Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(
              Icons.airport_shuttle,
              color: getRandomColor(),
            ),
            title: Text(
              'Taxis',
              style: Styles.blackSmall,
            ),
          ),
        ),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: '',
      child: Card(
        elevation: 2,
        child: ListTile(
          leading: Icon(
            Icons.people,
            color: getRandomColor(),
          ),
          title: Text('Commuters', style: Styles.blackSmall),
        ),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: '',
      child: GestureDetector(
        onTap: _startLandmarkMap,
        child: Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(
              Icons.map,
              color: getRandomColor(),
            ),
            title: Text('Route Map', style: Styles.blackSmall),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    _buildMenuItems();
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16, top: 4),
      child: Card(
        elevation: 4,
        color: getRandomPastelColor(),
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                PopupMenuButton<String>(
                  itemBuilder: (context) {
                    return menuItems;
                  },
                ),
              ],
            ),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 12,
                ),
                Icon(
                  Icons.my_location,
                  color: getRandomColor(),
                ),
                SizedBox(
                  width: 12,
                ),
                Text(
                  '${widget.landmark.landmarkName}',
                  style: Styles.blackBoldMedium,
                ),
              ],
            ),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 48,
                ),
                Text(
                  '${widget.landmark.routeName}',
                  style: Styles.blackSmall,
                ),
              ],
            ),
            SizedBox(
              height: 8,
            ),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 48,
                ),
                Text(
                  'Distance away: ',
                  style: Styles.blackSmall,
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  '${_getFormattedDistance(widget.landmark.distance)}',
                  style: Styles.blackBoldSmall,
                ),
              ],
            ),
            SizedBox(
              height: 40,
            )
          ],
        ),
      ),
    );
  }

  String _getFormattedDistance(double distance) {
    if (distance < 20) {
      return 'Arrived';
    }
    if (distance < 1000) {
      return distance.toStringAsFixed(0) + ' metres';
    }
    var km = distance / 1000;
    return km.toStringAsFixed(1) + ' km';
  }

  void _startLandmarkMap() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LandmarkMap(
                  commuterBloc: widget.bloc,
                  landmark: widget.landmark,
                )));
  }
}

class Summary extends StatelessWidget {
  final int total;
  final String caption;
  final TextStyle totalStyle, captionStyle;

  Summary(
      {@required this.total,
      @required this.caption,
      this.totalStyle,
      this.captionStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          '$total',
          style: totalStyle == null ? Styles.blackBoldReallyLarge : totalStyle,
        ),
        SizedBox(
          height: 2,
        ),
        Text(
          caption,
          style: captionStyle == null ? Styles.whiteSmall : captionStyle,
        ),
      ],
    );
  }
}
