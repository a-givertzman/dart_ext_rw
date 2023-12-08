import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:uuid/uuid.dart';

class PythonQuery implements ApiQueryType {
  late String _id;
  final String _script;
  final Map<String, dynamic> _params;
  ///
  /// Prapares query for some python script
  PythonQuery({
    required String script,
    required Map<String, dynamic> params,
  }) :
    _script = script,
    _params = params;
///
  @override
  bool valid() {
    return true;
    /// TODO some simplest validation to be implemented
  }
  ///
  @override
  Map<String,dynamic> buildJson() {
    _id = const Uuid().v1();
    return {
      'id': _id,
      'python': {
        'script': _script,
        'params': _params,
      },
    };
  }
  ///
  @override
  String get id => _id;
  ///
  String get script => _script;
}