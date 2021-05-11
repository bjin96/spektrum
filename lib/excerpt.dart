import 'package:sqflite/sqflite.dart';

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

  Excerpt(
      {this.speakerFirstName,
      this.speakerLastName,
      this.party,
      this.content,
      this.speechId,
      this.fragment,
      this.socioCulturalCoordinate,
      this.socioEconomicCoordinate});

  static Future<List<Excerpt>> getRandomExcerptList() async {
    final Database db = await SpektrumDatabase.getDatabase();

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT speaker_party.first_name, speaker_party.last_name, speaker_party.party,
          speaker_party.socio_cultural_coordinate, speaker_party.socio_economic_coordinate, excerpt_speech.excerpt, 
          excerpt_speech.speech_id, excerpt_speech.fragment
        FROM (
          SELECT excerpt.excerpt, speech.speaker_id, excerpt.speech_id, excerpt.fragment
          FROM excerpt
          INNER JOIN speech ON excerpt.speech_id = speech.id
        ) as excerpt_speech
        INNER JOIN (
          SELECT speaker.id, speaker.first_name, speaker.last_name, speaker.party, party.socio_cultural_coordinate, 
            party.socio_economic_coordinate
          FROM speaker
          INNER JOIN party on speaker.party = party.name
        ) as speaker_party
        ON excerpt_speech.speaker_id = speaker_party.id
        ORDER BY RANDOM()
        LIMIT 3;
        ''');
    return List.generate(maps.length, (i) {
      return Excerpt(
        speakerFirstName: maps[i]['first_name'],
        speakerLastName: maps[i]['last_name'],
        party: maps[i]['party'],
        socioCulturalCoordinate: maps[i]['socio_cultural_coordinate'],
        socioEconomicCoordinate: maps[i]['socio_economic_coordinate'],
        content: maps[i]['excerpt'],
        speechId: maps[i]['speech_id'],
        fragment: maps[i]['fragment'],
      );
    });
  }
}
