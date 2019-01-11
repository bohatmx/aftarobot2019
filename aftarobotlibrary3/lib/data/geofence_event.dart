class VehicleGeofenceEvent {
  String landmarkID, activityType, action, userID, vehicleID, stringTimestamp;
  String timestamp, vehicleReg, make, landmarkName;
  int confidence;
  double odometer;
  bool isMoving;

  VehicleGeofenceEvent(
      {this.landmarkID,
      this.action,
      this.activityType,
      this.confidence,
      this.odometer,
      this.stringTimestamp,
      this.timestamp,
      this.userID,
      this.isMoving,
      this.vehicleID,
      this.vehicleReg,
      this.make,
      this.landmarkName});

  VehicleGeofenceEvent.fromJson(Map map) {
    landmarkID = map['landmarkID'];
    landmarkName = map['landmarkName'];
    activityType = map['activityType'];
    action = map['action'];
    userID = map['userID'];
    vehicleID = map['vehicleID'];
    stringTimestamp = map['stringTimestamp'];
    timestamp = map['timestamp'];
    confidence = map['confidence'];
    odometer = map['odometer'];
    isMoving = map['isMoving'];

    vehicleReg = map['vehicleReg'];
    make = map['make'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'landmarkID': landmarkID,
      'landmarkName': landmarkName,
      'activityType': activityType,
      'action': action,
      'userID': userID,
      'vehicleID': vehicleID,
      'stringTimestamp': stringTimestamp,
      'timestamp': timestamp,
      'confidence': confidence,
      'odometer': odometer,
      'isMoving': isMoving,
      'vehicleReg': vehicleReg,
      'make': make,
    };
    return map;
  }
}

class CommuterGeofenceEvent {
  String landmarkID, activityType, action, userID;
  String timestamp, landmarkName;
  int confidence;
  double odometer;
  bool isMoving;

  CommuterGeofenceEvent(
      {this.landmarkID,
      this.action,
      this.activityType,
      this.confidence,
      this.odometer,
      this.timestamp,
      this.userID,
      this.isMoving,
      this.landmarkName});

  CommuterGeofenceEvent.fromJson(Map map) {
    landmarkID = map['landmarkID'];
    landmarkName = map['landmarkName'];
    activityType = map['activityType'];
    action = map['action'];
    userID = map['userID'];
    timestamp = map['timestamp'];
    confidence = map['confidence'];
    odometer = map['odometer'];
    isMoving = map['isMoving'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'landmarkID': landmarkID,
      'landmarkName': landmarkName,
      'activityType': activityType,
      'action': action,
      'userID': userID,
      'timestamp': timestamp,
      'confidence': confidence,
      'odometer': odometer,
      'isMoving': isMoving,
    };
    return map;
  }
}
