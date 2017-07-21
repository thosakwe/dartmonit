import 'dart:async';
import 'package:collection/equality.dart';
import 'dart:convert';
import 'package:angel_framework/angel_framework.dart';
import 'package:http/http.dart' as http;
import 'manager.dart';

class DartmonClient {
  http.Client _client;
  final String baseUrl;

  DartmonClient(this.baseUrl) {
    _client = new http.Client();
  }

  void close() => _client.close();

  Future<ChildProcessInfo> run(String absolute) async {
    var response = await _client.post('$baseUrl/api/spawn',
        headers: {
          'accept': 'application/json',
          'content-type': 'application/json'
        },
        body: JSON.encode({'path': absolute}));

    if (response.statusCode != 200)
      throw new AngelHttpException.fromJson(response.body);
    else if (response.headers['content-type']?.contains('application/json') !=
        true)
      throw 'dartmonit server did not respond with JSON';
    else
      return new ChildProcessInfo.fromJson(JSON.decode(response.body));
  }

  Future<ChildProcessInfo> fetch(String name) async {
    var response = await _client.get('$baseUrl/api/processes/$name',
        headers: {'accept': 'application/json'});

    if (response.statusCode != 200)
      throw new AngelHttpException.fromJson(response.body);
    else if (response.headers['content-type']?.contains('application/json') !=
        true)
      throw 'dartmonit server did not respond with JSON';
    else
      return new ChildProcessInfo.fromJson(JSON.decode(response.body));
  }

  Future<ChildProcessInfo> kill(String name) async {
    var response = await _client.delete('$baseUrl/api/processes/$name',
        headers: {'accept': 'application/json'});

    if (response.statusCode != 200)
      throw new AngelHttpException.fromJson(response.body);
    else if (response.headers['content-type']?.contains('application/json') !=
        true)
      throw 'dartmonit server did not respond with JSON';
    else
      return new ChildProcessInfo.fromJson(JSON.decode(response.body));
  }

  Future<List<ChildProcessInfo>> fetchAll() async {
    var response = await _client.get('$baseUrl/api/processes',
        headers: {'content-type': 'application/json'});

    if (response.statusCode != 200)
      throw new AngelHttpException.fromJson(response.body);
    else if (response.headers['content-type']?.contains('application/json') !=
        true)
      throw 'dartmonit server did not respond with JSON';
    else
      return JSON
          .decode(response.body)
          .map((c) => new ChildProcessInfo.fromJson(c));
  }

  Future stop() async {
    var response = await _client
        .post('$baseUrl/api/stop', headers: {'accept': 'application/json'});

    if (response.statusCode != 200)
      throw new AngelHttpException.fromJson(response.body);
    else if (response.headers['content-type']?.contains('application/json') !=
        true)
      throw 'dartmonit server did not respond with JSON';
    else {
      var body = JSON.decode(response.body);

      if (!const MapEquality().equals(body, {'ok': true})) {
        throw 'dartmonit server did not accept our shutdown request';
      }
    }
  }
}
