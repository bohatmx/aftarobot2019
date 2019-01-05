import 'dart:async';
import 'dart:convert';

import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:latlong/latlong.dart';

final VehicleAppBloc vehicleBloc = VehicleAppBloc();

//✅  🎾 🔵  📍   ℹ️
class VehicleAppBloc {
  VehicleAppBloc() {
    print('+++ ℹ️ +++  ++++++++++++++++++ initializing Vehicle App Bloc');
  }
  FirebaseAuth auth = FirebaseAuth.instance;
  Firestore fs = Firestore.instance;

  static const geoQueryChannel = const MethodChannel('aftarobot/geoQuery');
  static const messageStream = const EventChannel('aftarobot/messages');
  StreamSubscription _messagesSubscription;

  StreamController<List<LandmarkDTO>> _landmarksController =
      StreamController.broadcast();
  StreamController<String> _nearbyMessagesController =
      StreamController.broadcast();

  List<LandmarkDTO> _landmarks = List();
  List<LandmarkDTO> get landmarks => _landmarks;

  get landmarksStream => _landmarksController.stream;
  get nearbyMessageStream => _nearbyMessagesController.stream;

  final Distance distance = new Distance();

  void closeStreams() {
    _landmarksController.close();
    _nearbyMessagesController.close();
  }

  void _calculateDistancesBetweenLandmarks() {
    /*
    // km = 423
    final int km = distance.as(LengthUnit.Kilometer,
     new LatLng(52.518611,13.408056),new LatLng(51.519475,7.46694444));

    // meter = 422591.551
    final int meter = distance(
        new LatLng(52.518611,13.408056),
        new LatLng(51.519475,7.46694444)
        );

     */
  }
  void searchForLandmarks(
      double latitude, double longitude, double radius) async {
    print(
        ' 🔵  🔵  VehicleBloc: start geo query .... ........................');
    List<String> landmarkIDs = List();

    try {
      var args = {
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius,
      };
      var result = await geoQueryChannel.invokeMethod(
          'findLandmarks', json.encode(args));
      print('\n\nVehicleBloc: Result back from geoQuery ....  ✅ ');

      List<dynamic> list = json.decode(result);
      print('. ✅ ... number of searched geoPoints returned: ${list.length}');

      list.forEach((t) {
        if (t is Map) {
          t.forEach((key, value) {
            print("VehicleBloc 🔵 ++++++ landmarkID :::: $key ");
            landmarkIDs.add(key);
          });
        }
      });
      _getLocatedLandmarks(landmarkIDs);
    } on PlatformException catch (e) {
      print(
          'nVehicleBloc: Why is the result coming back twice??????????? - will check for already located landmarks: ${landmarkIDs.length}');
      print(e);
      if (landmarkIDs.isNotEmpty) {
        _getLocatedLandmarks(landmarkIDs);
      }
    }
  }

  void _getLocatedLandmarks(List<String> ids) async {
    int count = 0;
    _landmarks.clear();
    for (var id in ids) {
      DocumentSnapshot ds = await fs.collection('landmarks').document(id).get();
      if (ds.exists) {
        var lm = LandmarkDTO.fromJson(ds.data);
        _landmarks.add(lm);
        count++;
        prettyPrint(lm.toJson(),
            ' 🔵  🔵  ############# LANDMARK::: #$count  🔵  🔵  ✅ ');
      }
    }
    print('📍 Place ${_landmarks.length} landmarks found on the stream');
    _landmarksController.sink.add(_landmarks);
    print(' ✅  We have ${landmarks.length} landmarks found in area search');
  }

  void listenForCommuterMessages() {
    print('+++  🔵 starting message channel .......');
    try {
      _messagesSubscription =
          messageStream.receiveBroadcastStream().listen((message) {
        print('### - 🔵 - message received :: ${message.toString()}');
        print('### - 📍 - place arriving message on the stream');
        //todo check if this is from a commuter
        _nearbyMessagesController.sink.add(message.toString());
      });
    } on PlatformException {
      _messagesSubscription.cancel();
      print(
          'Things went south in a hurry, Jack!  ⚠️ ⚠️ Message listening not so hot ..');
    }
  }

  void signInAnonymously() async {
    print('📍 checking current user ..... 📍 ');
    var user = await auth.currentUser();

    if (user == null) {
      print('ℹ️ signing in ..... .......');
      user = await auth.signInAnonymously();
    } else {
      print('User already signed in: 🔵 🔵 🔵 ');
    }
  }

  void publishMessage() {
    print('+++ publishMessage ');
  }
}
