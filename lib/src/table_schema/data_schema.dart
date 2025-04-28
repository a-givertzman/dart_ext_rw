import 'dart:async';

import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_result.dart';

///
/// A collection of the SchameEntry, 
/// abstruction on the SQL table rows
class DataSchema<T extends SchemaEntryAbstract, P> implements Schema<T, P> {
  final SchemaRead<T, P> _read;
  final SchemaWrite<T> _write;
  final StreamController<Result<List<T>, Failure>> _controller = StreamController.broadcast();
  ///
  /// A collection of the SchameEntry, 
  /// abstruction on the SQL table rows
  /// - [keys] - list of table field names
  DataSchema({
    SchemaRead<T, P> read = const SchemaRead.empty(),
    SchemaWrite<T> write = const SchemaWrite.empty(),
  }) :
    _read = read,
    _write = write;
  ///
  /// Fetchs data with new sql built from [values]
  @override
  Future<Result<List<T>, Failure>> fetch(P params) async {
    return _read.fetch(params: params).then((result) {
      if (_controller.hasListener) _controller.add(result);
      return result;
    });
  }
  //
  //
  @override
  Stream<Result<List<T>, Failure>> get stream {
    return _controller.stream;
  }
  ///
  /// Inserts new entry into the table schema
  @override
  Future<Result<void, Failure>> insert({T? entry}) {
    return _write.insert(entry);
  }
  ///
  /// Updates entry of the table schema
  @override
  Future<Result<void, Failure>> update(T entry) {
    return _write.update(entry);
  }
  ///
  /// Deletes entry of the table schema
  @override
  Future<Result<void, Failure>> delete(T entry) {
    return _write.delete(entry);
  }
  //
  //
  @override
  Future<void> close() {
    return Future.wait([
      _controller.close(),
      _read.close(),
      _write.close(),
    ]);
  }
}
