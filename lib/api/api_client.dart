import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class ApiClient {
  static const String _baseUrl = kReleaseMode
      ? 'https://us-central1-betterhealth-f9c79.cloudfunctions.net/api'
      : 'http://localhost:5001/betterhealth-f9c79/us-central1/api/';

  static final ApiClient _instance = ApiClient._internal();
  final Logger _logger = Logger('ApiClient');

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    _logger.fine('Creating a new instance of ApiClient');
    _client = http.Client();
  }

  late http.Client _client;

  void addAuthHeader(String token) {
    _logger.fine('Adding authorization header');
    _client = http.Client();
    _client.get(Uri.parse(_baseUrl),
        headers: {'Authorization': 'Bearer $token'}).then((response) {
      _logger.finest('Authorization header added successfully');
      // Handle response
      _logger.finest(response.body);
    });
  }

  void removeAuthHeader() {
    _logger.fine('Removing authorization header');
    _client.close();
  }

  Future<dynamic> post(String path, dynamic body,
      {required Map<String, String> data}) async {
    _logger.fine('Sending POST request to $_baseUrl$path');
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final result = jsonDecode(response.body);
      _logger.finest('Received response: $result');
      return result;
    } else {
      _logger.warning('Request failed with status code ${response.statusCode}');
      throw Exception(response.reasonPhrase);
    }
  }

  Future<dynamic> get(String path) async {
    _logger.fine('Sending GET request to $_baseUrl$path');
    final response = await _client.get(Uri.parse('$_baseUrl$path'));

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      _logger.finest('Received response: $result');
      return result;
    } else {
      _logger.warning('Request failed with status code ${response.statusCode}');
      throw Exception(response.reasonPhrase);
    }
  }

  static Future<void> postHospital(Map<String, dynamic> hospital) async {
    const path = 'getReviews';
    var client = http.Client();
    final url = Uri.parse('$_baseUrl$path');
    final data = jsonEncode({"hospital": hospital});
    // ignore: unnecessary_cast
    try {
      print("my url is: $url");

      final response = await client.get(
          Uri.parse(
              'http://localhost:5001/betterhealth-f9c79/us-central1/api/getReviews'),
          headers: {
            'Access-Control-Allow-Origin':
                '*', // Replace * with your desired origin domain
            'Access-Control-Allow-Methods':
                'POST, GET, OPTIONS', // List of allowed HTTP methods
            'Access-Control-Allow-Headers':
                'Origin, Content-Type' // List of allowed headers
          });

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
    } catch (e) {
      print('Error: $e');
    }

    // try {
    //   final response = await http.post(
    //     url,
    //     headers: <String, String>{
    //       'Content-Type': 'application/json; charset=UTF-8',
    //     },
    //     body: jsonEncode({"hospital": hospital}),
    //   );
    //   print(response);
    //   if (response.statusCode >= 200) {
    //     // TODO pass the response to the ml model endpoint
    //     // final resData = '';
    //     print("success has happened $response");
    //   } else {
    //     throw Exception('request was unsuccessful: ${response.statusCode}');
    //   }
    // } catch (e) {
    //   print(e);
    // }
  }
}
