import 'dart:convert';

import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:uuid/uuid.dart';

class PythonQuery implements ApiQueryType {
  final String _authToken;
  late String _id;
  final String _script;
  final bool _keepAlive;
  final bool _debug;
  final Map<String, dynamic> _params;
  ///
  /// Prapares query for some python script
  PythonQuery({
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
      'authToken': _authToken,
      'id': _id,
      'keepAlive': _keepAlive,
      'debug': _debug,
      'python': {
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