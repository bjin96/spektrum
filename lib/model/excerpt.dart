import '../api_connection.dart';

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

  void report() async {
    final Map<String, dynamic> body = {'speechId': speechId, 'fragment': fragment};
    await ApiConnection.post('/excerpt/report', body);
  }
}
