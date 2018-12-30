import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter/scheduler.dart';

class GeofenceTestPage extends StatefulWidget {
  final RouteDTO route;

  const GeofenceTestPage({Key key, this.route}) : super(key: key);
  @override
  _GeofenceTestPageState createState() => _GeofenceTestPageState();
}

class _GeofenceTestPageState extends State<GeofenceTestPage> {
  RouteDTO route;
  List<bg.Geofence> fences = List();
  List<LandmarkDTO> landmarks = List();
  GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    bg.BackgroundGeolocation.onGeofence(_onGeofenceEvent);
    bg.BackgroundGeolocation.ready(bg.Config(
            desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
            distanceFilter: 10.0,
            stopOnTerminate: false,
            startOnBoot: true,
            debug: true,
            logLevel: bg.Config.LOG_LEVEL_VERBOSE,
            reset: true))
        .then((bg.State state) {
      print(state);
    });

    print('++++++++++++ BackgroundGeolocation configured ....');
    if (widget.route != null) {
      route = widget.route;
      _createGeofences();
    } else {
      _getPecanwoodRoute();
    }
  }

  void _getPecanwoodRoute() async {
    Firestore fs = Firestore.instance;
    var qs = await fs
        .collection('routes')
        .where('routeID', isEqualTo: '-KVnZVSIg8UMl_gFtswm')
        .getDocuments();
    if (qs.documents.isNotEmpty) {
      route = RouteDTO.fromJson(qs.documents.first.data);
      _createPecanwoodGeofences();
    } else {
      print('------ ERROR: Inside Pecanwood not found');
    }
  }

  List<bg.GeofenceEvent> events = List();
  Firestore fs = Firestore.instance;
  int enters = 0, dwells = 0, exits = 0;
  void _onGeofenceEvent(bg.GeofenceEvent event) {
    print(
        '#################### -- should write arrival/departure record ::: _onGeofenceEvent: $event');
    events.add(event);
    switch (event.action) {
      case 'ENTER':
        enters++;
        break;
      case 'DWELL':
        dwells++;
        break;
      case 'EXIT':
        exits++;
        break;
    }
    LandmarkDTO landmark;
    landmarks.forEach((m) {
      if (m.landmarkID == event.identifier) {
        landmark = m;
      }
    });
    assert(landmark != null);
    setState(() {
      events.add(event);
    });
    print('############# geofence events so far: ${events.length}');
    _addEventToFirestore(event);
    AppSnackbar.showSnackbar(
      scaffoldKey: _key,
      backgroundColor: Colors.black,
      message: '${event.action}: ${landmark.landmarkName}',
      textColor: Colors.yellow,
    );
  }

  void _addEventToFirestore(bg.GeofenceEvent event) async {
    var map = {
      'landmarkID': event.identifier,
      'isMoving': event.location.isMoving,
      'action': event.action,
      'activityType': event.location.activity.type,
      'confidence': event.location.activity.confidence,
      'odometer': event.location.odometer,
      'timestamp': event.location.timestamp,
    };
    var ref = await fs.collection('geofenceEvents').add(map);
    print(
        '+++++++++++++ geofence event added to Firestore: ${ref.path} \n$map');
  }

  void _createPecanwoodGeofences() {
    fences = List();
    route.spatialInfos.sort((a, b) => (a.fromLandmark.rankSequenceNumber
        .compareTo(b.fromLandmark.rankSequenceNumber)));
    route.spatialInfos.forEach((si) {
      fences.add(bg.Geofence(
        identifier: si.fromLandmark.landmarkID,
        latitude: si.fromLandmark.latitude,
        longitude: si.fromLandmark.latitude,
        radius: 100,
      ));
      landmarks.add(si.fromLandmark);
    });
    setState(() {});
    bg.BackgroundGeolocation.addGeofences(fences);
    print(
        '######### ++++++++++ ${fences.length} Geofences created for ${route.name}');
  }

  void _createGeofences() {
    widget.route.spatialInfos.sort((a, b) => (a.fromLandmark.rankSequenceNumber
        .compareTo(b.fromLandmark.rankSequenceNumber)));
    widget.route.spatialInfos.forEach((si) {
      fences.add(bg.Geofence(
        identifier: si.fromLandmark.landmarkID,
        latitude: si.fromLandmark.latitude,
        longitude: si.fromLandmark.latitude,
        radius: 100,
      ));
      landmarks.add(si.fromLandmark);
    });
    setState(() {});
    bg.BackgroundGeolocation.addGeofences(fences);
    print('######### ++++++++++ Geofences created for ${route.name}');
  }

  ScrollController scrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    });
    return Scaffold(
        key: _key,
        appBar: AppBar(
          title: Text('Geofence Testing'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: Column(
              children: <Widget>[
                Text(
                  route == null ? '' : route.name,
                  style: Styles.whiteBoldSmall,
                ),
                Row(
                  children: <Widget>[
                    Text('Geofence Events', style: Styles.whiteBoldSmall),
                    Column(
                      children: <Widget>[
                        Text(
                          '$enters',
                          style: Styles.blackBoldLarge,
                        ),
                        Text('Entered', style: Styles.whiteSmall)
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          '$dwells',
                          style: Styles.blackBoldLarge,
                        ),
                        Text('Dwelled', style: Styles.whiteSmall)
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        Text(
                          '$exits',
                          style: Styles.blackBoldLarge,
                        ),
                        Text('Exited', style: Styles.whiteSmall)
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: ListView.builder(
          controller: scrollController,
          itemCount: landmarks.length,
          itemBuilder: (context, index) {
            return Card(
              elevation: 2.0,
              color: getRandomPastelColor(),
              child: ListTile(
                leading: Icon(
                  Icons.my_location,
                  color: getRandomColor(),
                ),
                title: Text(landmarks.elementAt(index).landmarkName),
                subtitle: Text(
                    '${landmarks.elementAt(index).latitude}  ${landmarks.elementAt(index).longitude}'),
              ),
            );
          },
        ));
  }
}
