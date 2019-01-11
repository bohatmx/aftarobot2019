import 'package:aftarobotlibrary3/data/landmarkdto.dart';
import 'package:flutter/material.dart';

class CommuterRequestPage extends StatefulWidget {
  final LandmarkDTO landmark;

  CommuterRequestPage({@required this.landmark});

  @override
  _CommuterRequestPageState createState() => _CommuterRequestPageState();
}

class _CommuterRequestPageState extends State<CommuterRequestPage> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('Commuter Taxi Request'),
      ),
    );
  }
}
