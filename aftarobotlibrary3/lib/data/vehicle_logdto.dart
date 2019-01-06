import 'package:aftarobotlibrary3/data/vehicledto.dart';

class VehicleLogDTO {
  String vehicleLogID;
  String userID;
  String vehicleID;
  String stringDate;
  String nearestAddress;
  VehicleDTO vehicle;
  double latitude;
  double longitude;
  int date;
  double accuracy;
  double bearing;
  double speed;
  bool locationRequested;
  String path;

  VehicleLogDTO({
    this.vehicleLogID,
    this.vehicleID,
    this.stringDate,
    this.nearestAddress,
    this.vehicle,
    this.latitude,
    this.longitude,
    this.date,
    this.accuracy,
    this.bearing,
    this.speed,
    this.locationRequested,
  });

  VehicleLogDTO.fromJson(Map data) {
    this.vehicleLogID = data['vehicleLogID'];
    this.vehicleID = data['vehicleID'];
    this.stringDate = data['stringDate'];
    this.nearestAddress = data['nearestAddress'];
    if (data['vehicle'] != null) {
      this.vehicle = VehicleDTO.fromJson(data['vehicle']);
    }

    this.latitude = data['latitude'];
    this.longitude = data['longitude'];
    this.date = data['date'];
    this.accuracy = data['accuracy'];
    this.bearing = data['bearing'];
    this.speed = data['speed'];
    this.locationRequested = data['locationRequested'];
    this.path = data['path'];
  }

  Map<String, dynamic> toJson() {
    var mVehicle;
    if (this.vehicle != null) {
      mVehicle = this.vehicle.toJson();
    }
    Map<String, dynamic> map = {
      'driverLogID': vehicleLogID,
      'vehicleID': vehicleID,
      'stringDate': stringDate,
      'nearestAddress': nearestAddress,
      'vehicle': mVehicle,
      'latitude': latitude,
      'longitude': longitude,
      'date': date,
      'accuracy': accuracy,
      'bearing': bearing,
      'speed': speed,
      'locationRequested': locationRequested,
      'path': path,
    };
    return map;
  }
}
