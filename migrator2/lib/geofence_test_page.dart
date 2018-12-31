import 'package:aftarobotlibrary/data/geofence_event.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;
import 'package:flutter/scheduler.dart';
import 'package:migrator2/bloc/route_builder_bloc.dart';

class GeofenceTestPage extends StatefulWidget {
  final RouteDTO route;

  const GeofenceTestPage({Key key, this.route}) : super(key: key);
  @override
  _GeofenceTestPageState createState() => _GeofenceTestPageState();
}

class _GeofenceTestPageState extends State<GeofenceTestPage> implements SnackBarListener{
  RouteDTO route;
  List<bg.Geofence> fences = List();
  List<LandmarkDTO> landmarks = List();
  GlobalKey<ScaffoldState> _key = GlobalKey();
  RouteBuilderBloc bloc = routeBuilderBloc;
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

//TODO - remove after dev
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
        '#################### -- should write arrival/departure record ::: _onGeofenceEvent: ${event.toString()}');
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
    
    if (event.identifier == 'mi casa') {
      landmark = landmarks.elementAt(0);
    }
    // ✅  mi casa
    assert(landmark != null);
    setState(() {
      events.add(event);
    });
    print('#############  ℹ️ geofence events so far: ${events.length}');
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
    var e = ARGeofenceEvent.fromJson(map);
    try {
      bloc.addGeofenceEvent(e);
    } catch (e) {
      AppSnackbar.showErrorSnackbar(
        scaffoldKey: _key,
        message: e.toString(),
        actionLabel: '',
        listener: this
      );
    }
      }

  void _createPecanwoodGeofences() {
    fences = List();
    route.spatialInfos.sort((a, b) => (a.fromLandmark.rankSequenceNumber
        .compareTo(b.fromLandmark.rankSequenceNumber)));
    route.spatialInfos.forEach((si) {
      var fence = bg.Geofence(
          identifier: si.fromLandmark.landmarkID,
          latitude: si.fromLandmark.latitude,
          longitude: si.fromLandmark.latitude,
          radius: 100,
          loiteringDelay: 10,
          notifyOnEntry: true,
          notifyOnDwell: true,
          notifyOnExit: true);
      landmarks.add(si.fromLandmark);
      try {
        bg.BackgroundGeolocation.addGeofence(fence);
        fences.add(fence);
        print('############# geofence added: ${si.fromLandmark.landmarkName}');
      } catch (e) {
        print(e);
      }
    });
    bg.BackgroundGeolocation.addGeofence(_getHomeGeoFence());
    bg.BackgroundGeolocation.startGeofences();
    fences.add(_getHomeGeoFence());
    landmarks.insert(0, _getHomeLandmark());
    setState(() {});
    // bg.BackgroundGeolocation.addGeofences(fences);
    print(
        '######### ++++++++++ ${fences.length} Geofences created for ${route.name}');
  }

  bg.Geofence _getHomeGeoFence() {
    var fence = bg.Geofence(
        identifier: 'mi casa',
        latitude: -25.7605351,
        longitude: 27.8526003,
        radius: 100,
        loiteringDelay: 10,
        notifyOnEntry: true,
        notifyOnDwell: true,
        notifyOnExit: true);
    return fence;
  }

  LandmarkDTO _getHomeLandmark() {
    var m = LandmarkDTO(
      landmarkName: 'Mi Casa Mio',
      latitude: -25.7605351,
      longitude: 27.8526003,
    );
    return m;
  }

  void _createGeofences() {
    widget.route.spatialInfos.sort((a, b) => (a.fromLandmark.rankSequenceNumber
        .compareTo(b.fromLandmark.rankSequenceNumber)));
    widget.route.spatialInfos.forEach((si) {
      var fence = bg.Geofence(
        identifier: si.fromLandmark.landmarkID,
        latitude: si.fromLandmark.latitude,
        longitude: si.fromLandmark.latitude,
        radius: 100,
      );
      landmarks.add(si.fromLandmark);
      try {
        bg.BackgroundGeolocation.addGeofence(fence);
        fences.add(fence);
        print('############# geofence added: ${si.fromLandmark.landmarkName}');
      } catch (e) {
        print(e);
      }
    });
    setState(() {});
    print(
        '######### ++++++++++ ${fences.length} Geofences created for ${route.name}');
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
          backgroundColor: Colors.indigo.shade300,
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(140),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: <Widget>[
                  Text(
                    route == null ? '' : route.name,
                    style: Styles.whiteBoldMedium,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      SizedBox(
                        width: 30,
                      ),
                      Counter(
                        label: 'Entered',
                        total: enters,
                        totalStyle: Styles.purpleBoldReallyLarge,
                      ),
                      SizedBox(
                        width: 30,
                      ),
                      Counter(
                        label: 'Dwelled',
                        total: dwells,
                        totalStyle: Styles.blackBoldReallyLarge,
                      ),
                      SizedBox(
                        width: 30,
                      ),
                      Counter(
                        label: 'Exits',
                        total: exits,
                      ),
                      SizedBox(
                        width: 30,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
        backgroundColor: Colors.brown.shade100,
        body: ListView.builder(
          controller: scrollController,
          itemCount: landmarks.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20, top: 4),
              child: Card(
                elevation: 2.0,
                color: getRandomPastelColor(),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Icon(
                      Icons.my_location,
                      color: getRandomColor(),
                    ),
                    title: Text(landmarks.elementAt(index).landmarkName,
                        style: Styles.blackBoldMedium),
                    subtitle: Text(
                        '${landmarks.elementAt(index).latitude}  ${landmarks.elementAt(index).longitude}'),
                  ),
                ),
              ),
            );
          },
        ));
  }

  @override
  onActionPressed(int action) {
    // TODO: implement onActionPressed
    return null;
  }
}

class Counter extends StatelessWidget {
  final int total;
  final String label;
  final TextStyle totalStyle, labelStyle;

  const Counter(
      {Key key, this.total, this.label, this.totalStyle, this.labelStyle})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '$total',
          style: totalStyle == null ? Styles.whiteBoldReallyLarge : totalStyle,
        ),
        Text(label, style: labelStyle == null ? Styles.whiteSmall : labelStyle),
      ],
    );
  }
}
