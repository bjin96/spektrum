import '../api_connection.dart';

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

  void store() async {
    final Map<String, dynamic> body = {
      'gameId': gameId,
      'excerptCounter': excerptCounter,
      'userId': userId,
      'socioCulturalCoordinate': socioCulturalCoordinate,
      'socioEconomicCoordinate': socioEconomicCoordinate,
      'distance': distance,
    };
    await ApiConnection.post('/result/store', body);
  }
}
