import 'package:firebase_auth/firebase_auth.dart';
import 'package:postgres/postgres.dart';

import 'database.dart';
import 'excerpt.dart';

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

  static Future<Map<String, double>> fetchCurrentTotalDistance(String opponent) async {
    int currentUserGameId = await Excerpt.getGameId(FirebaseAuth.instance.currentUser.email, opponent);
    int opponentGameId = await Excerpt.getGameId(opponent, FirebaseAuth.instance.currentUser.email);

    List<Result> currentUserResultList = await fetchResultsByGameId(currentUserGameId);
    List<Result> opponentResultList = await fetchResultsByGameId(opponentGameId);

    double currentUserDistance = 0.0;
    for (Result result in currentUserResultList) {
      currentUserDistance += result.distance;
    }

    double opponentDistance = 0.0;
    for (Result result in opponentResultList) {
      opponentDistance += result.distance;
    }

    return {FirebaseAuth.instance.currentUser.email: currentUserDistance, opponent: opponentDistance};
  }

  static void setGameFinished(String opponent) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    await connection.query('''
      UPDATE game
      SET finished = true
      WHERE logged_in_player = @currentUser AND other_player = @opponent
        OR logged_in_player = @opponent AND other_player = @currentUser
      ''', substitutionValues: {'currentUser': FirebaseAuth.instance.currentUser.email, 'opponent': opponent});
    connection.close();
  }

  static Future<bool> fetchGameFinished(int gameId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> maps = await connection.mappedResultsQuery('''
      SELECT finished
      FROM game
      WHERE id = @gameId;
      ''', substitutionValues: {'gameId': gameId});
    connection.close();
    return maps[0]['game']['finished'];
  }

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
