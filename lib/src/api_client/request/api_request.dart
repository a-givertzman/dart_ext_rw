import 'dart:async';
import 'dart:convert';

import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:ext_rw/src/api_client/address/api_address.dart';
import 'package:ext_rw/src/api_client/reply/api_reply.dart';
import 'package:ext_rw/src/api_client/request/messages.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hmi_core/hmi_core_result.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
///
/// Performs the request(s) to the API server
/// - `ApiRequest.keep` can be fetched multiple times, call `close()` at the end
class ApiRequest {
  static final _log = const Log('ApiRequest');
  final String _authToken;
  final ApiQueryType _query;
  final bool _keep;
  final bool _debug;
  final Messages _messages;
  int _id = 0;
  ///
  /// Single request to the API server
  /// - Can be fetched only once
  /// - authToken - authentication parameter, dipends on authentication kind
  /// - address - IP and port of the API server
  /// - query - paload data to be sent to the API server, containing specific kind of API query
  /// - timeout - time to wait read, write & connection until timeout error, default - 3 sec
  ApiRequest({
    required String authToken,
    required ApiAddress address,
    required ApiQueryType query,
    Duration timeout = const Duration(milliseconds: 3000),
    bool debug = false,
  }) :
    _authToken = authToken,
    _query = query,
    _keep = false,
    _debug = debug,
    _messages = Messages(address: address, timeout: timeout);
  ///
  /// Multiple requests to the API server
  /// - Can be fetched multiple times
  /// - Must be closed by calling `close()` at the end
  /// - authToken - authentication parameter, dipends on authentication kind
  /// - address - IP and port of the API server
  /// - query - paload data to be sent to the API server, containing specific kind of API query
  /// - timeout - time to wait read, write & connection until timeout error, default - 3 sec
  ApiRequest.keep({
    required String authToken,
    required ApiAddress address,
    required ApiQueryType query,
    Duration timeout = const Duration(milliseconds: 3000),
    bool debug = false,
  }) :
    _authToken = authToken,
    _query = query,
    _keep = true,
    _debug = debug,
    _messages = Messages(address: address, timeout: timeout);
  ///
  /// Returns specified authToken
  String get authToken => _authToken;
  ///
  /// Sends created request to the remote
  /// - Returns reply or error
  Future<Result<ApiReply, Failure>> fetch() async {
    final queryJson = _query.buildJson(authToken: _authToken, debug: _debug, keep: _keep);
    final bytes = utf8.encode(queryJson);
    _log.debug('.fetch | platform: ${kIsWeb ? 'Web' : 'NonWeb'}');
    return _fetchSocket(bytes);
  }
  ///
  /// Sends specified `query` to the remote
  /// - Returns reply or error
  Future<Result<ApiReply, Failure>> fetchWith(ApiQueryType query) async {
    final queryJson = query.buildJson(authToken: _authToken, debug: _debug, keep: _keep);
    final bytes = utf8.encode(queryJson);
    _log.debug('.fetchWith | platform: ${kIsWeb ? 'Web' : 'NonWeb'}');
    return _fetchSocket(bytes);
  }
  ///
  /// Fetching on tcp socket
  Future<Result<ApiReply, Failure>> _fetchSocket(Bytes bytes) async {
    _id++;
    return _messages.fetch(_id, bytes, _keep)
      .then(
        (value) {
          if (!_keep) {
            _messages.close();
          }
          return value;
        },
        onError: (err) => Failure(message: '$runtimeType._fetchSocket| Error: $err', stackTrace: StackTrace.current),
      );
  }
  ///
  /// Closes connection
  Future<void> close() {
    return _messages.close();
  }
}
