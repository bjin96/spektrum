import 'package:postgres/postgres.dart';

import 'database.dart';

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
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> maps = await connection.mappedResultsQuery('''
        SELECT speech_id, fragment
        FROM excerpt
        ORDER BY RANDOM()
        LIMIT 3;
        ''');
    connection.close();
    return List.generate(maps.length, (i) {
      return {'speechId': maps[i]['excerpt']['speech_id'], 'fragment': maps[i]['excerpt']['fragment']};
    });
  }

  static Future<List<Excerpt>> getExcerptListForGame(int gameId) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> maps = await connection.mappedResultsQuery('''
        SELECT DISTINCT excerpt_information.id, excerpt_information.first_name, excerpt_information.last_name,
            excerpt_information.party, excerpt_information.socio_cultural_coordinate,
            excerpt_information.socio_economic_coordinate, excerpt_information.excerpt, excerpt_information.speech_id,
            excerpt_information.fragment, excerpt_information.topic, game_excerpt.counter, excerpt_information.bio
        FROM (
          SELECT speaker_party.id, speaker_party.first_name, speaker_party.last_name, speaker_party.party, speaker_party.bio,
            speaker_party.socio_cultural_coordinate, speaker_party.socio_economic_coordinate, excerpt_speech.excerpt, 
            excerpt_speech.speech_id, excerpt_speech.fragment, excerpt_speech.topic
          FROM (
            SELECT excerpt.excerpt, speech.speaker_id, excerpt.speech_id, excerpt.fragment, excerpt.topic
            FROM excerpt
            INNER JOIN speech ON excerpt.speech_id = speech.id
          ) as excerpt_speech
          INNER JOIN (
            SELECT speaker.id, speaker.first_name, speaker.last_name, speaker.party, speaker.bio, party.socio_cultural_coordinate, 
              party.socio_economic_coordinate
            FROM speaker
            INNER JOIN party on speaker.party = party.name
          ) as speaker_party
          ON excerpt_speech.speaker_id = speaker_party.id
        ) as excerpt_information
        INNER JOIN game_excerpt
        ON excerpt_information.speech_id = game_excerpt.speech_id
        AND excerpt_information.fragment = game_excerpt.fragment
        WHERE game_excerpt.speech_id IN (
          SELECT speech_id
          FROM game_excerpt
          WHERE game_id = @gameId
        )
        AND game_excerpt.fragment IN (
          SELECT fragment
          FROM game_excerpt
          WHERE game_id = @gameId
        )
        ''', substitutionValues: {'gameId': gameId});
    connection.close();
    List<Excerpt> excerptList = List.generate(maps.length, (i) {
      return Excerpt(
        speakerFirstName: maps[i]['speaker']['first_name'],
        speakerLastName: maps[i]['speaker']['last_name'],
        party: maps[i]['speaker']['party'],
        socioCulturalCoordinate: maps[i]['party']['socio_cultural_coordinate'],
        socioEconomicCoordinate: maps[i]['party']['socio_economic_coordinate'],
        content: maps[i]['excerpt']['excerpt'],
        speechId: maps[i]['excerpt']['speech_id'],
        fragment: maps[i]['excerpt']['fragment'],
        counter: maps[i]['game_excerpt']['counter'],
        topic: maps[i]['excerpt']['topic'],
        bio: maps[i]['speaker']['bio'],
        speakerId: maps[i]['speaker']['id']
      );
    });
    excerptList.sort((a, b) => a.counter.compareTo(b.counter));
    return excerptList;
  }

  static Future<int> getGameId(String loggedInPlayer, String otherPlayer) async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> maps = await connection.mappedResultsQuery('''
        SELECT id
        FROM game
        WHERE logged_in_player = @loggedInPlayer
        AND other_player = @otherPlayer
        AND game_created = (
          SELECT MAX(game_created)
          FROM game
          WHERE logged_in_player = @loggedInPlayer
          AND other_player = @otherPlayer 
        )
        ''', substitutionValues: {'loggedInPlayer': loggedInPlayer, 'otherPlayer': otherPlayer});
    connection.close();
    return maps[0]['game']['id'];
  }
}
