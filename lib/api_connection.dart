import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;

class ApiConnection {

  static String apiHost;
  static int apiPort;

  static Future<Uri> _buildUri(String endpoint) async {
    if (ApiConnection.apiHost == null || ApiConnection.apiPort == null) {
      final String yamlString = await rootBundle.loadString('assets/config.yaml');
      final dynamic yamlMap = loadYaml(yamlString);
      ApiConnection.apiHost = yamlMap['api_host'];
      ApiConnection.apiPort = yamlMap['api_port'];
    }
    return Uri.parse('${ApiConnection.apiHost}:${ApiConnection.apiPort}$endpoint');
  }

  static Future<Map<String, dynamic>> get(final String endpoint) async {
    final Uri uri = await _buildUri(endpoint);
    final String idToken = await FirebaseAuth.instance.currentUser.getIdToken();
    final Map<String, String> headers = { 'Authorization': 'Bearer $idToken' };
    final http.Response response = await http.get(uri, headers: headers);
    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return json;
    } else {
      throw Exception('Failed GET request with status code $response.statusCode');
    }
  }

  static Future<Map<String, dynamic>> post(final String endpoint, Map<String, dynamic> body) async {
    final Uri uri = await _buildUri(endpoint);
    final String idToken = await FirebaseAuth.instance.currentUser.getIdToken();
    final Map<String, String> headers = {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json'
    };
    final http.Response response = await http.post(uri, headers: headers, body: jsonEncode(body));
    final Map<String, dynamic> json = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return json;
    } else {
      throw Exception('Failed POST request with status code $response.statusCode');
    }
  }
}