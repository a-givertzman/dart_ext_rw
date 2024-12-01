import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';

class SqlRead<T extends SchemaEntryAbstract, P> implements SchemaRead<T, P> {
  late final Log _log;
  // final ApiAddress _address;
  // final String _authToken;
  final String _database;
  final bool _keepAlive;
  // final bool _debug;
  final SqlBuilder<P?> _sqlBuilder;
  final T Function(Map<String, dynamic> row) _entryBuilder;
  Sql _sql = Sql(sql: '');
  final ApiRequest _request;
  ///
  ///
  SqlRead({
    required ApiAddress address,
    required String authToken,
    required String database,
    bool keepAlive = false,
    bool debug = false,
    required SqlBuilder<P?> sqlBuilder,
    required T Function(Map<String, dynamic> row) entryBuilder,
  }) :
    // _address = address,
    // _authToken = authToken,
    _database = database,
    _keepAlive = keepAlive,
    // _debug = debug,
    _sqlBuilder = sqlBuilder,
    _entryBuilder = entryBuilder,
    _request = ApiRequest(
      address: address, 
      authToken: authToken, 
      debug: debug,
      query: SqlQuery(
        database: database,
        sql: '',
        keepAlive: keepAlive,
      ),
    ) {
    _log = Log("$runtimeType")..level = LogLevel.info;
  }
  //
  //
  @override
  Future<Result<List<T>, Failure>> fetch({P? params, bool? keepAlive}) {
    _sql = _sqlBuilder(_sql, params);
    return _fetch(_sql, keepAlive ?? _keepAlive);
  }
  ///
  /// Fetchs data with [sql]
  Future<Result<List<T>, Failure>> _fetch(Sql sql, bool keepAlive) {
    final query = SqlQuery(
      database: _database,
      sql: sql.build(),
      keepAlive: keepAlive,
    );
    _log.debug("._fetch | query: $query");
    return _request.fetchWith(query)
      .then((result) {
        return switch (result) {
          Ok(value :final reply) => () {
            _log.debug("._fetch | reply: $reply");
            if (reply.hasError) {
              return Err<List<T>, Failure>(Failure(message: reply.error.message, stackTrace: StackTrace.current));
            } else {
              final List<T> entries = [];
              final rows = reply.data;
              final rowsLength = rows.length;
              _log.debug("._fetch | reply rows ($rowsLength): $rows");
              for (final row in rows) {
                _log.debug("._fetch | row: $row");
                final entry = _entryBuilder(row);
                _log.debug("._fetch | entry: $entry");
                entries.add(entry);
              }
              _log.debug("._fetch | entries: $entries");
              return Ok<List<T>, Failure>(entries);
            }
          }(), 
          Err(:final error) => () {
            _log.debug("._fetch | error: $error");
            return Err<List<T>, Failure>(error);
          }(),
        };
      },
      onError: (err) {
        return Err<List<T>, Failure>(Failure(message: '$runtimeType._fetch | Error: $err', stackTrace: StackTrace.current));
      },
    );
  }
}