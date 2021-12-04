import 'api_connection.dart';

class Speaker {

  static Future<List<String>> fetchAllSpeakerIds() async {
    final Map<String, dynamic> json = await ApiConnection.get('/speaker/fetchAllSpeakerIds');
    return json['speakerList'];
  }
}
