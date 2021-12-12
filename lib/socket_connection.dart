import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;

class SocketConnection {

  static Socket _instance;

  static Future<Socket> instance() async {
    if (_instance == null) {
      final String idToken = await FirebaseAuth.instance.currentUser.getIdToken();
      final String yamlString = await rootBundle.loadString('assets/config.yaml');
      final dynamic yamlMap = loadYaml(yamlString);
      final String apiHost = yamlMap['api_host'];
      final int apiPort = yamlMap['api_port'];
      _instance = io('$apiHost:$apiPort',
          OptionBuilder()
              .setTransports(['websocket'])
              .setAuth({'auth': {'token': idToken}})
              .build()
      );
    }
    return _instance;
  }

  static Future<dynamic> send(String endpoint, Map<String, dynamic> parameters) async {
    Completer completer = new Completer();
    Socket socket = await SocketConnection.instance();

    socket.emitWithAck(endpoint, parameters, ack: (Map<String, dynamic> response) {
      completer.complete(response);
    });
    return completer.future;
  }

  static void registerEventHandler(String event, Function eventHandler) async {
    Socket socket = await SocketConnection.instance();
    socket.on(event, eventHandler);
  }

  static void clearAllHandlers() async {
    Socket socket = await SocketConnection.instance();
    socket.clearListeners();
  }

  static void clearHandler(String event, Function handler) async {
    Socket socket = await SocketConnection.instance();
    socket.off(event, handler);
  }
}