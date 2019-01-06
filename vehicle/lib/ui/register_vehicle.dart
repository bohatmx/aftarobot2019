import 'package:aftarobotlibrary3/api/sharedprefs.dart';
import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/vehicledto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/snack.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vehicle/vehicle_bloc/vehicle_bloc.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  TextEditingController textEditingController = TextEditingController();
  GlobalKey<AutoCompleteTextFieldState<AssociationDTO>> _assocKey = GlobalKey();

  List<AssociationDTO> _associations = List();
  VehicleAppBloc bloc = vehicleAppBloc;

  @override
  void initState() {
    super.initState();
    bloc.getAssociations();
  }

  void onAssociationTapped(AssociationDTO ass) {
    print('### association selected : ${ass.associationName}');

    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => VehicleSelector(
                  associationPath: ass.path,
                )));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    return StreamBuilder<List<AssociationDTO>>(
      initialData: bloc.associations,
      stream: bloc.associationStream,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
            print('\n\n####### stream active, passing on associations .....');
            _associations = snapshot.data;
//            _buildDropDown();
            break;
          case ConnectionState.none:
            break;
          case ConnectionState.waiting:
            break;
          case ConnectionState.done:
            break;
        }
        return WillPopScope(
          onWillPop: () {
            print('ignoring pleas to leave The Roach Motel');
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text('Vehicle Registration'),
            ),
            backgroundColor: Colors.brown.shade100,
            body: ListView.builder(
                itemCount: _associations.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8),
                    child: GestureDetector(
                      onTap: () {
                        onAssociationTapped(_associations.elementAt(index));
                      },
                      child: Card(
                        color: getRandomPastelColor(),
                        elevation: 4,
                        child: ListTile(
                          leading: Icon(
                            Icons.location_city,
                            color: getRandomColor(),
                          ),
                          title: Text(
                              '${_associations.elementAt(index).associationName}'),
                        ),
                      ),
                    ),
                  );
                }),
          ),
        );
      },
    );
  }
}

class VehicleSelector extends StatefulWidget {
  final String associationPath;

  VehicleSelector({this.associationPath});

  @override
  VehicleSelectorState createState() {
    return new VehicleSelectorState();
  }
}

class VehicleSelectorState extends State<VehicleSelector>
    implements SnackBarListener {
  GlobalKey<ScaffoldState> _key = GlobalKey();
  VehicleAppBloc bloc = vehicleAppBloc;
  List<VehicleDTO> vehicles = List(), filteredVehicles = List();
  String filter;
  @override
  void initState() {
    super.initState();
    bloc.getVehicles(widget.associationPath);
  }

  void _filterVehicles() {
    if (filter.isEmpty) {
      setState(() {
        filteredVehicles.clear();
      });
      return;
    }
    filteredVehicles.clear();
    vehicles.forEach((v) {
      if (v.vehicleReg.toLowerCase().contains(filter)) {
        filteredVehicles.add(v);
      }
    });
    filteredVehicles.sort((a, b) => a.vehicleReg.compareTo(b.vehicleReg));
    setState(() {});
  }

  void _dismissKeyboard() {
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  _registerVehicle(VehicleDTO v) async {
    print('### 🎾 --- registerVehicle ....... ${v.vehicleReg}');
    await Prefs.saveVehicle(v);
    print('### 🔵 --- vehicle registered on device : ${v.vehicleReg}');
    AppSnackbar.showSnackbar(
        scaffoldKey: _key,
        message: 'Vehicle ${v.vehicleReg} registered for device',
        textColor: Colors.yellow,
        backgroundColor: Colors.black);
  }

  Widget _getBottom() {
    return PreferredSize(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                elevation: 6,
                child: TextField(
                  style: Styles.blackMedium,
                  decoration: InputDecoration(
                      suffix: IconButton(
                        icon: Icon(
                          Icons.close,
                          color: Colors.pink,
                        ),
                        onPressed: _dismissKeyboard,
                      ),
                      hintText: 'Find vehicle '),
                  onChanged: (val) {
                    filter = val;
                    _filterVehicles();
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(
                  'Vehicles Found:',
                  style: Styles.whiteBoldMedium,
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  '${filteredVehicles.length}',
                  style: Styles.blackBoldReallyLarge,
                ),
                SizedBox(
                  width: 40,
                )
              ],
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
        preferredSize: Size.fromHeight(180));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        initialData: bloc.vehicles,
        stream: bloc.vehicleStream,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.active:
              print('🔵 ConnectionState.active set vehicles from stream data');
              vehicles = snapshot.data;
              break;
            case ConnectionState.waiting:
              print(' 🎾 ConnectionState.waiting .......');
              break;
            case ConnectionState.done:
              print(' 🎾 ConnectionState.done ???');
              break;
            case ConnectionState.none:
              print(' 🎾 ConnectionState.none - do nuthin ...');
              break;
          }
          return Scaffold(
            key: _key,
            appBar: AppBar(
              title: Text(
                'Vehicle App Registration',
                style: Styles.whiteBoldMedium,
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    bloc.getVehicles(widget.associationPath);
                  },
                ),
              ],
              bottom: _getBottom(),
              backgroundColor: Colors.indigo.shade300,
            ),
            body: Stack(
              children: <Widget>[
                Opacity(
                  opacity: 0.2,
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/fincash.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                filteredVehicles.isEmpty
                    ? Container()
                    : ListView.builder(
                        itemCount: filteredVehicles.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, right: 16),
                            child: GestureDetector(
                              onTap: () {
                                _registerVehicle(
                                    filteredVehicles.elementAt(index));
                              },
                              child: Card(
                                elevation: 4,
                                child: ListTile(
                                  leading: Icon(
                                    Icons.airport_shuttle,
                                    color: getRandomColor(),
                                  ),
                                  title: Text(
                                    '${filteredVehicles.elementAt(index).vehicleReg}',
                                    style: Styles.blackBoldMedium,
                                  ),
                                  subtitle: Text(
                                      '${filteredVehicles.elementAt(index).vehicleType.make} '
                                      '${filteredVehicles.elementAt(index).vehicleType.model}'),
                                ),
                              ),
                            ),
                          );
                        }),
              ],
            ),
          );
        });
  }

  @override
  onActionPressed(int action) {
    return null;
  }
}
