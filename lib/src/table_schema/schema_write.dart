import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_result.dart';

///
/// An abstraction on write data access
abstract interface class SchemaWrite<T extends SchemaEntryAbstract> {
  ///
  /// Empty instance implements SchemaRead
  const factory SchemaWrite.empty() = _SchemaWriteEmpty;
  ///
  /// Inserts new entry into the source
  Future<Result<void, Failure>> update(T entry);
  ///
  /// Updates entry at the source
  Future<Result<T, Failure>> insert(T? entry);
  ///
  /// Deletes entry from the source
  Future<Result<void, Failure>> delete(T entry);
}

///
/// Empty instance implements SchemaRead
class _SchemaWriteEmpty<T extends SchemaEntryAbstract> implements SchemaWrite<T> {
  ///
  ///
  const _SchemaWriteEmpty();
  //
  //
  @override
  Future<Result<void, Failure>> delete(T _) {
    return Future.value(Err(Failure(
      message: "$runtimeType.delete | write - not initialized", 
      stackTrace: StackTrace.current,
    )));
  }
  //
  //
  @override
  Future<Result<T, Failure>> insert(T? _) {
    return Future.value(Err(Failure(
      message: "$runtimeType.insert | write - not initialized", 
      stackTrace: StackTrace.current,
    )));
  }
  //
  //
  @override
  Future<Result<void, Failure>> update(T _) {
    return Future.value(Err(Failure(
      message: "$runtimeType.update | write - not initialized", 
      stackTrace: StackTrace.current,
    )));
  }
}