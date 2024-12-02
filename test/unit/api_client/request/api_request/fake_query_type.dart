import 'package:ext_rw/src/api_client/query/api_query_type.dart';
///
/// For testing only
class FakeApiQueryType implements ApiQueryType {
  final bool _valid;
  final String _query;
  final bool _keepAlive;
  ///
  /// For testing only
  FakeApiQueryType({
    required bool valid,
    required String query,
    bool keepAlive = false,
  })  : _valid = valid,
        _query = query,
        _keepAlive = keepAlive;
  //
  @override
  bool valid() => _valid;
  //
  @override
  String buildJson({String authToken = '', bool debug = false}) => _query;
  ///
  /// insert directly into _query in fake implementation
  @override
  String get id => '';
  //
  //
  @override
  bool get keepAlive => _keepAlive;
}
