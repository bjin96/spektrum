import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:spektrum/authentication.dart';

import 'contacts.dart';
import 'database.dart';

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
                  return Text('Du warst ${totalDistance.toStringAsFixed(2)} von den korrekten Parteien entfernt.');
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
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ContactPage()),
                  );
                },
                child: Text('Kontakte')),
            ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => AuthenticationPage()),
                  );
                },
                child: Text('Abmelden')),
          ],
        ),
      ),
    );
  }
}

class Result {
  int gameId;
  int excerptCounter;
  String userId;
  int socioCulturalCoordinate;
  int socioEconomicCoordinate;
  double distance;

  Result(
      {this.gameId,
      this.excerptCounter,
      this.userId,
      this.socioCulturalCoordinate,
      this.socioEconomicCoordinate,
      this.distance});

  static Future<List<Result>> fetchResultsByGameId(int gameId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> maps = await connection.mappedResultsQuery('''
      SELECT game_id, user_id, socio_cultural_coordinate, socio_economic_coordinate, distance
      FROM result
      WHERE game_id = @gameId;
      ''', substitutionValues: {'gameId': gameId});
    connection.close();
    return List.generate(maps.length, (i) {
      return Result(
        gameId: maps[i]['result']['game_id'],
        excerptCounter: maps[i]['result']['excerpt_counter'],
        userId: maps[i]['result']['user_id'],
        socioCulturalCoordinate: maps[i]['result']['socio_cultural_coordinate'],
        socioEconomicCoordinate: maps[i]['result']['socio_economic_coordinate'],
        distance: maps[i]['result']['distance'],
      );
    });
  }

  void store() async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.query('''
        INSERT INTO result (
          game_id, excerpt_counter, user_id, socio_cultural_coordinate, socio_economic_coordinate, distance
        )
        VALUES (@gameId, @excerptCounter, @userId, @socioCulturalCoordinate, @socioEconomicCoordinate, @distance);
        ''', substitutionValues: {
      'gameId': gameId,
      'excerptCounter': excerptCounter,
      'userId': userId,
      'socioCulturalCoordinate': socioCulturalCoordinate,
      'socioEconomicCoordinate': socioEconomicCoordinate,
      'distance': distance,
    });
    connection.close();
  }
}
