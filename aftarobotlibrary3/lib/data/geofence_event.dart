class ARGeofenceEvent {
  String landmarkID, activityType, action, userID, vehicleID, stringTimestamp;
  String timestamp;
  int confidence;
  double odometer;
  bool isMoving;

  ARGeofenceEvent(
      {this.landmarkID,
      this.action,
      this.activityType,
      this.confidence,
      this.odometer,
      this.stringTimestamp,
      this.timestamp,
      this.userID,
      this.isMoving,
      this.vehicleID});

  ARGeofenceEvent.fromJson(Map map) {
    landmarkID = map['landmarkID'];
    activityType = map['activityType'];
    action = map['action'];
    userID = map['userID'];
    vehicleID = map['vehicleID'];
    stringTimestamp = map['stringTimestamp'];
    timestamp = map['timestamp'];
    confidence = map['confidence'];
    odometer = map['odometer'];
    isMoving = map['isMoving'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> map = {
      'landmarkID': landmarkID,
      'activityType': activityType,
      'action': action,
      'userID': userID,
      'vehicleID': vehicleID,
      'stringTimestamp': stringTimestamp,
      'timestamp': timestamp,
      'confidence': confidence,
      'odometer': odometer,
      'isMoving': isMoving,
    };
    return map;
  }
}

/*
var map = {
      'landmarkID': event.identifier,
      'isMoving': event.location.isMoving,
      'action': event.action,
      'activityType': event.location.activity.type,
      'confidence': event.location.activity.confidence,
      'odometer': event.location.odometer,
      'timestamp': event.location.timestamp,
    };
*/
