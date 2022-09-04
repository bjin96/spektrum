import 'package:flutter/widgets.dart';

import '../socket_connection.dart';

class PoliticianImage {

  static const String SOCKET_NAMESPACE = 'image_';

  static Future<Map<String, dynamic>> getPoliticianImageAndCopyright(String speakerId) async {
    final Map<String, dynamic> body = { 'speakerId': speakerId };
    Map<String, dynamic> imageJson = await SocketConnection.send(SOCKET_NAMESPACE + 'politician', body);
    Map<String, dynamic> copyrightJson = await SocketConnection.send(SOCKET_NAMESPACE + 'copyright', body);
    return {
      'copyright': '© ' + copyrightJson['copyright'],
      'image': Image.memory(imageJson['image']),
    };
  }
}