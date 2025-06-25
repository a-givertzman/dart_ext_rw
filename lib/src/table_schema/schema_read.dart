import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_result.dart';

///
/// An abstraction on read data access 
abstract interface class SchemaRead<T extends SchemaEntryAbstract, P> {
  ///
  /// Empty instance implements SchemaRead
  const factory SchemaRead.empty() = _SchemaReadEmpty;
  ///
  /// Fetchs entries with new sql built from [params]
  Future<Result<List<T>, Failure>> fetch({P? params});
  ///
  /// Closes connection
  Future<void> close();
}

///
/// Empty instance implements SchemaRead
class _SchemaReadEmpty<T extends SchemaEntryAbstract, P> implements SchemaRead<T, P> {
  ///
  ///
  const _SchemaReadEmpty();
  //
  //
  @override
  Future<Result<List<T>, Failure>> fetch({P? params}) {
    return Future.value(Err(Failure("$runtimeType.fetch | read - not initialized")));
  }
  //
  //
  @override
  Future<void> close() {
    return Future.value();
  }
}