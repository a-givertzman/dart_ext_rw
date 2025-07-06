import 'dart:async';

import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';

///
/// A collection of the SchameEntry, 
/// abstruction on the SQL table rows
class RelationSchema<T extends SchemaEntryAbstract, P> implements TableSchemaAbstract<T, P> {
  late final Log _log;
  final TableSchemaAbstract<T, P> _schema;
  final Map<String, TableSchemaAbstract> _relations;
  final StreamController<Result<List<T>, Failure>> _controller = StreamController.broadcast();
  ///
  /// A collection of the SchameEntry, 
  /// abstruction on the SQL table rows
  /// - [keys] - list of table field names
  RelationSchema({
    required TableSchemaAbstract<T, P> schema,
    Map<String, TableSchemaAbstract> relations = const {},
  }) :
    _schema = schema,
    _relations = relations {
      _log = Log('$runtimeType');
    }
  ///
  /// Returns a list of table field names
  @override
  List<Field<T>> get fields {
    return _schema.fields;
  }
  ///
  /// Returns a list of table field keys
  @override
  List<String> get keys {
    return _schema.keys;
  }
  //
  //
  @override
  Map<String, T> get entries => _schema.entries;
  ///
  /// Fetchs data with new sql built from [values]
  @override
  Future<Result<List<T>, Failure>> fetch(params) async {
    Result<List<T>, Failure> schemaFetchResult = Err(Failure('$runtimeType.fetch | Just initialized only'));
    await Future.wait([
      fetchRelations(),
      _schema.fetch(params).then((result) {
        schemaFetchResult = result;
      }),
    ]).then((_) {
      if (_controller.hasListener) _controller.add(schemaFetchResult);
    });
    return schemaFetchResult;
  }
  //
  //
  @override
  Stream<Result<List<T>, Failure>> get stream {
    return _controller.stream;
  }
  //
  //
  @override
  Map<String, List<SchemaEntryAbstract>> get relations {
    return _relations.map((key, scheme) {
      final entries = scheme.entries;
      return MapEntry(key, entries.values.toList());
    });
  }
  //
  //
  @override
  Result<TableSchemaAbstract, Failure> relation(String id) {
    final rel = _relations[id];
    if (rel != null) {
      return Ok(rel);
    } else {
      return Err(Failure(
        '$runtimeType.relation | id: $id - not found', 
      ));
    }
  }
  ///
  /// Inserts new entry into the table schema
  @override
  Future<Result<void, Failure>> insert({T? entry}) {
    return _schema.insert(entry: entry);
  }
  ///
  /// Updates entry of the table schema
  @override
  Future<Result<void, Failure>> update(T entry) {
    return _schema.update(entry);
  }
  ///
  /// Deletes entry of the table schema
  @override
  Future<Result<void, Failure>> delete(T entry) {
    return _schema.delete(entry);
  }
  ///
  /// Fetchs data of the relation schemas only (with existing sql)
  @override
  Future<Result<void, Failure>> fetchRelations() async {
    Result<void, Failure> result = const Ok(null);
    for (final field in _schema.fields) {
      if (field.relation.isNotEmpty) {
        switch (relation(field.relation.id)) {
          case Ok(:final value):
            await value.fetch(null);
          case Err(:final error):
            final err = Failure.pass("$runtimeType.fetchRelations | relation '${field.relation}' - not found", error);
            _log.warning(err);
            result = Err(err);
        }
      }
    }
    return result;
  }
  //
  //
  @override
  Future<void> close() {
    return Future.wait([
      _controller.close(),
      _schema.close(),
      ..._relations.values.map((schema) {
        return schema.close();
      }),
    ]);
  }
}
