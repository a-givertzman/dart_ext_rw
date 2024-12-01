import 'dart:async';
import 'dart:convert';

import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/message.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/reply/api_reply.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';

///
/// Provide multiple requests via [Message] - a part of `ApiRequest`
/// - Can be fetched multiple times
/// - Keeps socket connection opened if `keep` = true
class ArcMessage {
  static final _log = const Log('ArcMessage');
  final Map<int, Completer<Result<ApiReply, Failure>>> _queries = {};
  final Message _message;
  final Duration _timeout;
  final bool keep;
  bool done = false;
  StreamSubscription<(FieldId, FieldKind, List<int>)>? _subscription;
  ///
  ///
  ArcMessage(
    Message message,
    this.keep, {
    Duration timeout = const Duration(milliseconds: 3000),
  }): _message = message, _timeout = timeout {
    _subscription = _message.stream.listen(
        (event) async {
          final (FieldId id, FieldKind kind, Bytes bytes) = event;
          _log.debug('.listen.onData | id: $id,  kind: $kind,  bytes: ${bytes.length > 16 ? bytes.sublist(0, 16) : bytes}');
          final query = _queries[id.id];
          if (query != null) {
            query.complete(
              Ok(ApiReply.fromJson(
                utf8.decode(bytes),
              )),
            );
            _queries.remove(id.id);
            if (!keep && _queries.isEmpty) {
              await Future.wait([
                _subscription?.cancel() ?? Future.value(),
                _message.close(),
              ]);
              done = true;
            }
          } else {
            _log.error('.listen.onData | id \'${id.id}\' - not found');
          }
        },
        onError: (err) {
          _log.error('.listen.onError | Error: $err');
          return err;
        },
        onDone: () async {
          await Future.wait([
            _subscription?.cancel() ?? Future.value(),
            _message.close(),
          ]);
          done = true;
          _log.warning('.listen.onDone | Done');
        },
      );
  }
  ///
  /// Sends `bytes` to the remote
  /// - `id` - integer id unique withing connection
  /// - Returns reply or error
  Future<Result<ApiReply, Failure>> fetch(int id, Bytes bytes) {
    if (!_queries.containsKey(id)) {
      _log.debug('.fetch | Sending  id: \'$id\',  sql: ${bytes.length > 16 ? bytes.sublist(0, 16) : bytes}');
      final Completer<Result<ApiReply, Failure>> completer = Completer();
      _queries[id] = completer;
      _message.add(id, bytes);
      return completer.future.timeout(_timeout, onTimeout: () {
        return Err<ApiReply, Failure>(Failure(message: 'ArcMessage.fetch | Timeout ($_timeout) expired', stackTrace: StackTrace.current));
      });
    }
    return Future.value(
      Err<ApiReply, Failure>(Failure(message: 'ArcMessage.fetch | Duplicated id \'$id\'', stackTrace: StackTrace.current)),
    );
  }
  //
  //
  @override
  String toString() {
    return 'ArcMessage{ keep: $keep, done: $done }';
  }
  ///
  /// Closes connection
  Future<void> close() {
    _queries.clear();
    return _message.close();
  }
}