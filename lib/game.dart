import 'dart:math';

import 'package:flutter/material.dart';
import 'package:spektrum/result.dart';

import 'excerpt.dart';

class GamePage extends StatefulWidget {
  GamePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _GamePage createState() => _GamePage();
}

class _GamePage extends State<GamePage> {
  PageController _pageController = PageController();
  List<Excerpt> _excerptList;
  int _gameId;

  Future<bool> fetchGameData() async {
    _excerptList = await Excerpt.getRandomExcerptList();
    _gameId = await Result.getNewGameId();
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
      children: <Widget>[
        Center(
          child: FutureBuilder(
            future: fetchGameData(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (snapshot.hasData) {
                return MyHomePage(
                  title: 'Page 1',
                  excerpt: _excerptList[0],
                  gameId: _gameId,
                );
              } else {
                return SizedBox(
                  child: CircularProgressIndicator(),
                  width: 60,
                  height: 60,
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
                  title: 'Page 2',
                  excerpt: _excerptList[1],
                  gameId: _gameId,
                );
              } else {
                return SizedBox(
                  child: CircularProgressIndicator(),
                  width: 60,
                  height: 60,
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
                  title: 'Page 3',
                  excerpt: _excerptList[2],
                  gameId: _gameId,
                );
              } else {
                return SizedBox(
                  child: CircularProgressIndicator(),
                  width: 60,
                  height: 60,
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
                return ResultPage(
                  gameId: _gameId,
                );
              } else {
                return SizedBox(
                  child: CircularProgressIndicator(),
                  width: 60,
                  height: 60,
                );
              }
            },
          ),
        )
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title, this.excerpt, this.gameId}) : super(key: key);

  final String title;
  final Excerpt excerpt;
  final int gameId;

  @override
  _MyHomePageState createState() => _MyHomePageState(excerpt: excerpt, gameId: gameId);
}

class _MyHomePageState extends State<MyHomePage> with AutomaticKeepAliveClientMixin<MyHomePage> {
  Excerpt excerpt;
  bool _showCorrection = false;
  int gameId;
  double _currentSocioEconomicValue = 0;
  double _currentSocioCulturalValue = 0;

  _MyHomePageState({this.excerpt, this.gameId});

  @override
  bool get wantKeepAlive => true;

  double calculateEuclideanDistance() {
    return sqrt(pow(_currentSocioCulturalValue - excerpt.socioCulturalCoordinate, 2) +
        pow(_currentSocioEconomicValue - excerpt.socioEconomicCoordinate, 2));
  }

  Function onSubmitExcerpt() {
    void _onSubmitExcerpt() {
      Result(
        gameId: gameId,
        userId: 0,
        speechId: excerpt.speechId,
        fragment: excerpt.fragment,
        socioCulturalCoordinate: _currentSocioCulturalValue.toInt(),
        socioEconomicCoordinate: _currentSocioEconomicValue.toInt(),
        distance: calculateEuclideanDistance(),
      ).store();
      setState(() {
        _showCorrection = true;
      });
    }

    return _onSubmitExcerpt;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GridView.count(
        crossAxisCount: 1,
        children: <Widget>[
          Center(
            child: Center(
              child: Container(
                child: Card(
                  child: Padding(
                    child: SingleChildScrollView(
                      child: Text(
                        excerpt.content,
                        textScaleFactor: 1.15,
                      ),
                    ),
                    padding: EdgeInsets.all(15),
                  ),
                ),
                padding: EdgeInsets.all(20),
              ),
            ),
          ),
          Center(
            child: Column(
              children: [
                Text(
                  'Soziokulturelle Achse:',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                    children: [Text('liberal/libertär'), Text('konservativ/autoritär')],
                  ),
                ),
                Text(
                  'Sozioökonomische Achse:',
                  style: TextStyle(fontWeight: FontWeight.bold),
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
                  padding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('Staat'), Text('Markt')],
                  ),
                ),
                Visibility(
                  child: ElevatedButton(onPressed: _showCorrection ? null : onSubmitExcerpt(), child: Text('Fertig')),
                  visible: !_showCorrection,
                ),
                Visibility(
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          '${excerpt.speakerFirstName} ${excerpt.speakerLastName}',
                          textScaleFactor: 1.5,
                        ),
                        Text(
                          '(${excerpt.party})',
                          textScaleFactor: 1.5,
                        ),
                      ],
                    ),
                  ),
                  visible: _showCorrection,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}