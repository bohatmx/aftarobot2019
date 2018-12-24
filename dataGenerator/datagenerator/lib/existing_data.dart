import 'package:aftarobotlibrary/api/list_api.dart';
import 'package:aftarobotlibrary/data/association_bag.dart';
import 'package:aftarobotlibrary/util/functions.dart';
import 'package:aftarobotlibrary/util/snack.dart';
import 'package:datagenerator/city_map_search.dart';
import 'package:datagenerator/city_migrate.dart';
import 'package:datagenerator/generator.dart';
import 'package:datagenerator/main.dart';
import 'package:datagenerator/new_page.dart';
import 'package:datagenerator/route_migrator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ExistingDataPage extends StatefulWidget {
  @override
  _ExistingDataPageState createState() => _ExistingDataPageState();
}

class _ExistingDataPageState extends State<ExistingDataPage>
    implements GeneratorListener, SnackBarListener, AssociationBagListener {
  List<Msg> _messages = List();
  List<AssociationBag> bags = List(), activeBags = List();
  ScrollController scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _key = new GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() async {
    activeBags = await ListAPI.getAssociationBags(this);
    setState(() {});
  }

  void _refresh() {
    _start();
    setState(() {
      activeBags.clear();
      errorText = null;
      counter = 0;
    });
  }

  void _startPage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => LocationTestPage()),
    );
  }

  void _startGenerationPage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => GenerationPage()),
    );
  }

  void _startRouteMigrator() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => RouteMigrator()),
    );
  }

  void _startCitySearchPage() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => CityMapSearch()),
    );
  }

  void _startCityMigrator() {
    Navigator.push(
      context,
      new MaterialPageRoute(builder: (context) => CityMigrator()),
    );
  }

  String errorText;

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
                  color: Colors.indigo,
                  elevation: 8.0,
                  onPressed: _refresh,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Get Fresh Data',
                      style: Styles.whiteSmall,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20.0),
                  child: Column(
                    children: <Widget>[
                      Text(
                        '$counter',
                        style: Styles.blackBoldLarge,
                      ),
                      Text(
                        'Associations',
                        style: Styles.blackBoldSmall,
                      )
                    ],
                  ),
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
            icon: Icon(Icons.refresh),
            onPressed: null,
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
          BagList(
            activeBags: activeBags,
            scrollController: scrollController,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.loyalty),
            title: Text(
              'Cities',
              style: Styles.blackSmall,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            title: Text(
              'Search',
              style: Styles.blackSmall,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            title: Text(
              'Location',
              style: Styles.blackSmall,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            title: Text(
              'Build',
              style: Styles.blackSmall,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions),
            title: Text(
              'Routes',
              style: Styles.blackSmall,
            ),
          ),
        ],
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          switch (index) {
            case 0:
              _startCityMigrator();
              break;
            case 1:
              _startCitySearchPage();
              break;
            case 2:
              _startPage();
              break;
            case 3:
              _startGenerationPage();
              break;
            case 4:
              _startRouteMigrator();
              break;
          }
        },
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

  @override
  onBag(AssociationBag bag) {
    print(
        '_ExistingDataPageState.onBag #################### bag coming in ....${DateTime.now().toIso8601String()}');
    setState(() {
      activeBags.add(bag);
      counter++;
    });
  }
}

class AssocCard extends StatelessWidget {
  final double elevation;
  final AssociationBag bag;
  final Color color;
  AssocCard({this.elevation, this.bag, this.color});

  @override
  Widget build(BuildContext context) {
    bag.filterUsers();
    return Card(
      elevation: elevation == null ? 2.0 : elevation,
      color: color == null ? Colors.white : color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 10.0,
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    child: Text(
                      bag.association.associationName,
                      style: Styles.blackBoldMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 10.0,
            ),
            Row(
              children: <Widget>[
                Text(
                  bag.association.associationID == null
                      ? ''
                      : bag.association.associationID,
                  style: Styles.greyLabelSmall,
                ),
              ],
            ),
            SizedBox(height: 8.0),
            CardItem(
              title: 'Owners',
              total: bag.owners.length,
              titleStyle: Styles.blackBoldSmall,
              totalStyle: Styles.pinkBoldMedium,
              icon: Icon(Icons.people),
            ),
            CardItem(
              title: 'Drivers',
              total: bag.drivers.length,
              titleStyle: Styles.blackBoldSmall,
              totalStyle: Styles.blueBoldMedium,
              icon: Icon(Icons.airport_shuttle),
            ),
            SizedBox(
              height: 4.0,
            ),
            CardItem(
              title: 'Marshals',
              total: bag.marshals.length,
              titleStyle: Styles.blackBoldSmall,
              totalStyle: Styles.tealBoldMedium,
              icon: Icon(Icons.pan_tool),
            ),
            CardItem(
              title: 'Association Staff',
              total: bag.admins.length,
              titleStyle: Styles.blackBoldSmall,
              totalStyle: Styles.blackBoldMedium,
              icon: Icon(Icons.people),
            ),
            SizedBox(
              height: 4.0,
            ),
            CardItem(
              title: 'Vehicles',
              total: bag.cars.length,
              titleStyle: Styles.blackBoldSmall,
              totalStyle: Styles.blueBoldMedium,
              icon: Icon(Icons.airport_shuttle),
            ),
            CardItem(
              title: 'Vehicle Types',
              total: bag.carTypes.length,
              titleStyle: Styles.blackBoldSmall,
              totalStyle: Styles.blackBoldMedium,
              icon: Icon(
                Icons.airport_shuttle,
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardItem extends StatelessWidget {
  final Icon icon;
  final String title;
  final int total;
  final TextStyle titleStyle, totalStyle;

  CardItem(
      {this.icon, this.title, this.total, this.titleStyle, this.totalStyle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 60.0,
            child: icon == null ? Icon(Icons.apps) : icon,
          ),
          SizedBox(
            width: 40.0,
            child: Text(
              '$total',
              style: totalStyle == null ? Styles.pinkBoldSmall : totalStyle,
            ),
          ),
          Text(
            title,
            style: titleStyle == null ? Styles.blackBoldSmall : titleStyle,
          ),
        ],
      ),
    );
  }
}

class BagList extends StatelessWidget {
  final List<AssociationBag> activeBags;
  final ScrollController scrollController;

  BagList({this.activeBags, this.scrollController});

  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
      );
    });
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ListView.builder(
            itemCount: activeBags == null ? 0 : activeBags.length,
            controller: scrollController,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: AssocCard(
                  elevation: 4.0,
                  color: getRandomPastelColor(),
                  bag: activeBags.elementAt(index),
                ),
              );
            }),
      ),
    );
  }
}
