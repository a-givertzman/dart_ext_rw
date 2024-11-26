import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';

class SqlWrite<T extends SchemaEntryAbstract> implements SchemaWrite<T> {
  late final Log _log;
  // final ApiAddress _address;
  // final String _authToken;
  final String _database;
  final bool _keepAlive;
  // final bool _debug;
  final SqlBuilder<T>? _insertSqlBuilder;
  final SqlBuilder<T>? _updateSqlBuilder;
  final SqlBuilder<T>? _deleteSqlBuilder;
  // final T Function(Map<String, dynamic> row) _entryFromFactories;
  final T Function() _emptyEntryBuilder;
  final ApiRequest _request;
  ///
  ///
  SqlWrite({
    required ApiAddress address,
    required String authToken,
    required String database,
    bool keepAlive = false,
    bool debug = false,
    SqlBuilder<T>? insertSqlBuilder,
    SqlBuilder<T>? updateSqlBuilder,
    SqlBuilder<T>? deleteSqlBuilder,
    // required T Function(Map<String, dynamic> row) entryFromFactories,
    required T Function() emptyEntryBuilder,
  }) :
    // _address = address,
    // _authToken = authToken,
    _database = database,
    _keepAlive = keepAlive,
    // _debug = debug,
    _insertSqlBuilder = insertSqlBuilder,
    _updateSqlBuilder = updateSqlBuilder,
    _deleteSqlBuilder = deleteSqlBuilder,
    // _entryFromFactories = entryFromFactories,
    _emptyEntryBuilder = emptyEntryBuilder,
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
    _log = Log("$runtimeType");
  }
  //
  //
  @override
  Future<Result<T, Failure>> insert(T? entry) {
    T entry_;
    if (entry != null) {
      entry_ = entry;
    } else {
      entry_ = _emptyEntryBuilder();
    }
    final builder = _insertSqlBuilder;
    if (builder != null) {
      final initialSql = Sql(sql: '');
      final sql = builder(initialSql, entry_);
      return _fetchWith(sql).then((result) {
        return switch(result) {
          Ok() => () {
            return Ok<T, Failure>(entry_);
          }(),
          Err(:final error) => () {
            return Err<T, Failure>(error);
          }(),
        };
      });
    }
    return Future.value(
      Err(Failure(
        message: "$runtimeType.insert | insertSqlBuilder is not initialized", 
        stackTrace: StackTrace.current,
      )),
    );
  }
  //
  //
  @override
  Future<Result<void, Failure>> update(T entry) {
    final builder = _updateSqlBuilder;
    if (builder != null) {
      final initialSql = Sql(sql: '');
      final sql = builder(initialSql, entry);
      return _fetchWith(sql).then((result) {
        return switch(result) {
          Ok() => () {
            return const Ok<void, Failure>(null);
          }(),
          Err(:final error) => () {
            return Err<void, Failure>(error);
          }(),
        };
      });
    }
    return Future.value(
      Err(Failure(
        message: "$runtimeType.update | updateSqlBuilder is not initialized", 
        stackTrace: StackTrace.current,
      )),
    );
  }
  //
  //
  @override
  Future<Result<void, Failure>> delete(T entry) {
    final builder = _deleteSqlBuilder;
    if (builder != null) {
      final initialSql = Sql(sql: '');
      final sql = builder(initialSql, entry);
      return _fetchWith(sql).then((result) {
        return switch(result) {
          Ok() => () {
            return const Ok<void, Failure>(null);
          }(),
          Err(:final error) => () {
            return Err<void, Failure>(error);
          }(),
        };
      });
    }
    return Future.value(
      Err(Failure(
        message: "$runtimeType.delete | deleteSqlBuilder is not initialized", 
        stackTrace: StackTrace.current,
      )),
    );
  }
  ///
  /// Fetchs data with new [sql]
  Future<Result<void, Failure>> _fetchWith(Sql sql) {
    final query = SqlQuery(
      database: _database,
      sql: sql.build(),
      keepAlive: _keepAlive,
    );
    _log.debug("._fetchWith | query: $query");
    return _request.fetch()
      .then((result) {
        return switch (result) {
          Ok(:final value) => () {
            final reply = value;
            if (reply.hasError) {
              return Err<void, Failure>(Failure(message: reply.error.message, stackTrace: StackTrace.current));
            } else {
              return const Ok<void, Failure>(null);
            }
          }(), 
          Err(:final error) => Err<void, Failure>(error),
        };
      },
      onError: (err) {
        return Err<List<T>, Failure>(Failure(message: '$runtimeType._fetchWith | Error: $err', stackTrace: StackTrace.current));
      },
    );
  }
  // ///
  // ///
  // T _makeEmptyEntry() {
  //   // final constructor = _entryEmptyFactories[T];
  //   return _entryEmptyFactories();
  //   // if (constructor != null) {
  //   // } else {
  //   //   throw Failure(
  //   //     message: "$runtimeType._makeEntry | Can't find constructor for $T", 
  //   //     stackTrace: StackTrace.current,
  //   //   );
  //   // }
  // }
  // ///
  // ///
  // T _makeEntry(Map<String, dynamic> row) {
  //   return _entryFromFactories(row);
  //   // final constructor = _entryFromFactories[T];
  //   // if (_entryFromFactories != null) {
  //   // }
  //   // throw Failure(
  //   //   message: "$runtimeType._makeEntry | Can't find constructor for $T", 
  //   //   stackTrace: StackTrace.current,
  //   // );
  // }
}