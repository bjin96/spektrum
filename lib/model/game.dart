import '../api_connection.dart';

class Game {
  int gameId;
  double totalDistance;
  bool isFinished;

  Game(
      {this.gameId,
        this.totalDistance,
        this.isFinished});

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
        gameId: json['gameId'],
        totalDistance: json['totalDistance'],
        isFinished: json['isFinished']
    );
  }

  static void setFinished(gameId) async {
    final Map<String, dynamic> body = {
      'gameId': gameId
    };
    await ApiConnection.post('/result/setGameFinished', body);
  }
}