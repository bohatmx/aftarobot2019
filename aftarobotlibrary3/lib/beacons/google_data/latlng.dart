
/*
####### Generated by JavaToDart Tue Jan 01 17:12:32 SAST 2019
####### rigged up by AM Esq.
*/

class LatLng {
	double latitude;
	double longitude;
	String path;

LatLng({
	this.latitude,
	this.longitude,
});

LatLng.fromJson(Map data) {
	this.latitude = data['latitude'];
	this.longitude = data['longitude'];
	this.path = data['path'];
}

Map<String, dynamic> toJson() => <String, dynamic>{
	'latitude': latitude,
	'longitude': longitude,
	'path': path,
	
};

}