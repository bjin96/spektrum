import 'api_connection.dart';

class Excerpt {
  String speakerFirstName;
  String speakerLastName;
  String party;
  String content;
  String speechId;
  int fragment;
  int socioCulturalCoordinate;
  int socioEconomicCoordinate;
  int counter;
  String topic;
  String bio;
  String speakerId;

  Excerpt(
      {this.speakerFirstName,
      this.speakerLastName,
      this.party,
      this.content,
      this.speechId,
      this.fragment,
      this.socioCulturalCoordinate,
      this.socioEconomicCoordinate,
      this.counter,
      this.topic,
      this.bio,
      this.speakerId});

  static Future<List<Map<String, dynamic>>> getRandomExcerptIdList() async {
    final Map<String, dynamic> json = await ApiConnection.get('/excerpt/getRandomExcerptIdList');
    return json['excerptIdList'];
  }

  static Future<List<Excerpt>> getExcerptListForGame(int gameId) async {
    final Map<String, dynamic> json = await ApiConnection.get('/excerpt/getExcerptListForGame/$gameId');
    final List<dynamic> responseExcerptList = json['excerptList'];
    return List.generate(responseExcerptList.length, (i) {
      return Excerpt(
          speakerFirstName: responseExcerptList[i]['speakerFirstName'],
          speakerLastName: responseExcerptList[i]['speakerLastName'],
          party: responseExcerptList[i]['party'],
          socioCulturalCoordinate: responseExcerptList[i]['socioCulturalCoordinate'],
          socioEconomicCoordinate: responseExcerptList[i]['socioEconomicCoordinate'],
          content: responseExcerptList[i]['content'],
          speechId: responseExcerptList[i]['speechid'],
          fragment: responseExcerptList[i]['fragment'],
          counter: responseExcerptList[i]['counter'],
          topic: responseExcerptList[i]['topic'],
          bio: responseExcerptList[i]['bio'],
          speakerId: responseExcerptList[i]['speakerId']);
    });
  }

  static Future<int> getGameId(String loggedInPlayer, String otherPlayer) async {
    final Map<String, dynamic> body = {'loggedInPlayer': loggedInPlayer, 'otherPlayer': otherPlayer};
    final Map<String, dynamic> json = await ApiConnection.post('/game/getGameId', body);
    return json['gameId'];
  }

  void report() async {
    final Map<String, dynamic> body = {'speechId': speechId, 'fragment': fragment};
    await ApiConnection.post('/excerpt/report', body);
  }
}
