import 'dart:convert';

import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Prefs {
  static void saveAssociation(AssociationDTO association) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    Map jsonx = association.toJson();
    var jx = json.encode(jsonx);
    print(jx);
    prefs.setString('account', jx);
    //prefs.commit();
    print("SharedPrefs.saveAccount =========  data SAVED.........");
  }

  static Future<AssociationDTO> getAssociation() async {
    print("SharedPrefs.getassociation =========  getting cached data.........");
    var prefs = await SharedPreferences.getInstance();
    var string = prefs.getString('association');
    if (string == null) {
      return null;
    }
    var jx = json.decode(string);
    prettyPrint(jx, 'Account from cache: ');
    var association = new AssociationDTO.fromJson(jx);
    return association;
  }

  static Future saveFCMToken(String token) async {
    print("SharedPrefs saving token ..........");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("fcm", token);
    //prefs.commit();

    print("FCM token saved in cache prefs: $token");
  }

  static Future<String> getFCMToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var token = prefs.getString("fcm");
    print("SharedPrefs - FCM token from prefs: $token");
    return token;
  }

  static Future saveMinutes(int minutes) async {
    print("SharedPrefs saving minutes ..........");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("minutes", minutes);

    print("FCM minutes saved in cache prefs: $minutes");
  }

  static Future<int> getMinutes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var minutes = prefs.getInt("minutes");
    print("SharedPrefs - FCM minutes from prefs: $minutes");
    return minutes;
  }

  static void saveThemeIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("themeIndex", index);
    //prefs.commit();
  }

  static Future<int> getThemeIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int index = prefs.getInt("themeIndex");
    print("=================== SharedPrefs theme index: $index");
    return index;
  }

  static void savePictureUrl(String url) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("url", url);
    //prefs.commit();
    print('picture url saved to shared prefs');
  }

  static Future<String> getPictureUrl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String path = prefs.getString("url");
    print("=================== SharedPrefs url index: $path");
    return path;
  }

  static void savePicturePath(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("path", path);
    //prefs.commit();
    print('picture path saved to shared prefs');
  }

  static Future<String> getPicturePath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String path = prefs.getString("path");
    print("=================== SharedPrefs path index: $path");
    return path;
  }

  static Future savePageLimit(int pageLimit) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("pageLimit", pageLimit);
    print('SharedPrefs.savePageLimit ######### saved pageLimit: $pageLimit');
    return null;
  }

  static Future<int> getPageLimit() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int pageLimit = prefs.getInt("pageLimit");
    if (pageLimit == null) {
      pageLimit = 10;
    }
    print("=================== SharedPrefs pageLimit: $pageLimit");
    return pageLimit;
  }

  static Future saveRefreshDate(DateTime date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("refresh", date.millisecondsSinceEpoch);
    print('SharedPrefs.saveRefreshDate ${date.toIso8601String()}');
    return null;
  }

  static Future<DateTime> getRefreshDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int ms = prefs.getInt("refresh");
    if (ms == null) {
      ms = DateTime.now().subtract(Duration(days: 365)).millisecondsSinceEpoch;
    }
    var date = DateTime.fromMillisecondsSinceEpoch(ms);
    print('SharedPrefs.getRefreshDate ${date.toIso8601String()}');
    return date;
  }
}
