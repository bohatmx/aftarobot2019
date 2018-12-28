import 'package:google_maps_webservice/directions.dart';

class DirectionsUtil {
  static Future getDirections() async {
    print('\n\n ############################### DirectionsUtil.getDirections');
    final directions = new GoogleMapsDirections(
        apiKey: "AIzaSyBj5ONubUcdtweuIdQPFszc2Z_kZdhd5g8");

    Location origin = Location(-25.67656, 27.5688);
    Location destination = Location(-26.4300, 27.989806);

    var locResult =
        await directions.directionsWithLocation(origin, destination);

    print(
        '\n\n\n################### location status: ${locResult.status} isOk: ${locResult.isOkay} isOverQueryLimit: ${locResult.isOverQueryLimit}');
    if (locResult.isOkay) {
      print(
          "################################### location query: found ${locResult.routes.length} routes");

      locResult.routes.forEach((Route r) {
        print(
            'DirectionsUtil.getDirections ------ polyLine: ${r.overviewPolyline.points}');
        print(
            'DirectionsUtil.getDirections: waypointOrder: ${r.waypointOrder.length}');
        print(r.summary);
        print(r.bounds);
      });
    } else {
      print(locResult.errorMessage);
    }
    print('\n\n\nDirectionsUtil.getDirections. location query done: \n\n\n');
    DirectionsResponse res = await directions.directionsWithAddress(
        "Sandton, South Africa", "Pretoria, South Africa");

    print(res.status);
    if (res.isOkay) {
      print("################################### ${res.routes.length} routes");
      ;
      res.routes.forEach((Route r) {
        print(
            'DirectionsUtil.getDirections ------ polyLine: ${r.overviewPolyline.points}');
        print(
            'DirectionsUtil.getDirections: waypointOrder: ${r.waypointOrder.length}');
        print(r.summary);
        print(r.bounds);
      });
    } else {
      print(res.errorMessage);
    }

    directions.dispose();
    return null;
  }
}
