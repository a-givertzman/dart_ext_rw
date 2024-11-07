import 'package:ext_rw/ext_rw.dart';
import 'package:hmi_core/hmi_core.dart';

///
/// An abstruction on the data access
abstract interface class Schema<T extends SchemaEntryAbstract, P> {
  ///
  /// Fetchs data from the data source using [params]
  Future<Result<List<T>, Failure>> fetch(P params);
  ///
  /// Inserts new entry into the data source
  Future<Result<void, Failure>> insert({T? entry});
  ///
  /// Updates entry of the data source
  Future<Result<void, Failure>> update(T entry);
  ///
  /// Deletes entry from the data source
  Future<Result<void, Failure>> delete(T entry);
}
