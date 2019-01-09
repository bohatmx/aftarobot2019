import 'package:aftarobotlibrary3/data/routedto.dart';
import 'package:aftarobotlibrary3/util/functions.dart';
import 'package:flutter/material.dart';

abstract class CounterCardListener {
  onCounterCardTapped(int index);
}

class CounterCard extends StatelessWidget {
  final int total, index;
  final String title;
  final TextStyle totalStyle, titleStyle;
  final Color cardColor;
  final Icon icon;
  final CounterCardListener cardListener;
  final AnimationController animation;

  CounterCard(
      {@required this.total,
      @required this.title,
      this.totalStyle,
      this.titleStyle,
      this.cardListener,
      this.cardColor,
      this.animation,
      this.index,
      this.icon});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (cardListener != null && index != null) {
          cardListener.onCounterCardTapped(index);
        }
      },
      child: SizedBox(
        height: 140,
        width: 80,
        child: Card(
          elevation: 4.0,
          color: cardColor == null ? getRandomPastelColor() : cardColor,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                animation == null
                    ? Text(
                        '$total',
                        style: totalStyle == null
                            ? Styles.blackBoldLarge
                            : totalStyle,
                      )
                    : ScaleTransition(
                        scale: animation,
                        child: Text(
                          '$total',
                          style: totalStyle == null
                              ? Styles.blackBoldLarge
                              : totalStyle,
                        ),
                      ),
                SizedBox(
                  height: 4,
                ),
                Text(
                  title,
                  style:
                      titleStyle == null ? Styles.greyLabelSmall : titleStyle,
                ),
                icon == null ? Icon(Icons.print) : icon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RouteCard extends StatefulWidget {
  final RouteDTO route;
  final Color color;
  final int number;

  RouteCard({this.route, this.color, this.number});

  @override
  _RouteCardState createState() => _RouteCardState();
}

class _RouteCardState extends State<RouteCard> {
  int index = 0;
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                SizedBox(
                  width: 28,
                  child: Text(
                    widget.number == null ? '0' : '${widget.number}',
                    style: Styles.pinkBoldSmall,
                  ),
                ),
                Flexible(
                  child: Container(
                    child: Text(
                      widget.route.name,
                      style: Styles.blackBoldMedium,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                SizedBox(
                  width: 28,
                ),
                Flexible(
                  child: Container(
                    child: Text(
                      widget.route.associationName,
                      style: Styles.greyLabelSmall,
                      overflow: TextOverflow.clip,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class Counter extends StatelessWidget {
  final int total;
  final String label;
  final TextStyle totalStyle, labelStyle;

  const Counter(
      {Key key, this.total, this.label, this.totalStyle, this.labelStyle})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          '$total',
          style: totalStyle == null ? Styles.whiteBoldReallyLarge : totalStyle,
        ),
        Text(label, style: labelStyle == null ? Styles.whiteSmall : labelStyle),
      ],
    );
  }
}
