
/*
####### Generated by JavaToDart Wed Dec 19 22:12:26 SAST 2018
####### rigged up by AM Esq.
*/

class RouteUpdateTriggerDTO {
	String routeUpdateTriggerID;
	String associationID;
	String associationName;
	String stringDate;
	String routeID;
	String routeName;
	int date;
	String path;

RouteUpdateTriggerDTO({
	this.routeUpdateTriggerID,
	this.associationID,
	this.associationName,
	this.stringDate,
	this.routeID,
	this.routeName,
	this.date,
});

RouteUpdateTriggerDTO.fromJson(Map data) {
	this.routeUpdateTriggerID = data['routeUpdateTriggerID'];
	this.associationID = data['associationID'];
	this.associationName = data['associationName'];
	this.stringDate = data['stringDate'];
	this.routeID = data['routeID'];
	this.routeName = data['routeName'];
	this.date = data['date'];
	this.path = data['path'];
}

Map<String, dynamic> toJson() => <String, dynamic>{
	'routeUpdateTriggerID': routeUpdateTriggerID,
	'associationID': associationID,
	'associationName': associationName,
	'stringDate': stringDate,
	'routeID': routeID,
	'routeName': routeName,
	'date': date,
	'path': path,
	
};

}