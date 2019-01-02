import 'dart:convert';

import 'package:beaconmanager/beacons/google_data/beacon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:googleapis_auth/auth_io.dart";

final GoogleBeaconBloc googleBeaconBloc = GoogleBeaconBloc();

class GoogleBeaconBloc {
  static const URL = 'https://proximitybeacon.googleapis.com/v1beta1/';
  static const Scopes = [
    'https://www.googleapis.com/auth/userlocation.beacon.registry'
  ];

  AuthClient authClient;
  Firestore fs = Firestore.instance;

  Future<int> initializeAuthClient() async {
    print('#################### initializeAuthClient .....');
    if (authClient != null) {
      return 0;
    }
    var mJson = {
      "type": "service_account",
      "private_key_id": "bd98591d880e83cdb0a468f61152610762eb5eac",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQC6NiIkONKMcEUq\nPjyobA2Z/vAh/QGB9ZgVMKXMGuaKwo7CX4FZOZCcyjAeoS0DRbujLkAyfbCS+CFs\nJLrB1n/qNSFe9/xgZa1q2/jr23ZSLCngIWmPcHb9GXTvUdtFdPYHoVu9EfNOlGHo\nI9WJiSSPPfOCg3QXHp2lhx2yaLwpv2YvWeJvls9CsgOZn9uLbPc2dvgpC2ErgqzC\nmSzth/bGpPmf+A6DcCXQeAz6qALdqdf0EhLggEg8F/Lyx2JDy+R+RbaY6QzOpH2D\nQIMevcWLTjEGv98Fl3Tuleslemq33gZ7GSl+OqIi8qhV4bJz/w0To8BFnAN2ZLqh\nz2q1pI05AgMBAAECggEAVOTyKs5nG1TiC5DFScm9Z7xlUTGOWugTlnGP3R5UheWO\nfUpaZ8nJRtodFxHHOksz8QDYjsxj0JVkc2/JXy8CMU5YsPnhKzef2OyBr1HmPy9Y\nRhEllZoh/WD6QVNx4tgghLkJYIkLAoO+oT2ZEHOgYdfOKW3x4sp39+vCW8DJLESI\nZmoquutx3IfTu0GvAaYK2wJdcN6W3kB2S+wsrEXyEfu17BOOtl43Eo+dVYO/f+U3\ngEZy50NMJR/h0kNkqw50S0lMYoB/gqpfKuiha3YCDeWznYDxbIUYjsOy9hkIRfU2\ndLN3mBstOhRuH8XoX/+X6a91gWpwTEtJpqRdmHYy8wKBgQD206y8a/M8CHsA56/A\n5iYAr0JO4IpZeZb4k6uYz7Rc+2mLhtcYxFjo/afITbc96j84rLGdeZKSMUTjtKKj\nimMWpodhXePoa86a3GiRHLdApChJ2IuTZLKtrEYEwyS6Wt0A4cTKOKM7NLUgdVMq\nQAhwE5O2KyMikxU9/z6VD65ijwKBgQDBIcKaAwVD8pWiNsk3P0UiOYR3+OByKJFp\n2jHZDRM2EASo47lwQLnKdHtv4ydu6wFPH/s9FSLqQ97EqlNzMFu9NctD0VazfgTC\nGoj/JW3gDgTfiCEsFNCQ0aYZ2qJeoO1c/l5oNkLJHSLaOiKiLpvMEy3VSobHPM6h\n9lbuBGrXtwKBgC5AwljYvc7dI/eqcvPp7Osp7HoNd7+GmnTgb0KGgZz+++tKjFo2\nyRZ4Gg3eCl2O3OQI8Iu68W110Bv/iI6u6xyefjYPuxqdwSyh6vJueCSj3mzgKF+p\nehYzdzeDPgmx50I4DIF8lZINsXdwpPIA59Pgx0hW0xGykEN65kZWlu4fAoGAdF+l\nZSwgxhqsc3xTrsifHcpOugPrKp6rUH87vjAUvWTVifb+TFeUHBwoLPlRT5KnzUfW\nGa5cxZBz8Uk405X2EYMSoiDH/4wVzegzWJrzJCkOYqsiYe+A5WKOldGaOS77GCfm\nNyFLCOhXkeup5tPy6Ps9iOJJaFCJqipHo1BiGO0CgYBmRKhrob1uyF/eTZlq3mNe\nXNWY8Wtv/l1UtSNQYhHNEm+Q+NobEKDY9Nv22Tp+eVcjCXLn/KfOJF8of6IvJDrB\nJ3Ie+6afVafOqHH0fyt8113Bw+8jbg/r+V07pq+RWrE8ZeJVXs+thTFP1E22TTxE\nhloZ9R6zQph34CjwdPfnTA==\n-----END PRIVATE KEY-----\n",
      "client_email":
          "beaconsaccount@aftarobot2019-dev1.iam.gserviceaccount.com",
      "client_id": "108891195253414859996",
    };
    try {
      final accountCredentials = new ServiceAccountCredentials.fromJson(mJson);
      clientViaServiceAccount(accountCredentials, Scopes)
          .then((AuthClient client) {
        authClient = client;
        print(
            '************* we have a authorised client!  🔵  🔵  🔵  🔵  🔵  ');
        return 0;
      });
    } catch (e) {
      print('⚠️ ⚠️ ⚠️  $e');
      authClient.close();
    }
    return 9;
  }

  Future<Beacon> registerBeacon(Beacon beacon) async {
    print('###### registering beacon ${beacon.toJson()}');
    var url = URL + 'beacons:register';
    var res = await _callGoogle(url: url, data: beacon.toJson());
    var b = Beacon.fromJson(json.decode(res));
    return await addRegisteredBeacon(b);
  }

  Future addRegisteredBeacon(Beacon beacon) async {
    print('##### adding beacon to Firestore: ${beacon.toJson()}');
    DocumentReference ref = await fs.collection('beacons').add(beacon.toJson());
    beacon.path = ref.path;
    await ref.setData(beacon.toJson());
    print('### beacon added to Firestore, path: ${beacon.path}');
  }

  Future<List<Beacon>> getRegistryBeacons() async {
    var url = URL + "beacons" + "?pageSize=1000&q=";
    var res = await _callGoogle(url: url);
    List list = List<Beacon>();
    //todo - parse list
    return list;
  }

  Future testClient() async {
    await initializeAuthClient();
    if (authClient != null) {
      var resp = await authClient
          .get('https://www.youtube.com/watch?v=oiwDU6s8l3k')
          .catchError((e) {
        print(e);
      });
      print(resp);
    } else {}
  }

  Future _callGoogle({String url, Map data}) async {
    await initializeAuthClient();
    if (authClient == null) {
      throw Exception('️ ⚠️ ⚠️  We have no authorized client');
    }

    try {
      var resp;
      if (data != null) {
        resp = await authClient.post(url, body: data);
      } else {
        resp = await authClient.get(url);
      }
      print(resp.body);
      print(
          '\n\nGoogleBeaconApi._callGoogle  ✅  .... ::::: statusCode: ${resp.statusCode} for $url');
      if (resp.statusCode == 200) {
        print('\n✅ ✅ Call to Google Beacon API successful. yo!');
      } else {
        throw Exception(
            '⚠️ ⚠️ ⚠️  - We have a problem calling Google Beacon API, status: ${resp.statusCode}');
      }
      return resp.body;
    } catch (e) {
      print('️ ⚠️ ⚠️  - $e');
      throw e;
    }
  }
}

/*
{
  "advertisedId": {
    "type": "EDDYSTONE",
    "id": "Fr4Z98nSoW0hgAAAAAAAAg=="
  },
  "status": "ACTIVE",
  "placeId": "ChIJTxax6NoSkFQRWPvFXI1LypQ",
  "latLng": {
    "latitude": "47.6693771",
    "longitude": "-122.1966037"
  },
  "indoorLevel": {
    "name": "1"
  },
  "expectedStability": "STABLE",
  "description": "An example beacon.",
  "properties": {
    "position": "entryway"
  }
}
*/

/*
private static final String TAG = ProximityBeaconAPI.class.getSimpleName();
    private static final String ENDPOINT = "https://proximitybeacon.googleapis.com/v1beta1/";
    private static final String SCOPE = "oauth2:https://www.googleapis.com/auth/userlocation.beacon.registry";
    public static final MediaType MEDIA_TYPE_JSON = MediaType.parse("application/json; charset=utf-8");

// These constants are in the Proximity Service Status enum:
    public static final String STATUS_UNSPECIFIED = "STATUS_UNSPECIFIED";
    public static final String STATUS_ACTIVE = "ACTIVE";
    public static final String STATUS_INACTIVE = "INACTIVE";
    public static final String STATUS_DECOMMISSIONED = "DECOMMISSIONED";
    public static final String STABILITY_UNSPECIFIED = "STABILITY_UNSPECIFIED";

    // These constants are convenience for this app:
    public static final String UNREGISTERED = "UNREGISTERED";
    public static final String NOT_AUTHORIZED = "NOT_AUTHORIZED";
    //
    .header(AUTHORIZATION, BEARER + tok)
*/
