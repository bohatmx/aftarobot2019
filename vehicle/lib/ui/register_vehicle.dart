import 'package:aftarobotlibrary3/data/associationdto.dart';
import 'package:aftarobotlibrary3/data/vehicledto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:aftarobotlibrary3/util/snack.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vehicle/ui/landing_page.dart';
import 'package:vehicle/vehicle_bloc/vehicle_bloc.dart';

class Registration extends StatefulWidget {
  @override
  _RegistrationState createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  TextEditingController textEditingController = TextEditingController();

  List<AssociationDTO> _associations = List();

  @override
  void initState() {
    super.initState();
    _getAssociations();
  }

  void _getAssociations() async {
    _associations = await VehicleAppBloc.getAssociationsFirstTime();
    setState(() {});
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
    return WillPopScope(
      onWillPop: () {
        print('ignoring pleas to leave The Roach Motel');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Vehicle Registration',
            style: Styles.whiteBoldMedium,
          ),
          bottom: PreferredSize(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: <Widget>[
                    Text(
                      'Tap Association and and search it\'s Vehicles for selection for the App.',
                      style: Styles.whiteMedium,
                    ),
                    SizedBox(
                      height: 40,
                    ),
                  ],
                ),
              ),
              preferredSize: Size.fromHeight(140)),
        ),
        backgroundColor: Colors.brown.shade100,
        body: ListView.builder(
            itemCount: _associations.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16, top: 8),
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
  List<VehicleDTO> vehicles = List(), filteredVehicles = List();
  String filter;
  @override
  void initState() {
    super.initState();
    _getVehicles();
  }

  void _getVehicles() async {
    vehicles =
        await VehicleAppBloc.getVehiclesFirstTime(widget.associationPath);
    print(
        '+++ have found vehicles using static bloc call, list has: ${vehicles.length}');
    setState(() {});
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
    print('\n\n### 🎾 --- registerVehicle ....... ${v.vehicleReg}');
    AppSnackbar.showSnackbarWithProgressIndicator(
        scaffoldKey: _key,
        message: 'Registering vehicle',
        textColor: Colors.yellow,
        backgroundColor: Colors.black);

    await VehicleAppBloc.registerVehicleOnDevice(v);
    print(
        '### 🎾 --- registerVehicle DONE! popping twice ....... ${v.vehicleReg}');
    _key.currentState.removeCurrentSnackBar();
    Navigator.pop(context);
    Navigator.pop(context);
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => LandingPage()));
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
                  width: 20,
                ),
                Text(
                  'of',
                  style: Styles.whiteBoldMedium,
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  '${vehicles.length}',
                  style: Styles.blackBoldReallyLarge,
                ),
                SizedBox(
                  width: 40,
                ),
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
              _getVehicles();
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
                      padding: const EdgeInsets.only(left: 16.0, right: 16),
                      child: GestureDetector(
                        onTap: () {
                          _registerVehicle(filteredVehicles.elementAt(index));
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
  }

  @override
  onActionPressed(int action) {
    return null;
  }
}
