import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/api/list_api.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/spatialinfodto.dart';
import 'package:aftarobotlibrary/util/city_map_search.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:flutter/material.dart';

class RouteViewerPage extends StatefulWidget {
  @override
  _RouteViewerPageState createState() => _RouteViewerPageState();
}

class _RouteViewerPageState extends State<RouteViewerPage>
    implements RouteCardListener {
  List<RouteDTO> routes;
  List<LandmarkDTO> landmarks;
  ScrollController scrollController = ScrollController();
  String status = 'AftaRobot Routes';
  int routeCount = 0, landmarkCount = 0;
  List<AssociationDTO> asses = List();
  @override
  void initState() {
    super.initState();
    _getNewRoutes();
  }

  void _setCounters() {
    setState(() {
      routeCount = routes.length;
      landmarkCount = landmarks.length;
    });
  }

  void _getNewRoutes() async {
    routes = await LocalDB.getRoutes();
    landmarks = await LocalDB.getLandmarks();
    if (routes.isEmpty) {
      routes = await ListAPI.getRoutes();
      landmarks = await ListAPI.getLandmarks();
    }
    _setCounters();
  }

  void _refresh() async {
    print('_RouteViewerPageState._refresh .................');
    routes = await ListAPI.getRoutes();
    landmarks = await ListAPI.getLandmarks();
    _setCounters();

    await LocalDB.saveRoutes(Routes(routes));
    await LocalDB.saveLandmarks(Landmarks(landmarks));
    print('_RouteViewerPageState._refresh ------- done. saved data in cache');
  }

  DateTime start, end;

  Widget _getListView() {
    return ListView.builder(
        itemCount: routes == null ? 0 : routes.length,
        controller: scrollController,
        itemBuilder: (BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16, top: 16.0),
            child: RouteCard(
              route: routes.elementAt(index),
              number: index + 1,
              hideLandmarks: switchStatus,
              listener: this,
            ),
          );
        });
  }

  String switchLabel = 'Hide';
  bool switchStatus = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AftaRobot Routes'),
        backgroundColor: Colors.indigo.shade300,
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 8.0),
            child: IconButton(
              onPressed: _refresh,
              iconSize: 28,
              icon: Icon(Icons.my_location),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      SizedBox(
                        width: 20,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '$routeCount',
                            style: Styles.blackBoldLarge,
                          ),
                          Text(
                            'Routes',
                            style: Styles.whiteSmall,
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            '$landmarkCount',
                            style: Styles.blackBoldLarge,
                          ),
                          Text(
                            'Landmarks',
                            style: Styles.whiteSmall,
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 80,
                      ),
                      Column(
                        children: <Widget>[
                          SizedBox(
                            width: 10,
                          ),
                          Text(
                            switchStatus == false ? 'Hide' : 'Show',
                            style: switchStatus == false
                                ? Styles.blackSmall
                                : Styles.yellowBoldSmall,
                          ),
                          Switch(
                            onChanged: _onSwitchChanged,
                            value: switchStatus,
                            activeColor: Colors.yellow,
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _getListView(),
      backgroundColor: Colors.brown.shade100,
    );
  }

  List<LandmarkDTO> newLandmarks = List();

  void _onSwitchChanged(bool value) {
    print('_RouteViewerPageState._onSwitchChanged hideRoutes = $value');
    setState(() {
      switchStatus = value;
    });
  }

  @override
  onRouteTapped(RouteDTO route) {
    print(
        '_RouteViewerPageState.onRouteTapped: &&&&&&&&&&& route: ${route.name}');
    _goToMapSearch(context: context, route: route);
  }

  void _goToMapSearch(
      {BuildContext context, LandmarkDTO landmark, RouteDTO route}) {
    if (route != null) {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => CityMapSearch(
                  route: route,
                )),
      );
    } else {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => CityMapSearch(
                  landmark: landmark,
                )),
      );
    }
  }
}

abstract class RouteCardListener {
  onRouteTapped(RouteDTO route);
}

class RouteCard extends StatefulWidget {
  final RouteDTO route;
  final Color color;
  final int number;
  final bool hideLandmarks;
  final RouteCardListener listener;

  RouteCard(
      {this.route, this.color, this.number, this.hideLandmarks, this.listener});

  @override
  _RouteCardState createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  int index = 0;
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    List<ExpansionPanel> panels = List();
    int mIndex = 0;
    widget.route.spatialInfos.sort((a, b) => a.fromLandmark.rankSequenceNumber
        .compareTo(b.fromLandmark.rankSequenceNumber));

    widget.route.spatialInfos.forEach((si) {
      bool iAmExpanding = false;
      if (index == mIndex) {
        iAmExpanding = isExpanded;
      }
      var panel = ExpansionPanel(
          isExpanded: iAmExpanding,
          body: SpatialInfoPair(
            spatialInfo: si,
            route: widget.route,
          ),
          headerBuilder: (BuildContext context, bool isExpanded) {
            return Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 8.0, bottom: 8),
              child: Text(
                si.fromLandmark.landmarkName,
                style: Styles.blackBoldSmall,
              ),
            );
          });

      panels.add(panel);
      mIndex++;
    });

    return Card(
      elevation: 4.0,
      color: getRandomPastelColor(),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: () {
                print(
                    '_RouteCardState.build --- route name tapped: ${widget.route.name}');
                if (widget.listener != null) {
                  widget.listener.onRouteTapped(widget.route);
                }
              },
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 40,
                    child: Text(
                      widget.number == null ? '0' : '${widget.number}',
                      style: Styles.pinkBoldSmall,
                    ),
                  ),
                  Flexible(
                    child: Container(
                      child: Text(
                        widget.route.name,
                        style: Styles.blackBoldMedium,
                        overflow: TextOverflow.clip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 40,
                ),
                Flexible(
                  child: Container(
                    child: Text(
                      widget.route.associationName,
                      style: Styles.greyLabelSmall,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
            widget.hideLandmarks == true
                ? Container()
                : ExpansionPanelList(
                    children: panels,
                    animationDuration: Duration(milliseconds: 500),
                    expansionCallback: (int index, bool isExpanded) {
                      print(
                          'RouteCard.build - expansionCallback: index: $index isExpanded: $isExpanded - ${DateTime.now().toUtc().toIso8601String()}');
                      setState(() {
                        this.index = index;
                        this.isExpanded = !isExpanded;
                      });
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

class SpatialInfoPair extends StatelessWidget {
  final SpatialInfoDTO spatialInfo;
  final RouteDTO route;

  SpatialInfoPair({this.route, this.spatialInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GestureDetector(
          onTap: () {
            _goToMapSearch(
                context: context, landmark: spatialInfo.fromLandmark);
          },
          child: ListTile(
            title: Row(
              children: <Widget>[
                Text(
                  '${spatialInfo.fromLandmark.rankSequenceNumber}',
                  style: Styles.blueBoldSmall,
                ),
                SizedBox(
                  width: 12,
                ),
                Flexible(
                  child: Container(
                    child: Text(
                      '${spatialInfo.fromLandmark.landmarkName}',
                      style: Styles.blackBoldSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: <Widget>[
                SizedBox(
                  width: 20,
                ),
                Text(
                  '${spatialInfo.fromLandmark.latitude}  ${spatialInfo.fromLandmark.longitude}',
                  style: Styles.greyLabelSmall,
                ),
              ],
            ),
            leading: Icon(
              Icons.my_location,
              color: Colors.teal.shade700,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            _goToMapSearch(context: context, landmark: spatialInfo.toLandmark);
          },
          child: ListTile(
            title: Row(
              children: <Widget>[
                Text(
                  '${spatialInfo.toLandmark.rankSequenceNumber}',
                  style: Styles.blueBoldSmall,
                ),
                SizedBox(
                  width: 12,
                ),
                Flexible(
                  child: Container(
                    child: Text(
                      '${spatialInfo.toLandmark.landmarkName}',
                      style: Styles.blackBoldSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    SizedBox(
                      width: 20,
                    ),
                    Text(
                      '${spatialInfo.toLandmark.latitude}  ${spatialInfo.toLandmark.longitude}',
                      style: Styles.greyLabelSmall,
                    ),
                  ],
                ),
              ],
            ),
            leading: Icon(
              Icons.my_location,
              color: Colors.pink.shade600,
            ),
          ),
        ),
      ],
    );
  }

  void _goToMapSearch(
      {BuildContext context, LandmarkDTO landmark, RouteDTO route}) {
    if (route != null) {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => CityMapSearch(
                  route: route,
                )),
      );
    } else {
      Navigator.push(
        context,
        new MaterialPageRoute(
            builder: (context) => CityMapSearch(
                  landmark: landmark,
                )),
      );
    }
  }
}
