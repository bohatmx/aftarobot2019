import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:flutter/material.dart';

class AssociationListPage extends StatefulWidget {
  @override
  _AssociationListPageState createState() => _AssociationListPageState();
}

class _AssociationListPageState extends State<AssociationListPage> {
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
          'AssociationListPage',
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
                    '_AssociationListPageState.build ....... in ListView.builder');
                return Container(
                  child: Text("Fake Shit 2"),
                );
              }),
        ],
      ),
    );
  }
}
