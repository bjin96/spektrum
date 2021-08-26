import 'package:postgres/postgres.dart';

import 'database.dart';

class Speaker {

  static Future<List<String>> fetchAllSpeakerIds() async {
    final PostgreSQLConnection connection = SpektrumDatabase.getDatabaseConnection();
    await connection.open();
    final List<Map<String, dynamic>> maps = await connection.mappedResultsQuery('''
        SELECT DISTINCT id
        FROM speaker
    ''');
    connection.close();
    return List.generate(maps.length, (i) {
      return maps[i]['speaker']['id'];
    });
  }
}
