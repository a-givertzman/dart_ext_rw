import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Performs a request(s) to the API server
/// - `SqlAccess.keep` can be fetched multiple times, call `close()` at the end
class SqlAccess<T, P> {
  late final Log _log;
  final String _database;
  final SqlBuilder<P?> _sqlBuilder;
  final T Function(Map<String, dynamic> row)? _entryBuilder;
  final ApiRequest _request;
  Sql _sql = Sql(sql: '');
  ///
  /// Performs a request to the API server
  /// - Can be fetched only once, closes automatically
  /// - `authToken` - authentication parameter, dipends on authentication kind
  /// - `address` - IP and port of the API server
  /// - `database` - database name
  /// - `timeout` - time to wait read, write & connection until timeout error, default - 3 sec
  SqlAccess({
    required ApiAddress address,
    required String authToken,
    required String database,
    Duration timeout = const Duration(milliseconds: 3000),
    bool debug = false,
    required SqlBuilder<P?> sqlBuilder,
    T Function(Map<String, dynamic> row)? entryBuilder,
  }) :
    _database = database,
    _sqlBuilder = sqlBuilder,
    _entryBuilder = entryBuilder,
    _request = ApiRequest(
      address: address, 
      authToken: authToken, 
      timeout: timeout,
      debug: debug,
      query: SqlQuery(
        database: database,
        sql: '',
      ),
    ) {
    _log = Log("$runtimeType");
  }
  ///
  /// Performs a requests to the API server
  /// - Can be fetched multiple times, , call `close()` at the end
  /// - `authToken` - authentication parameter, dipends on authentication kind
  /// - `address` - IP and port of the API server
  /// - `database` - database name
  /// - `timeout` - time to wait read, write & connection until timeout error, default - 3 sec
  SqlAccess.keep({
    required ApiAddress address,
    required String authToken,
    required String database,
    Duration timeout = const Duration(milliseconds: 3000),
    bool debug = false,
    required SqlBuilder<P?> sqlBuilder,
    T Function(Map<String, dynamic> row)? entryBuilder,
  }) :
    _database = database,
    _sqlBuilder = sqlBuilder,
    _entryBuilder = entryBuilder,
    _request = ApiRequest.keep(
      address: address, 
      authToken: authToken, 
      timeout: timeout,
      debug: debug,
      query: SqlQuery(
        database: database,
        sql: '',
      ),
    ) {
    _log = Log("$runtimeType");
  }
  ///
  /// Sends specified query to the remote
  /// - Keeps socket connection opened if [keep] = true
  Future<Result<List<T>, Failure>> fetch({P? params}) {
    _sql = _sqlBuilder(_sql, params);
    return _fetch(_sql);
  }
  ///
  /// Fetchs data with [sql]
  Future<Result<List<T>, Failure>> _fetch(Sql sql) {
    final query = SqlQuery(
      database: _database,
      sql: sql.build(),
    );
    _log.debug("._fetch | request: $query");
    final entryBuilder = _entryBuilder ?? (dynamic _) {return null as T;};
    return _request.fetchWith(query)
      .then((result) {
        return switch (result) {
          Ok(value :final reply) => () {
            _log.debug("._fetch | reply: $reply");
            if (reply.hasError) {
              return Err<List<T>, Failure>(Failure.pass('$runtimeType._fetch', reply.error.message));
            } else {
              final List<T> entries = [];
              final rows = reply.data;
              final rowsLength = rows.length;
              _log.trace("._fetch | reply rows ($rowsLength): $rows");
              for (final row in rows) {
                _log.trace("._fetch | row: $row");
                final entry = entryBuilder(row);
                _log.trace("._fetch | entry: $entry");
                entries.add(entry);
              }
              _log.trace("._fetch | entries: $entries");
              return Ok<List<T>, Failure>(entries);
            }
          }(), 
          Err(error:final err) => () {
            // _log.warn("._fetch | error: $err");
            return Err<List<T>, Failure>(Failure.pass('$runtimeType._fetch', err));
          }(),
        };
      },
      onError: (err) {
        return Err<List<T>, Failure>(Failure.pass('$runtimeType._fetch', err));
      },
    );
  }
  ///
  /// Closes connection
  Future<void> close() {
    return _request.close();
  }
}
