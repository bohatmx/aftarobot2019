import 'package:aftarobotlibrary/api/file_util.dart';
import 'package:aftarobotlibrary/data/association_bag.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/citydto.dart';
import 'package:aftarobotlibrary/data/countrydto.dart';
import 'package:aftarobotlibrary/data/landmarkdto.dart';
import 'package:aftarobotlibrary/data/routedto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AssociationBagListener {
  onBag(AssociationBag bag);
}

/*
var qs0 = await fs.collection('associations').getDocuments();
    var qs1 = await fs.collection('vehicleTypes').getDocuments();
    var qs2 = await fs.collection('countries').getDocuments();
 */
class ListAPI {
  static Firestore fs = Firestore.instance;

  static Future<List<VehicleDTO>> getAssociationVehicles(
      String associationPath) async {
    List<VehicleDTO> list = List();
    var qs = await fs
        .document(associationPath)
        .collection('vehicles')
        .getDocuments();
    if (qs.documents.isNotEmpty) {
      qs.documents.forEach((doc) {
        list.add(VehicleDTO.fromJson(doc.data));
      });
    }
    return list;
  }

  static Future<List<UserDTO>> getAssociationUsers(
      String associationPath) async {
    List<UserDTO> list = List();
    var qs =
        await fs.document(associationPath).collection('users').getDocuments();
    if (qs.documents.isNotEmpty) {
      qs.documents.forEach((doc) {
        list.add(UserDTO.fromJson(doc.data));
      });
    }
    return list;
  }

  static Future<List<AssociationDTO>> getAssociations() async {
    List<AssociationDTO> list = List();
    var qs = await fs.collection('associations').getDocuments();
    if (qs.documents.isNotEmpty) {
      qs.documents.forEach((doc) {
        list.add(AssociationDTO.fromJson(doc.data));
      });
    }
    return list;
  }

  static Future<List<LandmarkDTO>> getLandmarks() async {
    List<LandmarkDTO> list = List();
    var qs = await fs.collection('landmarks').getDocuments();
    if (qs.documents.isNotEmpty) {
      qs.documents.forEach((doc) {
        list.add(LandmarkDTO.fromJson(doc.data));
      });
    }
    return list;
  }

  static Future<List<VehicleTypeDTO>> getVehicleTypes() async {
    List<VehicleTypeDTO> list = List();
    var qs = await fs.collection('vehicleTypes').getDocuments();
    if (qs.documents.isNotEmpty) {
      qs.documents.forEach((doc) {
        list.add(VehicleTypeDTO.fromJson(doc.data));
      });
    }
    return list;
  }

  static Future<List<CountryDTO>> getCountries() async {
    List<CountryDTO> list = List();
    var qs = await fs.collection('countries').getDocuments();
    if (qs.documents.isNotEmpty) {
      qs.documents.forEach((doc) {
        list.add(CountryDTO.fromJson(doc.data));
      });
    }
    return list;
  }

  static Future<List<CityDTO>> getSouthAfricanCities(
      {bool forceRefresh}) async {
    List<CountryDTO> list = await LocalDB.getCountries();
    List<CityDTO> cityList = await LocalDB.getCities();
    CountryDTO za;
    list.forEach((c) {
      if (c.name.contains('South Africa')) {
        za = c;
      }
    });

    if (forceRefresh || cityList.isEmpty) {
      await _parseCities(za, cityList);
      return cityList;
    }

    return cityList;
  }

  static Future _parseCities(CountryDTO za, List<CityDTO> cityList) async {
    var qs = await fs.document(za.path).collection('cities').getDocuments();
    qs.documents.forEach((doc) {
      cityList.add(CityDTO.fromJson(doc.data));
    });
  }

  static Future<List<RouteDTO>> getRoutes() async {
    List<RouteDTO> list = List();
    var qs = await fs.collection('routes').getDocuments();
    if (qs.documents.isNotEmpty) {
      qs.documents.forEach((doc) {
        list.add(RouteDTO.fromJson(doc.data));
      });
    }
    return list;
  }

  static Future<RouteDTO> getRouteByID(String routeID) async {
    var qs = await fs
        .collection('routes')
        .where('routeID', isEqualTo: routeID)
        .getDocuments();
    if (qs.documents.isNotEmpty) {
      return RouteDTO.fromJson(qs.documents.first.data);
    } else {
      throw Exception('Route not found');
    }
  }

  static Future<List<AssociationBag>> getAssociationBags(
      AssociationBagListener listener) async {
    List<VehicleTypeDTO> carTypes = List();
    List<UserDTO> users = List();
    List<AssociationDTO> asses = List();
    List<AssociationBag> bags = List();

    var qs0 = await fs.collection('vehicleTypes').getDocuments();
    for (var mdoc in qs0.documents) {
      carTypes.add(VehicleTypeDTO.fromJson(mdoc.data));
    }

    var qs1 = await fs.collection('associations').getDocuments();
    for (var doc in qs1.documents) {
      var ass = AssociationDTO.fromJson(doc.data);
      asses.add(ass);

      AssociationBag bag = AssociationBag();
      bag.association = ass;

      List<UserDTO> admins = List();
      var qs1a = await doc.reference.collection('users').getDocuments();
      for (var doc2 in qs1a.documents) {
        admins.add(UserDTO.fromJson(doc2.data));
      }
      bag.users = admins;

      List<VehicleDTO> cars = List();
      var qs1b = await doc.reference.collection('vehicles').getDocuments();
      for (var doc2 in qs1b.documents) {
        cars.add(VehicleDTO.fromJson(doc2.data));
      }
      bag.cars = cars;

      bag.carTypes = _filter(ass, cars);

      listener.onBag(bag);
      bags.add(bag);
    }

    return bags;
  }

  static List<VehicleTypeDTO> _filter(
      AssociationDTO ass, List<VehicleDTO> cars) {
    List<VehicleTypeDTO> list = List();
    cars.forEach((car) {
      if (!_isVehicleTypeFound(list, car.vehicleType)) {
        list.add(car.vehicleType);
      }
    });

    return list;
  }

  static bool _isVehicleTypeFound(
      List<VehicleTypeDTO> list, VehicleTypeDTO type) {
    var isFound = false;
    list.forEach((t) {
      if (type == null || t == null) {
        //do nothing
      } else {
        if (type.vehicleTypeID == t.vehicleTypeID) {
          isFound = true;
        }
      }
    });
    return isFound;
  }
}
