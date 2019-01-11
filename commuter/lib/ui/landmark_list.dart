import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:commuter/bloc/commuter_bloc.dart';
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
                      landmark: _landmarks.elementAt(index));
                }),
          );
        });
  }
}

class LandmarkCard extends StatelessWidget {
  final LandmarkDTO landmark;

  LandmarkCard({this.landmark});

  _startTaxiRequest() {}
  _searchForTaxis() {}
  final List<PopupMenuItem<String>> menuItems = List();
  _buildMenuItems() {
    menuItems.clear();
    menuItems.add(PopupMenuItem<String>(
      value: '',
      child: GestureDetector(
        onTap: _startTaxiRequest,
        child: ListTile(
          leading: Icon(
            Icons.edit,
            color: getRandomColor(),
          ),
          title: Text('Request Taxi', style: Styles.blackSmall),
        ),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: '',
      child: GestureDetector(
        onTap: _searchForTaxis,
        child: ListTile(
          leading: Icon(
            Icons.airport_shuttle,
            color: getRandomColor(),
          ),
          title: Text(
            'Taxis at Landmark',
            style: Styles.blackSmall,
          ),
        ),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: '',
      child: ListTile(
        leading: Icon(
          Icons.people,
          color: getRandomColor(),
        ),
        title: Text('Commuters at Landmark', style: Styles.blackSmall),
      ),
    ));
    menuItems.add(PopupMenuItem<String>(
      value: '',
      child: ListTile(
        leading: Icon(
          Icons.map,
          color: getRandomColor(),
        ),
        title: Text('Route Map', style: Styles.blackSmall),
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
                  '${landmark.landmarkName}',
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
                  '${landmark.routeName}',
                  style: Styles.blackSmall,
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
