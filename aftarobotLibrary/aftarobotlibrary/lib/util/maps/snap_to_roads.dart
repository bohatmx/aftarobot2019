import 'dart:convert';

import 'package:http/http.dart' as http;

class SnapToRoads {
  static const URL =
      'https://roads.googleapis.com/v1/snapToRoads?parameters&key=';
  static const SNAP_TO_ROADS_URL =
      "https://roads.googleapis.com/v1/snapToRoads?";
  static const API_KEY = 'AIzaSyBj5ONubUcdtweuIdQPFszc2Z_kZdhd5g8';

  static void getSnappedPoints(List<ARLocation> points) async {
    print('\n\nSnapToRoads ####################### starting');
    var start = DateTime.now();
    int index = 0;
    String parameters;
    for (var p in points) {
      var s = '${p.latitude},${p.longitude}';
      if (index == points.length - 1) {
        //do not append comma
      } else {
        s = '$s,';
      }
      parameters += s;
      index++;
    }
    var sendUrl = '$SNAP_TO_ROADS_URL$parameters&key=$API_KEY&interpolate=true';
    print('####### send to Roads API \n$sendUrl');
    var client = new http.Client();
    var resp = await client.get(sendUrl).whenComplete(() {
      client.close();
    });
    print(
        '\n\nDataAPI._callCloudFunction .... #### BFN via Cloud Functions: statusCode: ${resp.statusCode} for $mUrl');
//
    print('\n\n\n\n\n');
    print(resp.body);
    var list = json.decode(resp.body);
    print('\n\n\n\n\n');
    print(list);
    var end = DateTime.now();
    print(
        '\n\nSnapToRoads ####################### COMPLETE: elapsed time: ${end.difference(start).inSeconds}');
    return null;
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

  SnappedPoint.fromJson(Map data) {
    this.originalIndex = data['originalIndex'];
    this.placeId = data['placeId'];
    if (data['location'] != null) {
      this.location = ARLocation.fromJson(data['location']);
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
/*
print(currentLocation["latitude"]);
  print(currentLocation["longitude"]);
  print(currentLocation["accuracy"]);
  print(currentLocation["altitude"]);
  print(currentLocation["speed"]);
  print(currentLocation["speed_accuracy"]); // Will always be 0 on iOS
*/

class ARLocation {
  double latitude, longitude;
  int altitude, accuracy, speed, speedAccuracy;
  ARLocation(
      {this.latitude,
      this.longitude,
      this.accuracy,
      this.altitude,
      this.speed,
      this.speedAccuracy});

  ARLocation.fromJson(Map data) {
    this.latitude = data['latitude'];
    this.longitude = data['longitude'];
    this.accuracy = data['accuracy'];
    this.altitude = data['altitude'];
    this.speed = data['speed'];
    this.speedAccuracy = data['speedAccuracy'];
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'speedAccuracy': speedAccuracy,
    };
    return map;
  }
}
