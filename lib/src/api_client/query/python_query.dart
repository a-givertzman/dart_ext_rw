import 'dart:convert';

import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:uuid/uuid.dart';
///
/// Query for `python` API service
class PythonQuery implements ApiQueryType {
  late String _id;
  final String _script;
  final bool _keepAlive;
  final Map<String, dynamic> _params;
  ///
  /// Prapares query for some python script
  PythonQuery({
    required String script,
    required Map<String, dynamic> params,
    bool keepAlive = false,
  }) :
    _script = script,
    _params = params,
    _keepAlive = keepAlive;
  //
  //
  @override
  bool valid() {
    return true;
    /// TODO some simplest validation to be implemented
  }
  //
  //
  @override
  String buildJson({String authToken = '', bool debug = false}) {
    _id = const Uuid().v1();
    final jsonString = json.encode({
      'authToken': authToken,
      'id': _id,
      'keepAlive': _keepAlive,
      'debug': debug,
      'python': {
        'script': _script,
        'params': _params,
      },
    });
    return jsonString;
  }
  //
  //
  @override
  String get id => _id;
  //
  //
  @override
  bool get keepAlive => _keepAlive;
  ///
  /// Returns contained python script
  String get script => _script;
}