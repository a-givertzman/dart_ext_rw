import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_result.dart';

///
/// A collection of the SchameEntry, 
/// abstruction on the SQL table rows
class DataSchema<T extends SchemaEntryAbstract, P> implements Schema<T, P> {
  final SchemaRead<T, P> _read;
  final SchemaWrite<T> _write;
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
    final read = _read;
    return read.fetch(params: params);
  }
  ///
  /// Inserts new entry into the table schema
  @override
  Future<Result<void, Failure>> insert({T? entry}) {
    final write = _write;
    return write.insert(entry);
  }
  ///
  /// Updates entry of the table schema
  @override
  Future<Result<void, Failure>> update(T entry) {
    final write = _write;
    return write.update(entry);
  }
  ///
  /// Deletes entry of the table schema
  @override
  Future<Result<void, Failure>> delete(T entry) {
    final write = _write;
    return write.delete(entry);
  }
  //
  //
  @override
  Future<void> close() {
    return Future.wait([
      _read.close(),
      _write.close(),
    ]);
  }
}
