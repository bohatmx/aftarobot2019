import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class SnapToRoads {
  static const SNAP_TO_ROADS_URL =
      "https://roads.googleapis.com/v1/snapToRoads?path=";
  static const API_KEY = 'AIzaSyBj5ONubUcdtweuIdQPFszc2Z_kZdhd5g8';

  static Future<List<SnappedPoint>> getSnappedPoints(
      List<ARLocation> points) async {
    print('\n\nSnapToRoads ####################### starting');
    List<SnappedPoint> snappedPoints = List();
    var start = DateTime.now();
    int index = 0;
    //path=60.170880,24.942795|60.170879,24.942796|60.170877,24.942796.
    //"path" contains an invalid value: -26.139582,27.860941,-26.133071,27.8568082,-26.133071,27.8568082,-26.1294046,2
    String parameters = '';
    for (var p in points) {
      var s = '${p.latitude},${p.longitude}';
      if (index == points.length - 1) {
        //do not append |
      } else {
        s = '$s|';
      }
      parameters += s;
      index++;
    }
    var sendUrl = '$SNAP_TO_ROADS_URL$parameters&key=$API_KEY&interpolate=true';
    print('####### send to Roads API \n$sendUrl');
    try {
      var client = new http.Client();
      var resp = await client.get(sendUrl).whenComplete(() {
        client.close();
      });
      print(
          '\n\ngetSnappedPoints._c: statusCode: ${resp.statusCode} for $SNAP_TO_ROADS_URL');
      Map<String, dynamic> map = json.decode(resp.body);
      List list = map['snappedPoints'];
      print(list);
      list.forEach((sp) {
        var p = SnappedPoint.fromJson(sp);
        snappedPoints.add(p);
      });
      var end = DateTime.now();
      print('\n\nSnapToRoads ####################### ' +
          'COMPLETE: elapsed time: ${end.difference(start).inSeconds} seconds. Roads API returned: ${snappedPoints.length} snapped points');
    } catch (e) {
      print('@@@@@@@@@@@ Problem with Roads API parsing ........');
      print(e);
    }
    return snappedPoints;
  }

  static Future addLocationsToRoute(
      {List<SnappedPoint> points, String pathToRoute}) async {
    print('##### ++++ add snapped points to route in Firestore');
    Firestore fs = Firestore.instance;
    var ref = await fs.document(pathToRoute).collection('snappedPoints');
    //send these in batches to a function ....
  }
}

abstract class SnapToRoadsListener {
  onResponse(List<SnappedPoint> snappedPoints);
}

class SnappedPoint {
  ARLocation location;
  int originalIndex;
  String placeId;
  SnappedPoint({this.location, this.originalIndex, this.placeId});

//I/flutter (18749): type '_InternalLinkedHashMap<String, dynamic>' is not a subtype of type 'List<dynamic>'
//I/flutter (18749): type '_InternalLinkedHashMap<String, dynamic>' is not a subtype of type 'List<dynamic>'

  SnappedPoint.fromJson(Map data) {
    this.originalIndex = data['originalIndex'];
    this.placeId = data['placeId'];
    if (data['location'] != null) {
      this.location = ARLocation.fromJson(data['location']);
      this.location.placeId = this.placeId;
    }
  }
  Map<String, dynamic> toJson() {
    var loc;
    if (this.location != null) {
      loc = this.location.toJson();
    }
    Map<String, dynamic> map = {
      'originalIndex': originalIndex,
      'placeId': placeId,
      'location': loc,
    };
    return map;
  }
}

class ARLocation {
  double latitude, longitude;
  double altitude, accuracy, speed, speedAccuracy, odometer, heading;
  String routeID, placeId;
  String date, uid;
  bool isMoving;
  Activity activity;
  Battery battery;
  ARLocation(
      {this.latitude,
      this.longitude,
      this.accuracy,
      this.altitude,
      this.speed,
      this.uid,
      this.placeId,
      this.routeID,
      this.isMoving,
      this.odometer,
      this.date,
      this.heading,
      this.speedAccuracy,
      this.activity,
      this.battery});

  ARLocation.fromJson(Map data) {
    Map coords = data['coords'];
    if (coords == null) {
      //**** data from Firestore */
      this.latitude = data['latitude'];
      this.longitude = data['longitude'];
      this.accuracy = data['accuracy'];
      this.altitude = data['altitude'];
      this.speed = data['speed'];
      this.heading = data['heading'];
    } else {
      //**** data from BackgroundLocation response */
      this.latitude = coords['latitude'];
      this.longitude = coords['longitude'];
      this.accuracy = coords['accuracy'];
      this.altitude = coords['altitude'];
      this.speed = coords['speed'];
      this.heading = coords['heading'];
    }
    Map act = data['activity'];
    Map batt = data['battery'];
    if (act != null) {
      this.activity = Activity.fromJson(act);
    } else {
      print(
          '##### activity is null🔵  🔵  🔵  🔵  🔵  🔵  🔵  🔵  🔵  🔵  🔵  🔵  🔵  ');
    }
    if (batt != null) {
      this.battery = Battery.fromJson(batt);
    }

    this.isMoving = data['is_moving'];
    this.routeID = data['routeID'];
    this.date = data['timestamp'];
    this.placeId = data['placeId'];
    this.uid = data['uuid'];
    this.odometer = data['odometer'];
  }

  Map<String, dynamic> toJson() {
    Map mBattery, mAct;
    if (battery != null) {
      mBattery = battery.toJson();
    }
    if (activity != null) {
      mAct = activity.toJson();
    }
    Map<String, dynamic> map = {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'isMoving': isMoving,
      'heading': heading,
      'speedAccuracy': speedAccuracy,
      'routeID': routeID,
      'date': date,
      'placeId': placeId,
      'uid': uid,
      'odometer': odometer,
      'battery': mBattery,
      'activity': mAct
    };
    return map;
  }
}

class Battery {
  double level;
  bool isCharging;
  Battery({this.level, this.isCharging});
  Battery.fromJson(Map map) {
    level = map['level'];
    isCharging = map['isCharging'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'level': level,
      'isCharging': isCharging,
    };
    return map;
  }
}

class Activity {
  int confidence;
  String type;
  Activity({this.confidence, this.type});

  Activity.fromJson(Map map) {
    confidence = map['confidence'];
    type = map['type'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'confidence': confidence,
      'type': type,
    };
    return map;
  }
}
