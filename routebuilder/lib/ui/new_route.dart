import 'package:flutter/material.dart';

class NewRoutePage extends StatefulWidget {
  @override
  _NewRoutePageState createState() => _NewRoutePageState();
}

class _NewRoutePageState extends State<NewRoutePage> {
  GlobalKey<ScaffoldState> _key = GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('New Route'),
      ),
    );
  }
}
