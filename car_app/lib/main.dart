import 'package:aftarobotlibrary/util/city_map_search.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return MaterialApp(
      title: 'CarApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
      ),
      home: MyHomePage(title: 'AftaRobot CarApp'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _test();
  }

  void _test() async {
    Firestore fs = Firestore.instance;
    var qs = await fs.collection('associations').getDocuments();
    print(
        '_MyHomePageState._test ############# yay! asses found: ${qs.documents.length}');
    setState(() {
      _counter = 33333;
    });
  }

  void _startCitySearchMap() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => CityMapSearch()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'AftaRobot CarApp',
              style: Styles.purpleReallyLarge,
            ),
            Text(
              'The new Autonomous Vehicle App',
              style: Theme.of(context).textTheme.display1,
            ),
            Text(
              'Transportation Data collection without human intervention or hassle.',
              style: Styles.tealBoldSmall,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startCitySearchMap,
        tooltip: 'Increment',
        child: Icon(Icons.map),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
