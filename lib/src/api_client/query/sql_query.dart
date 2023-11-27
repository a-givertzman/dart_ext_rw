import 'dart:convert';

import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:uuid/uuid.dart';

class SqlQuery implements ApiQueryType {
  final String _authToken;
  late String _id;
  final String _database;
  final String _sql;
  final bool _keepAlive;
  final bool _debug;
  ///
  /// Prapares sql for some database
  SqlQuery({
    required String authToken,
    required String database,
    required String sql,
    bool keepAlive = false,
    bool debug = false,
  }) :
    _authToken = authToken,
    _database = database,
    _sql = sql,
    _keepAlive = keepAlive,
    _debug = debug;
  ///
  @override
  bool valid() {
    return true;
    /// some simplest sql syntax validation to be implemented
  }
  ///
  @override
  String buildJson() {
    _id = const Uuid().v1();
    final jsonString = json.encode({
      'authToken': _authToken,
      'id': _id,
      'keepAlive': _keepAlive,
      'debug': _debug,
      'sql': {
        'database': _database,
        'sql': _sql,
      },
    });
    return jsonString;
  }
  ///
  @override
  String get authToken => _authToken;
  ///
  @override
  String get id => _id;
  ///
  String get database => _database;
}