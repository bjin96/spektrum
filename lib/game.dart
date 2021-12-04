import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:spektrum/result.dart';

import 'excerpt.dart';

const Map<String, Color> PARTY_COLOR = {
  'SPD': Color(0xffe2010f),
  'FDP': Color(0xffffee01),
  'CDU/CSU': Colors.black,
  'BÜNDNIS 90/DIE GRÜNEN': Color(0xff3b8024),
  'DIE LINKE': Color(0xffce368d),
  'AfD': Color(0xff1c9fdf),
};

class GamePage extends StatefulWidget {
  GamePage({Key key, this.opponent}) : super(key: key);

  final String opponent;

  @override
  _GamePage createState() => _GamePage(opponent: opponent);
}

class _GamePage extends State<GamePage> {
  PageController _pageController = PageController();
  List<Excerpt> _excerptList;
  List<Result> _resultList;
  int _gameId;
  final String opponent;

  _GamePage({this.opponent});

  Future<bool> fetchGameData() async {
    _gameId = await Excerpt.getGameId(FirebaseAuth.instance.currentUser.email, opponent);
    _excerptList = await Excerpt.getExcerptListForGame(_gameId);
    _resultList = await Result.fetchResultsByGameId(_gameId);
    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController(initialPage: 0);

    return PageView(
      scrollDirection: Axis.horizontal,
      reverse: false,
      controller: controller,
      physics: NeverScrollableScrollPhysics(),
      children: <Widget>[
        Center(
          child: FutureBuilder(
            future: fetchGameData(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) {
                return MyHomePage(
                  excerpt: _excerptList[0],
                  result: _resultList.length > 0 ? _resultList[0] : null,
                  gameId: _gameId,
                  pageController: controller,
                  opponent: opponent,
                  pageNumber: 1,
                );
              } else {
                return Scaffold(
                  body: Center(
                    child: Container(
                      child: Text(
                        'spektrum',
                        textScaleFactor: 3,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        Center(
          child: FutureBuilder(
            future: fetchGameData(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) {
                return MyHomePage(
                  excerpt: _excerptList[1],
                  result: _resultList.length > 1 ? _resultList[1] : null,
                  gameId: _gameId,
                  pageController: controller,
                  opponent: opponent,
                  pageNumber: 2,
                );
              } else {
                return Scaffold(
                  body: Center(
                    child: Container(
                      child: Text(
                        'spektrum',
                        textScaleFactor: 3,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        Center(
          child: FutureBuilder(
            future: fetchGameData(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) {
                return MyHomePage(
                  excerpt: _excerptList[2],
                  result: _resultList.length > 2 ? _resultList[2] : null,
                  gameId: _gameId,
                  pageController: controller,
                  opponent: opponent,
                  pageNumber: 3,
                );
              } else {
                return Scaffold(
                  body: Center(
                    child: Container(
                      child: Text(
                        'spektrum',
                        textScaleFactor: 3,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage(
      {Key key, this.excerpt, this.gameId, this.result, this.pageController, this.opponent, this.pageNumber})
      : super(key: key);

  final Excerpt excerpt;
  final Result result;
  final int gameId;
  final PageController pageController;
  final String opponent;
  final int pageNumber;

  @override
  _MyHomePageState createState() => _MyHomePageState(excerpt, gameId, result, pageController, opponent, pageNumber);
}

class _MyHomePageState extends State<MyHomePage> with AutomaticKeepAliveClientMixin<MyHomePage> {
  Excerpt excerpt;
  bool _showCorrection = false;
  int gameId;
  Result result;
  double _currentSocioEconomicValue = 0;
  double _currentSocioCulturalValue = 0;
  PageController pageController;
  String opponent;
  int pageNumber;
  bool alreadyReported = false;

  _MyHomePageState(
      Excerpt excerpt, int gameId, Result result, PageController pageController, String opponent, int pageNumber) {
    this.excerpt = excerpt;
    this.gameId = gameId;
    this.result = result;
    this.pageController = pageController;
    this.opponent = opponent;
    this.pageNumber = pageNumber;

    if (result != null) {
      _showCorrection = true;
      _currentSocioEconomicValue = result.socioEconomicCoordinate.toDouble();
      _currentSocioCulturalValue = result.socioCulturalCoordinate.toDouble();
    }
  }

  @override
  bool get wantKeepAlive => true;

  double calculateEuclideanDistance() {
    return sqrt(pow(_currentSocioCulturalValue - excerpt.socioCulturalCoordinate, 2) +
        pow(_currentSocioEconomicValue - excerpt.socioEconomicCoordinate, 2));
  }

  Function onSubmitExcerpt(int excerptCounter) {
    void _onSubmitExcerpt() {
      Result(
        gameId: gameId,
        excerptCounter: excerptCounter,
        userId: FirebaseAuth.instance.currentUser.email,
        socioCulturalCoordinate: _currentSocioCulturalValue.toInt(),
        socioEconomicCoordinate: _currentSocioEconomicValue.toInt(),
        distance: calculateEuclideanDistance(),
      ).store();
      if (pageController.page == 2) {
        Result.setGameFinished(opponent);
      }
      setState(() {
        _showCorrection = true;
      });
    }

    return _onSubmitExcerpt;
  }

  void onSubmitReport(StateSetter setState) {
    setState(() {
      alreadyReported = true;
    });
    excerpt.report();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onPanUpdate: (data) {
        if (data.delta.dx > 0) {
          pageController.animateToPage(
            pageController.page.toInt() - 1,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
        if (data.delta.dx < 0 && _showCorrection) {
          if (pageController.page == 2) {
            Navigator.of(context).pop();
          } else {
            pageController.animateToPage(
              pageController.page.toInt() + 1,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          }
        }
      },
      child: Scaffold(
        floatingActionButton: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop,
        body: GridView.count(
          childAspectRatio: MediaQuery.of(context).size.width /
              (MediaQuery.of(context).size.height -
                  (MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom)) *
              2,
          crossAxisCount: 1,
          children: <Widget>[
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: pageNumber == 1 ? Icon(Icons.circle) : Icon(Icons.brightness_1_outlined),
                        disabledColor: Colors.blueGrey,
                        iconSize: 10,
                        onPressed: null,
                      ),
                      IconButton(
                        icon: pageNumber == 2 ? Icon(Icons.circle) : Icon(Icons.brightness_1_outlined),
                        disabledColor: Colors.blueGrey,
                        iconSize: 10,
                        onPressed: null,
                      ),
                      IconButton(
                        icon: pageNumber == 3 ? Icon(Icons.circle) : Icon(Icons.brightness_1_outlined),
                        disabledColor: Colors.blueGrey,
                        iconSize: 10,
                        onPressed: null,
                      ),
                    ],
                  ),
                  Center(
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 15,
                        right: 15,
                        top: 10,
                        bottom: 30,
                      ),
                      child: Text(
                        excerpt.topic,
                        textScaleFactor: 1.3,
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(15),
                            child: Column(
                              children: [
                                Icon(Icons.format_quote_rounded, size: 30, color: Colors.blueGrey),
                                Text(
                                  excerpt.content,
                                  textScaleFactor: 1,
                                  style: TextStyle(color: Colors.black),
                                ),
                                // Currently allows same user to report multiple times due to re-opening the game.
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.bug_report_outlined),
                                      onPressed: alreadyReported ? null : () => onSubmitReport(setState),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        padding: EdgeInsets.only(
                          top: 0,
                          bottom: 0,
                          left: 20,
                          right: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'soziokulturelle achse',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  Visibility(
                    child: Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
                      child: Slider(
                        value: _currentSocioCulturalValue,
                        min: -10,
                        max: 10,
                        divisions: 20,
                        label: _currentSocioCulturalValue.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _currentSocioCulturalValue = value;
                          });
                        },
                      ),
                    ),
                    visible: !_showCorrection,
                  ),
                  Visibility(
                    child: Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
                      child: RangeSlider(
                        values: _currentSocioCulturalValue < excerpt.socioCulturalCoordinate
                            ? RangeValues(_currentSocioCulturalValue, excerpt.socioCulturalCoordinate.toDouble())
                            : RangeValues(excerpt.socioCulturalCoordinate.toDouble(), _currentSocioCulturalValue),
                        min: -10,
                        max: 10,
                        divisions: 20,
                        labels: RangeLabels(
                            _currentSocioCulturalValue.round().toString(), excerpt.socioCulturalCoordinate.toString()),
                        onChanged: null,
                      ),
                    ),
                    visible: _showCorrection,
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('liberal'), Text('konservativ')],
                    ),
                  ),
                  Text(
                    'sozioökonomische achse',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  Visibility(
                    child: Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
                      child: Slider(
                        value: _currentSocioEconomicValue,
                        min: -10,
                        max: 10,
                        divisions: 20,
                        label: _currentSocioEconomicValue.round().toString(),
                        onChanged: (double value) {
                          setState(() {
                            _currentSocioEconomicValue = value;
                          });
                        },
                      ),
                    ),
                    visible: !_showCorrection,
                  ),
                  Visibility(
                    child: Container(
                      padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 0),
                      child: RangeSlider(
                        values: _currentSocioEconomicValue < excerpt.socioEconomicCoordinate
                            ? RangeValues(_currentSocioEconomicValue, excerpt.socioEconomicCoordinate.toDouble())
                            : RangeValues(excerpt.socioEconomicCoordinate.toDouble(), _currentSocioEconomicValue),
                        min: -10,
                        max: 10,
                        divisions: 20,
                        labels: RangeLabels(
                            _currentSocioEconomicValue.round().toString(), excerpt.socioEconomicCoordinate.toString()),
                        onChanged: null,
                      ),
                    ),
                    visible: _showCorrection,
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('staat'), Text('markt')],
                    ),
                  ),
                  Visibility(
                    child: ElevatedButton(
                        onPressed: _showCorrection ? null : onSubmitExcerpt(excerpt.counter), child: Text('fertig')),
                    visible: !_showCorrection,
                  ),
                  Visibility(
                    child: Column(
                      children: [
                        IconButton(
                          iconSize: 75,
                          icon: ClipRRect(
                            borderRadius: BorderRadius.circular(200.0),
                            child: Image.asset('assets/portrait_id/${excerpt.speakerId}.jpg'),
                          ),
                          onPressed: () {
                            return showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: PARTY_COLOR[excerpt.party],
                                  content: Container(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          iconSize: 75,
                                          icon: ClipRRect(
                                            borderRadius: BorderRadius.circular(200.0),
                                            child: Image.asset('assets/portrait_id/${excerpt.speakerId}.jpg'),
                                          ),
                                          onPressed: null,
                                        ),
                                        Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(bottom: 20),
                                            child: Text(
                                              '${excerpt.speakerFirstName} ${excerpt.speakerLastName} (${excerpt.party})',
                                              style: TextStyle(
                                                  color: excerpt.party == 'FDP' ? Colors.black : Colors.white),
                                            ),
                                          ),
                                        ),
                                        Flexible(
                                          child: SingleChildScrollView(
                                            child: Text(
                                              excerpt.bio != null ? excerpt.bio : '',
                                              textScaleFactor: 0.8,
                                              style: TextStyle(
                                                  color: excerpt.party == 'FDP' ? Colors.black : Colors.white),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        Text(
                          '${excerpt.speakerFirstName} ${excerpt.speakerLastName} (${excerpt.party})',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    visible: _showCorrection,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
