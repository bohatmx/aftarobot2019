import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:datagenerator/dashboard.dart';
import 'package:datagenerator/generator.dart';
import 'package:datagenerator/new_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

///This API Key will be used for both the interactive maps as well as the static maps.
///Make sure that you have enabled the following APIs in the Google API Console (https://console.developers.google.com/apis)
/// - Static Maps API
/// - Android Maps API
/// - iOS Maps API
const API_KEY = "AIzaSyBj5ONubUcdtweuIdQPFszc2Z_kZdhd5g8";

void main() {
  runApp(new MyApp());
}

//void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Migrator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: Dashboard(),
    );
  }
}

class GenerationPage extends StatefulWidget {
  @override
  _GenerationPageState createState() => _GenerationPageState();
}

class _GenerationPageState extends State<GenerationPage>
    implements GeneratorListener, SnackBarListener {
  List<Msg> _messages = List();
  ScrollController scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  void _start() {
    _refresh();
    Generator.generate(this);
  }

  void _showExistingData() {
    Generator.getExistingData(this);
  }

  void _refresh() {
    setState(() {
      _messages.clear();
      errorText = null;
    });
  }

  Widget _getListView() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    });
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 4.0,
        color: Colors.purple.shade50,
        child: Padding(
          padding: const EdgeInsets.only(top: 20.0),
          child: ListView.builder(
              itemCount: _messages == null ? 0 : _messages.length,
              controller: scrollController,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(
                    _messages.elementAt(index).message,
                    style: _messages.elementAt(index).style,
                  ),
                  leading: _messages.elementAt(index).icon,
                );
              }),
        ),
      ),
    );
  }

  void _startLocationTestPage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => LocationTestPage()),
    );
  }

  void _startExistingPage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => Dashboard()),
    );
  }

  Widget _getThis() {
    PageRouteBuilder(
      pageBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        return LocationTestPage();
      },
      transitionsBuilder: (BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) {
        return SlideTransition(
          position: new Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: new SlideTransition(
            position: new Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-1.0, 0.0),
            ).animate(secondaryAnimation),
            child: child,
          ),
        );
      },
    );
  }

  String errorText;
  Widget _getCounterView() {
    if (counter == 0) {
      return Container();
    }
    if (counter < 3) {
      return Text(
        '$counter',
        style: Styles.blackBoldSmall,
      );
    }
    if (counter < 20) {
      return Text(
        '$counter',
        style: Styles.blackBoldMedium,
      );
    }
    if (counter < 100) {
      return Text(
        '$counter',
        style: Styles.blackBoldLarge,
      );
    }

    return Text(
      '$counter',
      style: Styles.blackBoldLarge,
    );
  }

  Widget _getBottom() {
    return PreferredSize(
      preferredSize: Size.fromHeight(100.0),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(
                top: 10.0, bottom: 20.0, left: 10.0, right: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  color: Colors.pink,
                  elevation: 8.0,
                  onPressed: _start,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Start Generation',
                      style: Styles.whiteSmall,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: _getCounterView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _doSomething() {
    print('_DGHomePageState._doSomething ${DateTime.now().toIso8601String()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text('AftaRobot Data'),
        leading: IconButton(icon: Icon(Icons.apps), onPressed: _doSomething),
        bottom: _getBottom(),
        backgroundColor: Colors.purple.shade300,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.location_on),
            onPressed: _startLocationTestPage,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _startExistingPage,
          ),
        ],
      ),
      backgroundColor: Colors.purple.shade100,
      body: Stack(
        children: <Widget>[
          Opacity(
            opacity: 0.3,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/fincash.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          _getListView(),
        ],
      ),
    );
  }

  @override
  onEvent(Msg msg) {
    setState(() {
      _messages.add(msg);
    });
  }

  @override
  onActionPressed(int action) {
    return null;
  }

  @override
  onError(String message) {
    AppSnackbar.showErrorSnackbar(
        scaffoldKey: _key, message: message, listener: this, actionLabel: "OK");
    setState(() {
      errorText = message;
    });
  }

  int counter = 0;
  @override
  onRecordAdded() {
    setState(() {
      counter++;
    });
  }
}
