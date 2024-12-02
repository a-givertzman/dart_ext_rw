import 'dart:convert';

import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:uuid/uuid.dart';
///
/// Query for `executable` API service
class ExecutableQuery implements ApiQueryType {
  late String _id;
  final String _script;
  final Map<String, dynamic> _params;
  final bool _keepAlive;
  ///
  /// Prapares query for some executable
  ExecutableQuery({
    required String script,
    required Map<String, dynamic> params,
    bool keepAlive = false,
  }) :
    _script = script,
    _params = params,
    _keepAlive = keepAlive;
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
      'executable': {
        'name': _script,
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
  //
  //
  String get script => _script;
}