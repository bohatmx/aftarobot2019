class CityDTO {
  String cityID;
  String provinceID;
  String countryID, countryPath;
  String name;
  String status;
  String provinceName;
  double latitude;
  double longitude;
  String countryName;
  int date;

  String path;

  CityDTO({
    this.cityID,
    this.provinceID,
    this.countryID,
    this.name,
    this.countryPath,
    this.status,
    this.provinceName,
    this.latitude,
    this.longitude,
    this.countryName,
    this.date,
  });

  CityDTO.fromJson(Map data) {
    this.cityID = data['cityID'];
    this.provinceID = data['provinceID'];
    this.countryID = data['countryID'];
    this.name = data['name'];
    this.status = data['status'];
    this.provinceName = data['provinceName'];

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

    this.countryName = data['countryName'];
    this.date = data['date'];
    this.path = data['path'];
    this.countryPath = data['countryPath'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'cityID': cityID,
        'provinceID': provinceID,
        'countryID': countryID,
        'name': name,
        'status': status,
        'provinceName': provinceName,
        'latitude': latitude,
        'longitude': longitude,
        'countryName': countryName,
        'date': date,
        'path': path,
        'countryPath': countryPath,
      };
}
