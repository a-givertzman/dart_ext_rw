import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core.dart';

///
/// An abstraction on read data access 
abstract interface class SchemaRead<T extends SchemaEntryAbstract, P> {
  ///
  /// Empty instance implements SchemaRead
  const factory SchemaRead.empty() = _SchemaReadEmpty;
  ///
  /// Fetchs entries with new sql built from [params]
  Future<Result<List<T>, Failure>> fetch({P? params});
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
    return Future.value(Err(Failure(
      message: "$runtimeType.fetch | read - not initialized", 
      stackTrace: StackTrace.current,
    )));
  }
}