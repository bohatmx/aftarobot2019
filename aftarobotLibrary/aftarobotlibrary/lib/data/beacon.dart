import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';

class BeaconDTO {
  String beaconID;
  String routeID;
  VehicleDTO vehicle;
  LandmarkDTO landmark;
  AssociationDTO association;
  String advertiseID;
  bool isActive;
  double latitude;
  double longitude;
  int date;
  String stringDate, description;
  String path;

  BeaconDTO({
    this.beaconID,
    this.routeID,
    this.vehicle,
    this.landmark,
    this.association,
    this.advertiseID,
    this.stringDate,
    this.latitude,
    this.longitude, this.description,
    this.path, this.isActive,
    this.date,
  });

  BeaconDTO.fromJson(Map data) {
    this.beaconID = data['beaconID'];
    this.routeID = data['routeID'];
    this.advertiseID = data['advertiseID'];
    this.stringDate = data['stringDate'];
    this.path = data['path'];
    this.description = data['description'];

    if (data['latitude'] is int) {
      this.latitude = data['latitude'] * 1.0;
    } else {
      this.latitude = data['latitude'];
    }
    if (data['longitude'] is int) {
      this.longitude = data['longitude'] * 1.0;
    } else {
      this.longitude = data['longitude'];
    }

    this.date = data['date'];
    this.path = data['path'];
    if (data['vehicle'] != null) {
      vehicle = VehicleDTO.fromJson(data['vehicle']);
    }
    if (data['landmark'] != null) {
      landmark = LandmarkDTO.fromJson(data['landmark']);
    }
    if (data['association'] != null) {
      association = AssociationDTO.fromJson(data['association']);
    }
  }

  Map<String, dynamic> toJson() {
    var car, ass, mark;
    if (vehicle != null) {
      car = vehicle.toJson();
    }
    if (association != null) {
      ass = association.toJson();
    }
    if (landmark != null) {
      mark = landmark.toJson();
    }
    Map<String, dynamic> map = {
        'beaconID': beaconID,
        'date': date,
        'path': path,
        'description': description,
        'isActive': isActive,
        'stringDate': stringDate,
        'routeID': routeID,
        'latitude': latitude,
        'longitude': longitude,
        'vehicle': car,
        'association': ass,
        'landmark': mark,
      };
      return map;
}
