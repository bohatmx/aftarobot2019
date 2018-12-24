/*
####### Generated by JavaToDart Wed Dec 19 22:12:26 SAST 2018
####### rigged up by AM Esq.
*/

class PanicOverDTO {
  String userID;
  String stringDate;
  String panicID;
  String userName;
  int date;
  double latitude;
  double longitude;
  String panicType;
  String path;
  List<String> fcmTokens;

  PanicOverDTO({
    this.userID,
    this.stringDate,
    this.panicID,
    this.userName,
    this.date,
    this.latitude,
    this.longitude,
    this.panicType,
    this.fcmTokens,
  });

  PanicOverDTO.fromJson(Map data) {
    this.userID = data['userID'];
    this.stringDate = data['stringDate'];
    this.panicID = data['panicID'];
    this.userName = data['userName'];
    this.date = data['date'];
    this.latitude = data['latitude'];
    this.longitude = data['longitude'];
    this.panicType = data['panicType'];
    this.fcmTokens = data['fcmTokens'];
    this.path = data['path'];
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userID': userID,
        'stringDate': stringDate,
        'panicID': panicID,
        'userName': userName,
        'date': date,
        'latitude': latitude,
        'longitude': longitude,
        'panicType': panicType,
        'fcmTokens': fcmTokens,
        'path': path,
      };
}