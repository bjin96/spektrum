import 'dart:async';

import 'package:flutter/material.dart';
import 'package:spektrum/game.dart';
import 'package:spektrum/socket_connection.dart';

import 'model/game.dart';
import 'model/spektrum_user.dart';

class GameRoomPage extends StatefulWidget {
  GameRoomPage({Key key, this.user, this.opponent, this.userGameId}) : super(key: key);

  final SpektrumUser user;
  final String opponent;
  final int userGameId;

  @override
  _GameRoomPageState createState() => _GameRoomPageState(user: user, opponentId: opponent, userGameId: userGameId);
}

class _GameRoomPageState extends State<GameRoomPage> {

  Future dataLoaded;

  SpektrumUser user;
  int userGameId;
  String opponentId;
  SpektrumUser opponent;
  Game userGame;
  Game opponentGame;


  _GameRoomPageState({this.user, this.opponentId, this.userGameId});

  @override
  void initState() {
    super.initState();

    this.dataLoaded = setPreGameData();

    SocketConnection.registerEventHandler('result_stored', handleResultStored);
    SocketConnection.registerEventHandler('both_finished_game', handleBothFinishedGame);
    SocketConnection.registerEventHandler('own_result_stored', handleOwnResultStored);
  }

  @override
  void dispose() {
    super.dispose();

    SocketConnection.clearHandler('result_stored', handleResultStored);
    SocketConnection.clearHandler('both_finished_game', handleBothFinishedGame);
    SocketConnection.clearHandler('own_result_stored', handleOwnResultStored);
  }

  Future setPreGameData() async {
    Map<String, dynamic> json;
    if (this.userGameId != null) {
      final Map<String, dynamic> body = {'gameId': this.userGameId};
      json = await SocketConnection.send('view_history_game_page', body);
    } else {
      final Map<String, dynamic> body = {'opponentId': this.opponentId};
      json = await SocketConnection.send('view_pre_game_page', body);
    }

    this.opponent = SpektrumUser.fromJson(json['opponent']);
    this.userGame = Game.fromJson(json['userGame']);
    this.opponentGame = Game.fromJson(json['opponentGame']);
  }

  void handleResultStored(dynamic json)  {
    if (this.opponent.userId == json['userId']) {
      this.setState(() {
        this.opponentGame.totalDistance += json['distance'];
      });
    }
  }

  void handleOwnResultStored(dynamic json)  {
    if (this.opponent.userId == json['targetUserId']) {
      this.setState(() {
        this.userGame.totalDistance += json['distance'];
      });
    }
  }

  void handleBothFinishedGame(dynamic json) {
    if (this.opponent.userId == json['userId']) {
      this.setState(() {
        this.userGame.isFinished = true;
        this.opponentGame.isFinished = true;
      });
    }
  }

  void onStartGame(int gameId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GamePage(
                gameId: gameId
              ),
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

  ElevatedButton getGameRoomActionButton() {
    if (this.userGameId != null) {
      return ElevatedButton(
          onPressed: () => onStartGame(userGame.gameId), child: Text('ergebnis anzeigen'));
    } else if (userGame.isFinished && opponentGame.isFinished) {
      return ElevatedButton(
          onPressed: () {
            user.sendChallenge(opponentId);
            Navigator.of(context).pop();
          },
          child: Text('erneut herausfordern'));
    } else {
      return ElevatedButton(
          onPressed: () => onStartGame(userGame.gameId), child: Text('spielen'));
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
        future: dataLoaded,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
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
                          user.profileImageId != null
                              ? IconButton(
                            icon: ClipRRect(
                              borderRadius: BorderRadius.circular(200.0),
                              child: Image.asset('assets/portrait_id/${user.profileImageId}.jpg'),
                            ),
                            iconSize: 50,
                            onPressed: null,
                          )
                              : Icon(
                            Icons.person_pin,
                            size: 65,
                          ),
                          user.userName != null
                              ? SizedBox(
                            width: 100.0,
                            child: Center(
                              child: Text(
                                user.userName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                              : SizedBox(
                            width: 100.0,
                            child: Center(
                              child: Text(
                                user.userId,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          getDistanceIndicator(user.userId, userGame.totalDistance),
                        ],
                      ),
                      Column(
                        children: [
                          opponent.profileImageId != null
                              ? IconButton(
                            icon: ClipRRect(
                              borderRadius: BorderRadius.circular(200.0),
                              child: Image.asset('assets/portrait_id/${opponent.profileImageId}.jpg'),
                            ),
                            iconSize: 50,
                            onPressed: null,
                          )
                              : Icon(
                            Icons.person_pin,
                            size: 65,
                          ),
                          opponent.userName != null
                              ? SizedBox(
                            width: 100.0,
                            child: Center(
                              child: Text(
                                opponent.userName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                              : SizedBox(
                            width: 100.0,
                            child: Center(
                              child: Text(
                                opponent.userId,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          getDistanceIndicator(opponent.userId, opponentGame.totalDistance),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    getGameRoomActionButton(),
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
