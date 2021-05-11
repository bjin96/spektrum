import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:spektrum/authentication.dart';
import 'package:sqflite/sqflite.dart';

import 'database.dart';
import 'game.dart';

class ResultPage extends StatelessWidget {
  final int gameId;

  const ResultPage({this.gameId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ergebnis"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FutureBuilder(
              future: Result.fetchResultsByGameId(gameId),
              builder: (BuildContext context, AsyncSnapshot<List<Result>> snapshot) {
                if (snapshot.hasData) {
                  double totalDistance = 0;
                  for (Result result in snapshot.data) {
                    totalDistance += result.distance;
                  }
                  return Text(
                      'Du warst ${totalDistance.toStringAsFixed(2)} von den korrekten Parteien entfernt.');
                } else {
                  return SizedBox(
                    child: CircularProgressIndicator(),
                    width: 60,
                    height: 60,
                  );
                }
              },
            ),
            ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => GamePage(title: 'Spektrum')),
                  );
                },
                child: Text('Nochmal spielen')
            ),
            ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AuthenticationPage()),
                  );
                },
                child: Text('Abmelden')
            ),
          ],
        ),
      ),
    );
  }
}

class Result {
  int gameId;
  int userId;
  String speechId;
  int fragment;
  int socioCulturalCoordinate;
  int socioEconomicCoordinate;
  double distance;

  Result(
      {this.gameId,
      this.userId,
      this.speechId,
      this.fragment,
      this.socioCulturalCoordinate,
      this.socioEconomicCoordinate,
      this.distance});

  static Future<List<Result>> fetchResultsByGameId(int gameId) async {
    final Database db = await SpektrumDatabase.getDatabase();

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT game_id, user_id, speech_id, fragment, socio_cultural_coordinate, socio_economic_coordinate, distance
      FROM result
      WHERE game_id = ?;
      ''', [gameId]);
    return List.generate(maps.length, (i) {
      return Result(
        gameId: maps[i]['game_id'],
        userId: maps[i]['user_id'],
        speechId: maps[i]['speech_id'],
        fragment: maps[i]['fragment'],
        socioCulturalCoordinate: maps[i]['socio_cultural_coordinate'],
        socioEconomicCoordinate: maps[i]['socio_economic_coordinate'],
        distance: maps[i]['distance'],
      );
    });
  }

  static Future<int> getNewGameId() async {
    final Database db = await SpektrumDatabase.getDatabase();

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT max(game_id)
      FROM result;
      ''');
    return (maps[0]['max(game_id)'] ?? 0) + 1;
  }

  void store() async {
    final Database db = await SpektrumDatabase.getDatabase();

    await db.rawQuery('''
      INSERT INTO result
      VALUES (?, ?, ?, ?, ?, ?, ?);
      ''', [gameId, userId, speechId, fragment, socioCulturalCoordinate, socioEconomicCoordinate, distance]);
  }
}
