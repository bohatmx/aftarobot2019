import 'package:aftarobotlibrary/util/functions.dart';
import 'package:flutter/material.dart';

class RouteListPage extends StatefulWidget {
  @override
  _RouteListPageState createState() => _RouteListPageState();
}

class _RouteListPageState extends State<RouteListPage> {
  List list = List();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RouteListPage',
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
                print('_RouteListPageState.build ....... in ListView.builder');
                return Container();
              }),
        ],
      ),
    );
  }
}
