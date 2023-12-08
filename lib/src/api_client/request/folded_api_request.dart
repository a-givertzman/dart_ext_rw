import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:ext_rw/src/api_client/request/api_request.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result_new.dart';
import 'converted.dart';
///
final class FoldedApiRequest<T> {
  static final _log =  const Log('FoldedApiRequest')..level = LogLevel.info;
  final ApiRequest _request;
  final Converted<Map<String,dynamic>, T> _converted;
  /// 
  /// Converts maps from [request]'s reply into entities using [converted].
  const FoldedApiRequest({
    required ApiRequest request, 
    required Converted<Map<String,dynamic>, T> converted,
  }) : 
    _request = request, 
    _converted = converted;
  ///
  /// Sends [query] to the remote.
  /// Returns entities if exist.
  Future<ResultF<List<T>>> fetch(ApiQueryType query) async {
    return _request.fetch(query)
      .then((replyResult) => switch(replyResult) {
        Ok(value:final reply) => _parse(reply.data),
        Err(:final error) => Err(error),
      });
  }
  ///
  /// Parse [entries] with [_converted].
  ResultF<List<T>> _parse(List<Map<String, dynamic>> entries) {
    final parsedEntries = <T>[];
    for(final entry in entries) {
      switch(_converted.valueFrom(entry)) {
        case Ok<T, Failure>(:final value):
          parsedEntries.add(value);
        case Err<T, Failure>(:final error):
          _log.warning('Error while converting $entry to $T');
          return Err(error);
      }
    }
    return Ok(parsedEntries);
  }
}