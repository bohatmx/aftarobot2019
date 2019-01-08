import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unicorndial/unicorndial.dart';
import 'package:vehicle/ui/landmark_map.dart';
import 'package:vehicle/vehicle_bloc/vehicle_bloc.dart';

class LandingPage extends StatefulWidget {
  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  VehicleAppBloc bloc = VehicleAppBloc();
  List<LandmarkDTO> landmarks = List();
  var childButtons = List<UnicornButton>();

  @override
  void initState() {
    super.initState();
    // _buildFabMenuList();
    //_buildDialerList();
  }

  _buildDialerList() {
    childButtons.clear();
    childButtons.add(UnicornButton(
        hasLabel: true,
        labelText: "Announcements",
        currentButton: FloatingActionButton(
          heroTag: "announcements",
          backgroundColor: Colors.deepOrange,
          mini: true,
          child: Icon(Icons.people),
          onPressed: () {},
        )));

    childButtons.add(UnicornButton(
        hasLabel: true,
        labelText: "Refresh Information",
        currentButton: FloatingActionButton(
          heroTag: "refresh",
          backgroundColor: Colors.black,
          mini: true,
          child: Icon(Icons.refresh),
          onPressed: () {},
        )));
    childButtons.add(UnicornButton(
        hasLabel: true,
        labelText: "Commuters",
        currentButton: FloatingActionButton(
          heroTag: "commuters",
          backgroundColor: Colors.teal,
          mini: true,
          child: Icon(Icons.people),
          onPressed: () {
            _findCommuterRequests();
          },
        )));

//    childButtons.add(UnicornButton(
//        hasLabel: true,
//        labelText: "Route Map",
//        currentButton: FloatingActionButton(
//          heroTag: "routeMap",
//          backgroundColor: Colors.purple,
//          mini: true,
//          child: Icon(Icons.map),
//          onPressed: _startLandmarkMap,
//        )));

    childButtons.add(UnicornButton(
        hasLabel: true,
        labelText: "Taxis Around Us",
        currentButton: FloatingActionButton(
            heroTag: "vehicles",
            backgroundColor: Colors.blue.shade800,
            mini: true,
            child: Icon(Icons.directions_car))));
  }

  void _findCommuterRequests() async {
    printLog('### 🔵 _findCommuterRequests - NOT IMPLEMENTED yet');
  }

  void _startLandmarkMap() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => LandmarkMap()),
    );
  }

  @override
  Widget build(BuildContext context) {
    _buildDialerList();
    return StreamBuilder(
        stream: bloc.landmarksStream,
        initialData: bloc.landmarks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            landmarks = snapshot.data;
          }
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft,
          ]);
          return Stack(
            children: <Widget>[
              Scaffold(
                backgroundColor: Colors.brown.shade100,
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: LandmarkList(
                    landmarks: landmarks,
                  ),
                ),
                floatingActionButton: UnicornDialer(
                  backgroundColor: Colors.transparent,
                  parentButtonBackground: Colors.pink,
                  orientation: UnicornOrientation.VERTICAL,
                  parentButton: Icon(Icons.list),
                  childButtons: childButtons,
                ),
              ),
              bloc.geofenceEvents.isEmpty
                  ? Container()
                  : Positioned(
                      right: 2,
                      top: 10,
                      child: StreamBuilder(
                          initialData: bloc.geofenceEvents,
                          stream: bloc.geofenceEventStream,
                          builder: (context, snapshot) {
                            return Card(
                              elevation: 16,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  children: <Widget>[
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          'Geofence Events: ',
                                          style: Styles.blackBoldSmall,
                                        ),
                                        SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          '${bloc.geofenceEvents.length}',
                                          style: Styles.blackBoldLarge,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: <Widget>[
                                        Text(
                                          'Current Event: ',
                                          style: Styles.blackBoldSmall,
                                        ),
                                        SizedBox(
                                          width: 4,
                                        ),
                                        Text(
                                          bloc.geofenceEvents.isEmpty
                                              ? 'Nada'
                                              : '${bloc.geofenceEvents.last.action}',
                                          style: Styles.pinkBoldMedium,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                    )
            ],
          );
        });
  }
}

class LandmarkList extends StatelessWidget {
  final List<LandmarkDTO> landmarks;

  const LandmarkList({Key key, this.landmarks}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: landmarks == null ? 0 : landmarks.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 40.0),
            child: Card(
              elevation: 4,
              color: getRandomPastelColor(),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4.0, top: 4),
                child: ListTile(
                  leading: Icon(
                    Icons.my_location,
                    color: getRandomColor(),
                  ),
                  title: Row(
                    children: <Widget>[
                      TrickleCounter(
                        total: 1765,
                        caption: 'Passengers',
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      Text(
                        landmarks == null
                            ? ""
                            : landmarks.elementAt(index).landmarkName,
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 100,
                      ),
                      Text(
                        landmarks.elementAt(index).routeName,
                        style: Styles.blackSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }
}

class TrickleCounter extends StatelessWidget {
  final int total;
  final String caption;
  final TextStyle totalStyle, captionStyle;

  const TrickleCounter(
      {Key key, this.total, this.caption, this.totalStyle, this.captionStyle})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          total == null ? '1048' : '$total',
          style: Styles.blueBoldLarge,
        ),
        Text(
          caption == null ? 'People' : caption,
          style: Styles.blackSmall,
        ),
      ],
    );
  }
}
