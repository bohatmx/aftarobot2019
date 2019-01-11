import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:latlong/latlong.dart';
import 'package:meta/meta.dart';

Future<List<LandmarkDTO>> calculateAndSortByDistance(
    {@required List<LandmarkDTO> landmarks,
    @required double latitude,
    @required double longitude}) async {
  //
  printLog(
      'sorting ${landmarks.length} landmarks .... distance from:  $latitude   $longitude');
  final Distance distance = new Distance();
  landmarks.forEach((m) {
    final double meters = distance(
        new LatLng(latitude, longitude), new LatLng(m.latitude, m.longitude));
    m.distance = meters;
  });

  landmarks.sort((a, b) => a.distance.compareTo(b.distance));

  return landmarks;
}
