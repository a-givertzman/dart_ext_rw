import 'dart:convert';

import 'package:dart_api_client/src/core/api_query_type/api_query_type.dart';
import 'package:uuid/uuid.dart';

class ExecutableQuery implements ApiQueryType {
  final String _authToken;
  late String _id;
  final String _script;
  final Map<String, dynamic> _params;
  final bool _keepAlive;
  final bool _debug;
  ///
  /// Prapares query for some executable
  ExecutableQuery({
    required String authToken,
    required String script,
    required Map<String, dynamic> params,
    bool keepAlive = false,
    bool debug = false,
  }) :
    _authToken = authToken,
    _script = script,
    _params = params,
    _keepAlive = keepAlive,
    _debug = debug;
  ///
  @override
  bool valid() {
    return true;
    /// TODO some simplest validation to be implemented
  }
  ///
  @override
  String buildJson() {
    _id = const Uuid().v1();
    final jsonString = json.encode({
      'auth_token': _authToken,
      'id': _id,
      'keep-alive': _keepAlive,
      'debug': _debug,
      'executable': {
        'script': _script,
        'params': _params,
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
  String get script => _script;
}