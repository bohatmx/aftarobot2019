import 'package:flutter/material.dart';


class BackgroundLocationTest extends StatefulWidget {
  @override
  _BackgroundLocationTestState createState() => _BackgroundLocationTestState();
}

class _BackgroundLocationTestState extends State<BackgroundLocationTest> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('text'),
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