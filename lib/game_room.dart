import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spektrum/contacts.dart';
import 'package:spektrum/game.dart';
import 'package:spektrum/result.dart';

import 'excerpt.dart';

class GameRoomPage extends StatefulWidget {
  GameRoomPage({Key key, this.opponent}) : super(key: key);

  final String opponent;

  @override
  _GameRoomPageState createState() => _GameRoomPageState(opponent);
}

class _GameRoomPageState extends State<GameRoomPage> {
  String opponent;
  Future<Map<String, double>> totalDistances;

  _GameRoomPageState(String opponent) {
    this.opponent = opponent;
    this.totalDistances = Result.fetchCurrentTotalDistance(opponent);
  }

  void onStartGame(String currentPlayer, String otherPlayer) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => GamePage(
                opponent: opponent,
              )),
    );
  }

  @override
  void initState() {
    super.initState();

    Timer.periodic(Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          totalDistances = Result.fetchCurrentTotalDistance(opponent);
        });
      }
    });
  }

  Padding getDistanceIndicator(String player) {
    return Padding(
      padding: EdgeInsets.only(
        top: 100,
      ),
      child: FutureBuilder(
        future: totalDistances,
        builder: (BuildContext context, AsyncSnapshot<Map<String, double>> snapshot) {
          if (snapshot.hasData) {
            double progressValue = snapshot.data[player] / 60; // 50 arbitrary, use 90 for perfect [0, 1] interval.
            Animation<Color> indicatorColor = AlwaysStoppedAnimation<Color>(Colors.black);
            if (progressValue == 0.0) {
              progressValue = 0.01;
            }
            indicatorColor = AlwaysStoppedAnimation<Color>(Color.lerp(Colors.green, Colors.red, progressValue));
            return Column(
              children: [
                SizedBox(
                  height: 400,
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
                    )
                  ),
                ),
                Text(
                  snapshot.data[player].toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                SizedBox(
                  height: 400,
                  width: 10,
                ),
                Text(
                  0.0.toStringAsFixed(2),
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Future<ElevatedButton> getGameRoomActionButton() async {
    int gameId = await Excerpt.getGameId(FirebaseAuth.instance.currentUser.email, opponent);
    bool isGameFinished = await Result.fetchGameFinished(gameId);

    SpektrumUser user = await SpektrumUser.getUserById(FirebaseAuth.instance.currentUser.email);
    if (isGameFinished) {
      return ElevatedButton(
          onPressed: () {
            user.sendChallenge(opponent);
            Navigator.of(context).pop();
          },
          child: Text('erneut herausfordern')
      );
    } else {
      return ElevatedButton(
          onPressed: () => onStartGame(FirebaseAuth.instance.currentUser.email, opponent),
          child: Text('spielen')
      );
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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Icon(
                      Icons.person,
                      size: 50,
                    ),
                    Text(FirebaseAuth.instance.currentUser.email),
                    getDistanceIndicator(FirebaseAuth.instance.currentUser.email),
                  ],
                ),
                Column(
                  children: [
                    Icon(
                      Icons.person,
                      size: 50,
                    ),
                    Text(opponent),
                    getDistanceIndicator(opponent),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FutureBuilder(
                future: getGameRoomActionButton(),
                builder: (BuildContext context, AsyncSnapshot<ElevatedButton> snapshot) {
                  if (snapshot.hasData) {
                    return snapshot.data;
                  } else {
                    return ElevatedButton(onPressed: null, child: Text('lädt...'));
                  }
                }
              ),
            ],
          ),
        ],
      ),
    );
  }
}
