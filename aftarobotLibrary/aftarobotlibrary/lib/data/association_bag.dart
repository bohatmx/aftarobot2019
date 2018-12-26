import 'package:aftarobotlibrary/api/data_api.dart';
import 'package:aftarobotlibrary/data/associationdto.dart';
import 'package:aftarobotlibrary/data/userdto.dart';
import 'package:aftarobotlibrary/data/vehicledto.dart';
import 'package:aftarobotlibrary/data/vehicletypedto.dart';

class AssociationBag {
  AssociationDTO association;
  List<VehicleDTO> cars;
  List<VehicleTypeDTO> carTypes;
  List<UserDTO> users = List(),
      owners = List(),
      drivers = List(),
      marshals = List(),
      patrollers = List(),
      officeAdmins = List();

  AssociationBag(
      {this.association,
      this.cars,
      this.carTypes,
      this.users,
      this.owners,
      this.drivers,
      this.marshals,
      this.patrollers});

  void filterUsers() {
    _initializeLists();

    users.forEach((user) {
      switch (user.userType) {
        case DataAPI.OWNER:
          owners.add(user);
          break;
        case DataAPI.ASSOC_ADMIN:
          officeAdmins.add(user);
          break;
        case DataAPI.DRIVER:
          drivers.add(user);
          break;
        case DataAPI.MARSHAL:
          marshals.add(user);
          break;
        case DataAPI.PATROLLER:
          patrollers.add(user);
          break;
      }
    });
  }

  void _initializeLists() {
    owners = List();
    officeAdmins = List();
    drivers = List();
    marshals = List();
    patrollers = List();
  }
}
