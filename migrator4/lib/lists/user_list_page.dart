import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:flutter/material.dart';

class UserListPage extends StatefulWidget {
  @override
  _UserListPageState createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
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
          'UserListPage',
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
                print('_UserListPageState.build ....... in ListView.builder');
                return Container(
                  child: Text("Fake Shit 3"),
                );
              }),
        ],
      ),
    );
  }
}
