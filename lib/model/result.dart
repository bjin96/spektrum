import '../socket_connection.dart';

class Result {

  static const String SOCKET_NAMESPACE = 'result_';

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
    await SocketConnection.send(SOCKET_NAMESPACE + 'store', body);
  }
}
