import 'package:aftarobotlibrary3/data/vehicledto.dart';

class VehicleLocation {
  VehicleDTO vehicle;
  double latitude;
  double longitude;
  int timestamp;
  String date;

  VehicleLocation({
    this.vehicle,
    this.latitude,
    this.longitude,
    this.timestamp,
    this.date,
  });

  VehicleLocation.fromJson(Map data) {
    if (data['vehicle'] != null) {
      vehicle = VehicleDTO.fromJson(data['vehicle']);
    }

    this.timestamp = data['timestamp'];
    this.date = data['date'];

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
  }

  Map<String, dynamic> toJson() {
    var vh;
    if (vehicle != null) {
      vh = vehicle.toJson();
    }
    Map<String, dynamic> map = {
      'vehicle': vh,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'date': date,
    };
    return map;
  }
}
