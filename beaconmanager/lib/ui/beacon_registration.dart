import 'package:crashtest/beacons/beacon_api.dart';
import 'package:crashtest/beacons/google_data/beacon.dart';
import 'package:crashtest/util/functions.dart';
import 'package:crashtest/util/snack.dart';
import 'package:flutter/material.dart';

class BeaconRegistration extends StatelessWidget implements SnackBarListener {
  final Beacon beacon;

  BeaconRegistration({this.beacon});
  void _registerBeacon() async {
    print('⚠️ --- register beacon ....');
    try {
      AppSnackbar.showSnackbarWithProgressIndicator(
          scaffoldKey: _key,
          message: 'Registering beacon ...',
          textColor: Styles.white,
          backgroundColor: Styles.black);
      //call the business logic
      print(
          '############## ℹ️ call the business logic (bloc) to register beacon and put result in stream');
      googleBeaconBloc.registerBeacon(this.beacon);
      //print('✅ ✅ RECEIVED REGISTERED BEACON: ${beacon.toJson()}');
      _key.currentState.removeCurrentSnackBar();
    } catch (e) {
      print('⚠️⚠️⚠️ - problem: $e');
      AppSnackbar.showErrorSnackbar(
          scaffoldKey: _key,
          message: e.toString(),
          listener: this,
          actionLabel: 'close');
    }
  }

  final GlobalKey<ScaffoldState> _key = GlobalKey();
  List<Beacon> beacons = List();
  @override
  Widget build(BuildContext context) {
    print('############## ℹ️ building stateless BeaconRegistration widget');

    if (googleBeaconBloc.associations.isEmpty) {
      print(
          '⚠ ⚠⚠ There are no associations ... asking the bloc to do something ...');
      googleBeaconBloc.initializeData();
    } else {
      print(
          '############## 🔵 found in googleBeaconBloc: ${googleBeaconBloc.associations.length} associations. set up auto-complete text');
      print(
          '############## 🔵 found in googleBeaconBloc: ${googleBeaconBloc.vehicles.length} vehicles. set up auto-complete text');
      beacons = googleBeaconBloc.beacons;
      print(
          '############## 🔵 found in googleBeaconBloc: ${beacons.length} beacons. put in main listview');
      print('Beacon to be registered:  🔵 ️⚠️ ${beacon.toJson()}');
    }
    return StreamBuilder<List<Beacon>>(
      initialData: googleBeaconBloc.beacons,
      stream: googleBeaconBloc.beaconStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          beacons = snapshot.data;
          print(
              '############## 🔵 found in snapshot: ${beacons.length} beacons. put in main listview');
        }
        return Scaffold(
          key: _key,
          body: Stack(
            children: <Widget>[
              ListView.builder(
                  itemCount: beacons.length,
                  itemBuilder: (context, index) {
                    print(beacons.elementAt(index).toJson());
                    var s = beacons.elementAt(index).advertisedId.type;
                    s += ' - ' + beacons.elementAt(index).advertisedId.id;

                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: Card(
                        elevation: 2,
                        color: getRandomPastelColor(),
                        child: ListTile(
                          leading: Icon(
                            Icons.bluetooth_searching,
                            color: Colors.indigo,
                          ),
                          subtitle: Text(
                            beacons.elementAt(index).beaconName,
                            style: Styles.blackBoldSmall,
                          ),
                          title: Text(
                            '$s',
                            style: Styles.greyLabelSmall,
                          ),
                        ),
                      ),
                    );
                  }),
              Positioned(
                bottom: 10,
                left: 10,
                child: Card(
                  elevation: 8.0,
                  color: getRandomPastelColor(),
                  child: Column(
                    children: <Widget>[
                      googleBeaconBloc.isBusy
                          ? Container(
                              color: getRandomColor(),
                              child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: Text(
                                  'Busy ...',
                                  style: Styles.whiteBoldMedium,
                                ),
                              ),
                            )
                          : RaisedButton(
                              elevation: 4.0,
                              color: Colors.pink.shade700,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  'Register Beacon',
                                  style: Styles.whiteSmall,
                                ),
                              ),
                              onPressed: _registerBeacon),
                    ],
                  ),
                ),
              ),
            ],
          ),
          appBar: AppBar(
            title: Text('Beacon Registration'),
            backgroundColor: Colors.brown.shade300,
            bottom: PreferredSize(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '${beacon.advertisedId.type}',
                        style: Styles.whiteBoldMedium,
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Text(
                        '${beacon.advertisedId.id}',
                        style: Styles.blackBoldMedium,
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        '${beacon.description}',
                        style: Styles.blackBoldSmall,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Row(
                        children: <Widget>[
                          Text(
                            'Registered Beacons',
                            style: Styles.whiteBoldMedium,
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Text(
                            '${beacons.length}',
                            style: Styles.blackBoldReallyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                preferredSize: Size.fromHeight(180)),
          ),
          backgroundColor: Colors.brown.shade100,
        );
      },
    );
  }

  @override
  onActionPressed(int action) {
    return null;
  }
}
