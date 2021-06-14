import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spektrum/game.dart';


class GameRoomPage extends StatefulWidget {
  GameRoomPage({Key key, this.opponent}) : super(key: key);

  final String opponent;

  @override
  _GameRoomPageState createState() => _GameRoomPageState(opponent);
}

class _GameRoomPageState extends State<GameRoomPage> {
  final String opponent;

  _GameRoomPageState(this.opponent);

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Icon(Icons.person),
                  Text(FirebaseAuth.instance.currentUser.email),
                ],
              ),
              Column(
                children: [
                  Icon(Icons.person),
                  Text(opponent),
                ],
              ),
            ],
          ),
          ElevatedButton(
              onPressed: () => onStartGame(FirebaseAuth.instance.currentUser.email, opponent), child: Text('Spielen')),
        ],
      ),
    );
  }
}
