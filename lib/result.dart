import 'package:firebase_auth/firebase_auth.dart';

import 'api_connection.dart';
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
    final Map<String, dynamic> body = {
      'currentUser': FirebaseAuth.instance.currentUser.email,
      'opponent': opponent,
    };
    await ApiConnection.post('/result/setGameFinished', body);
  }

  static Future<bool> fetchGameFinished(int gameId) async {
    final Map<String, dynamic> json = await ApiConnection.get('/game/fetchGameFinished/$gameId');
    return json['is_game_finished'];
  }

  static Future<List<Result>> fetchResultsByGameId(int gameId) async {
    final Map<String, dynamic> json = await ApiConnection.get('/result/fetchResultsByGameId/$gameId');
    return List.generate(json['resultList'].length, (i) {
      return Result(
        gameId: json['resultList'][i]['gameId'],
        excerptCounter: json['resultList'][i]['excerptCounter'],
        userId: json['resultList'][i]['userId'],
        socioCulturalCoordinate: json['resultList'][i]['socioCulturalCoordinate'],
        socioEconomicCoordinate: json['resultList'][i]['socioEconomicCoordinate'],
        distance: json['resultList'][i]['distance'],
      );
    });
  }

  void store() async {
    final Map<String, dynamic> body = {
      'gameId': gameId,
      'excerptCounter': excerptCounter,
      'userId': userId,
      'socioCulturalCoordinate': socioCulturalCoordinate,
      'socioEconomicCoordinate': socioEconomicCoordinate,
      'distance': distance,
    };
    await ApiConnection.post('/game/getGameId', body);
  }
}
