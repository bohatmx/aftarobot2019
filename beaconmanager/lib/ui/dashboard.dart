import 'package:crashtest/beacons/beacon_api.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
  }

  test() {
    print('🔵  🔵  🔵  🔵  🔵  start your engines');
    GoogleBeaconBloc api = GoogleBeaconBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('BeaconManager Dashboard'),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.launch),
            onPressed: test,
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: <Widget>[],
          ),
        ),
      ),
    );
  }
}
