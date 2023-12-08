import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:uuid/uuid.dart';

class SqlQuery implements ApiQueryType {
  late String _id;
  final String _database;
  final String _sql;
  ///
  /// Prapares sql for some database
  SqlQuery({
    required String database,
    required String sql,
  }) :
    _database = database,
    _sql = sql;
  ///
  @override
  bool valid() {
    return true;
    /// some simplest sql syntax validation to be implemented
  }
  ///
  @override
  Map<String,dynamic> buildJson() {
    _id = const Uuid().v1();
    return {
      'id': _id,
      'sql': {
        'database': _database,
        'sql': _sql,
      },
    };
  }
  ///
  @override
  String get id => _id;
  ///
  String get database => _database;
}