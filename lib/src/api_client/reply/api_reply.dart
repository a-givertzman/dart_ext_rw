import 'dart:convert';

import 'package:ext_rw/src/api_client/reply/api_error.dart';
import 'package:logging/logging.dart';

class ApiReply {
  final _log = Logger('ApiReply');
  late final String _authToken;
  late final String _id;
  late final String _query;
  late final List<Map<String, dynamic>> _data;
  late final ApiError _error;
  ///
  ApiReply({
    required String authToken,
    required String id,
    required String query,
    required List<Map<String, dynamic>> data,
    required ApiError errors,
  }) : 
    _authToken = authToken,
    _id = id,
    _query = query, 
    _data = data, 
    _error = errors;
  ///
  ApiReply.fromJson(String jsonString) {
    // _log.fine('.fromJson | jsonString: $jsonString');
    final jsonMap = json.decode(jsonString);
    _log.fine('.fromJson | jsonMap: $jsonMap');
    _authToken = jsonMap['authToken'];
    _id = jsonMap['id'];
    _query = jsonMap['query'] ?? {};
    _data = (jsonMap['data'] as List<dynamic>).map((e) {
      return (e as Map<dynamic, dynamic>).map((key, value) => MapEntry(key.toString(), value));
    }).toList();
    _error = ApiError(errors: jsonMap['error']);
  }
  ///
  String get authToken => _authToken;
  ///
  String get id => _id;
  ///
  String get sql => _query;
  ///
  List<Map<String, dynamic>> get data => _data;
  ///
  ApiError get error => _error;
  ///
  bool get hasError => _error.isNotEmpty;
  ///
  @override
  String toString() {
    return '''$ApiReply {
\t\tauthToken: $_authToken;
\t\tid: $_id;
\t\tquery: $_query;
\t\tdata: $_data;
\t\terror: $_error;
\t}''';
  }
}
