
/*
####### Generated by JavaToDart Wed Dec 19 22:12:26 SAST 2018
####### rigged up by AM Esq.
*/

class VehicleLocationRequestDTO {
	String vehicleLocationRequestID;
	String vehicleID;
	String vehicleReg;
	String userID;
	String driverID;
	String stringDate;
	String userName;
	String fcmToken;
	int date;
	String path;

VehicleLocationRequestDTO({
	this.vehicleLocationRequestID,
	this.vehicleID,
	this.vehicleReg,
	this.userID,
	this.driverID,
	this.stringDate,
	this.userName,
	this.fcmToken,
	this.date,
});

VehicleLocationRequestDTO.fromJson(Map data) {
	this.vehicleLocationRequestID = data['vehicleLocationRequestID'];
	this.vehicleID = data['vehicleID'];
	this.vehicleReg = data['vehicleReg'];
	this.userID = data['userID'];
	this.driverID = data['driverID'];
	this.stringDate = data['stringDate'];
	this.userName = data['userName'];
	this.fcmToken = data['fcmToken'];
	this.date = data['date'];
	this.path = data['path'];
}

Map<String, dynamic> toJson() => <String, dynamic>{
	'vehicleLocationRequestID': vehicleLocationRequestID,
	'vehicleID': vehicleID,
	'vehicleReg': vehicleReg,
	'userID': userID,
	'driverID': driverID,
	'stringDate': stringDate,
	'userName': userName,
	'fcmToken': fcmToken,
	'date': date,
	'path': path,
	
};

}