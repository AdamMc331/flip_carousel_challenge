import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'card_data.dart';
import 'dart:math';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: "Flip Carousel",
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double scrollPercent = 0.0;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.black,
      body: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Room for status bar since we're not using an app bar
          new Container(
            width: double.infinity,
            height: 20.0,
          ),
          // Cards
          new Expanded(
            child: new CardFlipper(
                cards: demoCards,
                onScroll: (double scrollPercent) {
                  setState(() {
                    this.scrollPercent = scrollPercent;
                  });
                }),
          ),
          // Bottom bar
          new BottomBar(
            cardCount: demoCards.length,
            scrollPercent: scrollPercent,
          ),
        ],
      ),
    );
  }
}

class BottomBar extends StatelessWidget {
  final int cardCount;
  final double scrollPercent;

  BottomBar({
    this.cardCount,
    this.scrollPercent,
  });

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: EdgeInsets.only(top: 15.0, bottom: 15.0),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new Center(
              child: new Icon(
                Icons.settings,
                color: Colors.white,
              ),
            ),
          ),
          new Expanded(
            child: new Container(
              width: double.infinity,
              height: 5.0,
              child: new ScrollIndicator(
                cardCount: cardCount,
                scrollPercent: scrollPercent,
              ),
            ),
          ),
          new Expanded(
            child: new Center(
              child: new Icon(
                Icons.add,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScrollIndicator extends StatelessWidget {
  final int cardCount;
  final double scrollPercent;

  ScrollIndicator({
    this.cardCount,
    this.scrollPercent,
  });

  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      painter: new ScrollIndicatorPainter(
        cardCount: cardCount,
        scrollPercent: scrollPercent,
      ),
      child: new Container(),
    );
  }
}

class ScrollIndicatorPainter extends CustomPainter {
  final int cardCount;
  final double scrollPercent;
  final Paint trackPaint;
  final Paint thumbPaint;

  ScrollIndicatorPainter({
    this.cardCount,
    this.scrollPercent,
  })  : trackPaint = new Paint()
          ..color = const Color(0xFF444444)
          ..style = PaintingStyle.fill,
        thumbPaint = new Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw track
    canvas.drawRRect(
        new RRect.fromRectAndCorners(
          new Rect.fromLTWH(
            0.0,
            0.0,
            size.width,
            size.height,
          ),
          topLeft: new Radius.circular(3.0),
          topRight: new Radius.circular(3.0),
          bottomLeft: new Radius.circular(3.0),
          bottomRight: new Radius.circular(3.0),
        ),
        trackPaint);

    // Draw thumb
    final thumbWidth = size.width / cardCount;
    final thumbLeft = scrollPercent * size.width;

    canvas.drawRRect(
        new RRect.fromRectAndCorners(
          new Rect.fromLTWH(
            thumbLeft,
            0.0,
            thumbWidth,
            size.height,
          ),
          topLeft: new Radius.circular(3.0),
          topRight: new Radius.circular(3.0),
          bottomLeft: new Radius.circular(3.0),
          bottomRight: new Radius.circular(3.0),
        ),
        thumbPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class CardFlipper extends StatefulWidget {
  final List<CardViewModel> cards;
  final Function(double scrollPercent) onScroll;

  CardFlipper({
    this.cards,
    this.onScroll,
  });

  @override
  State<StatefulWidget> createState() => new _CardFlipperState();
}

class _CardFlipperState extends State<CardFlipper>
    with TickerProviderStateMixin {
  double scrollPercent = 0.0;
  Offset startDrag;
  double startDragPercentScroll;
  double finishScrollStart;
  double finishScrollEnd;
  AnimationController finishScrollController;

  @override
  void initState() {
    super.initState();

    finishScrollController = new AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..addListener(() {
        setState(() {
          scrollPercent = lerpDouble(
              finishScrollStart, finishScrollEnd, finishScrollController.value);

          if (widget.onScroll != null) {
            widget.onScroll(scrollPercent);
          }
        });
      });
  }

  @override
  void dispose() {
    finishScrollController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    startDrag = details.globalPosition;
    startDragPercentScroll = scrollPercent;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final currentDrag = details.globalPosition;
    final dragDistance = currentDrag.dx - startDrag.dx;
    final singleCardDragPercent = dragDistance / context.size.width;

    final numCards = widget.cards.length;
    setState(() {
      // startDragPercentScroll is how far we scrolled before the user started dragging
      scrollPercent =
          (startDragPercentScroll + (-singleCardDragPercent / numCards))
              .clamp(0.0, 1.0 - (1 / numCards));

      if (widget.onScroll != null) {
        widget.onScroll(scrollPercent);
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final numCards = widget.cards.length;

    // Start the animation from wherever the user finished scrolling
    // Multiplying scroll percent by number of cards helps us figure out where to snap to.
    finishScrollStart = scrollPercent;
    finishScrollEnd = (scrollPercent * numCards).round() / numCards;
    finishScrollController.forward(from: 0.0); // Run full animation

    setState(() {
      startDrag = null;
      startDragPercentScroll = null;
    });
  }

  List<Widget> _buildCards() {
    final numCards = widget.cards.length;

    int index = -1;
    return widget.cards.map((CardViewModel viewModel) {
      ++index;
      return _buildCard(viewModel, index, numCards, scrollPercent);
    }).toList();
  }

  Matrix4 _buildCardProjection(double scrollPercent) {
    // Pre-multiplied matrix of a projection matrix and a view matrix.
    //
    // Projection matrix is a simplified perspective matrix
    // http://web.iitd.ac.in/~hegde/cad/lecture/L9_persproj.pdf
    // in the form of
    // [[1.0, 0.0, 0.0, 0.0],
    //  [0.0, 1.0, 0.0, 0.0],
    //  [0.0, 0.0, 1.0, 0.0],
    //  [0.0, 0.0, -perspective, 1.0]]
    //
    // View matrix is a simplified camera view matrix.
    // Basically re-scales to keep object at original size at angle = 0 at
    // any radius in the form of
    // [[1.0, 0.0, 0.0, 0.0],
    //  [0.0, 1.0, 0.0, 0.0],
    //  [0.0, 0.0, 1.0, -radius],
    //  [0.0, 0.0, 0.0, 1.0]]
    final perspective = 0.002;
    final radius = 1.0;
    final angle = scrollPercent * pi / 8;
    final horizontalTranslation = 0.0;
    Matrix4 projection = new Matrix4.identity()
      ..setEntry(0, 0, 1 / radius)
      ..setEntry(1, 1, 1 / radius)
      ..setEntry(3, 2, -perspective)
      ..setEntry(2, 3, -radius)
      ..setEntry(3, 3, perspective * radius + 1.0);

    // Model matrix by first translating the object from the origin of the world
    // by radius in the z axis and then rotating against the world.
    final rotationPointMultiplier = angle > 0.0 ? angle / angle.abs() : 1.0;
    print('Angle: $angle');
    projection *= new Matrix4.translationValues(
            horizontalTranslation + (rotationPointMultiplier * 300.0),
            0.0,
            0.0) *
        new Matrix4.rotationY(angle) *
        new Matrix4.translationValues(0.0, 0.0, radius) *
        new Matrix4.translationValues(
            -rotationPointMultiplier * 300.0, 0.0, 0.0);

    return projection;
  }

  Widget _buildCard(CardViewModel viewModel, int cardIndex, int cardCount,
      double scrollPercent) {
    // (1 / cardCount) represents at what percentage it means one card has moved
    // off the screen.
    // By dividing our scrollPercent by that number, we know how many cards
    // we have scrolled to the left.
    final cardScrollPercent = scrollPercent / (1 / cardCount);

    // If we're the third card, out of 5, then our beginning scroll position
    // is essentially 3/5th. So we wanna know how far to the left have we scrolled
    // from our base.
    // This number could get weird, but only when the card is on screen, so let's not worry about
    // it being wonky if it's off screen.
    final parallax = scrollPercent - (cardIndex / cardCount);

    return new FractionalTranslation(
      translation: new Offset(cardIndex - cardScrollPercent, 0.0),
      child: new Padding(
        padding: EdgeInsets.all(16.0),
        child: new Transform(
          transform: _buildCardProjection(cardScrollPercent - cardIndex),
          child: Card(
            viewModel: viewModel,
            parallaxPercent: parallax,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: new Stack(
        children: _buildCards(),
      ),
    );
  }
}

class Card extends StatelessWidget {
  final CardViewModel viewModel;
  final double parallaxPercent;

  Card({
    this.viewModel,
    this.parallaxPercent = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return new Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Background
        new ClipRRect(
          borderRadius: new BorderRadius.circular(10.0),
          child: new FractionalTranslation(
            translation: new Offset(parallaxPercent * 2.0, 0.0),
            child: new OverflowBox(
              maxWidth: double.infinity,
              child: Image.asset(
                viewModel.backdropAssetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Content
        new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            new Padding(
              padding: EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0),
              child: new Text(
                viewModel.address.toUpperCase(),
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontFamily: "petita",
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            new Expanded(
              child: new Container(),
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                new Text(
                  "${viewModel.minHeightInFeet} - ${viewModel.maxHeightInFeet}",
                  style: new TextStyle(
                    color: Colors.white,
                    fontSize: 140.0,
                    fontFamily: "petita",
                    letterSpacing: -5.0,
                  ),
                ),
                new Padding(
                  padding: EdgeInsets.only(left: 10.0, top: 30.0),
                  child: new Text(
                    "FT",
                    style: new TextStyle(
                      color: Colors.white,
                      fontSize: 22.0,
                      fontFamily: "petita",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                new Icon(
                  Icons.wb_sunny,
                  color: Colors.white,
                ),
                new Padding(
                  padding: EdgeInsets.only(left: 10.0),
                  child: new Text(
                    "${viewModel.tempInDegrees}°",
                    style: new TextStyle(
                      color: Colors.white,
                      fontFamily: "petita",
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                ),
              ],
            ),
            new Expanded(
              child: new Container(),
            ),
            new Padding(
              padding: EdgeInsets.only(top: 50.0, bottom: 50.0),
              child: Container(
                decoration: new BoxDecoration(
                  borderRadius: BorderRadius.circular(30.0),
                  border: new Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: new Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      new Text(
                        viewModel.weatherType,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: "petita",
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                      new Padding(
                        padding: EdgeInsets.only(left: 10.0, right: 10.0),
                        child: Icon(Icons.wb_cloudy, color: Colors.white),
                      ),
                      new Text(
                        "${viewModel.windSpeedInMph}mph ${viewModel.cardinalDirection}",
                        style: new TextStyle(
                          color: Colors.white,
                          fontFamily: "petita",
                          fontWeight: FontWeight.bold,
                          fontSize: 16.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
