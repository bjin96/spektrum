import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spektrum/game.dart';

import 'model/spektrum_user.dart';
import 'model/pageInfo.dart';

class GameRoomPage extends StatefulWidget {
  GameRoomPage({Key key, this.user, this.opponent}) : super(key: key);

  final SpektrumUser user;
  final String opponent;

  @override
  _GameRoomPageState createState() => _GameRoomPageState(user, opponent);
}

class _GameRoomPageState extends State<GameRoomPage> {
  Future<PreGamePageInfo> preGamePageInfo;

  _GameRoomPageState(SpektrumUser user, String opponent) {
    this.preGamePageInfo = PreGamePageInfo.getPreGamePageInfo(user, opponent);
  }

  void onStartGame(int gameId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GamePage(
                gameId: gameId
              ),
        maintainState: false
      ),
    );
  }

  Padding getDistanceIndicator(String player, double totalDistance) {
    double progressValue = totalDistance / 60; // 60 arbitrary, use 90 for perfect [0, 1] interval.
    Animation<Color> indicatorColor = AlwaysStoppedAnimation<Color>(Colors.black);
    if (progressValue == 0.0) {
      progressValue = 0.01;
    }
    indicatorColor = AlwaysStoppedAnimation<Color>(Color.lerp(Colors.green, Colors.red, progressValue));
    return Padding(
      padding: EdgeInsets.only(
        top: 100,
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height / 3,
                width: 10,
                child: RotatedBox(
                  quarterTurns: -3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      valueColor: indicatorColor,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ),
              Text(
                totalDistance.toStringAsFixed(2),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ElevatedButton getGameRoomActionButton(bool isUserGameFinished, bool isOpponentGameFinished, SpektrumUser user, String opponentId, int gameId) {
    if (isUserGameFinished && isOpponentGameFinished) {
      return ElevatedButton(
          onPressed: () {
            user.sendChallenge(opponentId);
            Navigator.of(context).pop();
          },
          child: Text('erneut herausfordern'));
    } else {
      return ElevatedButton(
          onPressed: () => onStartGame(gameId), child: Text('spielen'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: IconButton(
        icon: Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
      body: FutureBuilder(
        future: preGamePageInfo,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            PreGamePageInfo preGamePageInfo = snapshot.data;

            return Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          preGamePageInfo.user.profileImageId != null
                              ? IconButton(
                            icon: ClipRRect(
                              borderRadius: BorderRadius.circular(200.0),
                              child: Image.asset('assets/portrait_id/${preGamePageInfo.user.profileImageId}.jpg'),
                            ),
                            iconSize: 50,
                            onPressed: null,
                          )
                              : Icon(
                            Icons.person_pin,
                            size: 65,
                          ),
                          preGamePageInfo.user.userName != null
                              ? SizedBox(
                            width: 100.0,
                            child: Center(
                              child: Text(
                                preGamePageInfo.user.userName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                              : SizedBox(
                            width: 100.0,
                            child: Center(
                              child: Text(
                                preGamePageInfo.user.userId,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          getDistanceIndicator(preGamePageInfo.user.userId, preGamePageInfo.userGame.totalDistance),
                        ],
                      ),
                      Column(
                        children: [
                          preGamePageInfo.opponent.profileImageId != null
                              ? IconButton(
                            icon: ClipRRect(
                              borderRadius: BorderRadius.circular(200.0),
                              child: Image.asset('assets/portrait_id/${preGamePageInfo.opponent.profileImageId}.jpg'),
                            ),
                            iconSize: 50,
                            onPressed: null,
                          )
                              : Icon(
                            Icons.person_pin,
                            size: 65,
                          ),
                          preGamePageInfo.opponent.userName != null
                              ? SizedBox(
                            width: 100.0,
                            child: Center(
                              child: Text(
                                preGamePageInfo.opponent.userName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                              : SizedBox(
                            width: 100.0,
                            child: Center(
                              child: Text(
                                preGamePageInfo.opponent.userId,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          getDistanceIndicator(preGamePageInfo.opponent.userId, preGamePageInfo.opponentGame.totalDistance),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getGameRoomActionButton(
                      preGamePageInfo.userGame.isFinished,
                      preGamePageInfo.opponentGame.isFinished,
                      preGamePageInfo.user,
                      preGamePageInfo.opponent.userId,
                      preGamePageInfo.userGame.gameId
                    ),
                  ],
                ),
              ],
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
      )
    );
  }
}
