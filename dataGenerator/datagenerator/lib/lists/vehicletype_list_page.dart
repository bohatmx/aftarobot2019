import 'package:aftarobotlibrary/util/functions.dart';
import 'package:flutter/material.dart';

class VehicleTypeListPage extends StatefulWidget {
  @override
  _VehicleTypeListPageState createState() => _VehicleTypeListPageState();
}

class _VehicleTypeListPageState extends State<VehicleTypeListPage> {
  List list = List();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    list.add("some string");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'VehicleTypeListPage',
          style: Styles.whiteBoldLarge,
        ),
      ),
      body: Column(
        children: <Widget>[
          Text(
            this.context.toString(),
            style: Styles.blackBoldReallyLarge,
          ),
          ListView.builder(
              itemCount: list.length,
              controller: _scrollController,
              itemBuilder: (context, index) {
                print(
                    '_VehicleTypeListPageState.build ....... in ListView.builder');
                return Container(
                  child: Text("Fake Shit 4"),
                );
              }),
        ],
      ),
    );
  }
}
