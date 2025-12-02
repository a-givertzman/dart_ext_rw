import 'dart:async';
import 'dart:convert';

import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/message.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_log.dart';

///
/// FakeRequest
class FakeRequest {
  final _log = Log('FakeRequest');
  final Map<int, Completer<Bytes>> _queries = {};
  final Message _message;
  int id = 0;
  ///
  /// FakeRequest
  FakeRequest(Message message):
    _message = message {
    _message.stream.listen(
      (event) {
        final (FieldId id, FieldKind kind, Bytes bytes) = event;
        _log.debug('.listen.onData | Event | id: $id,  kind: $kind,  bytes: $bytes');
        if (_queries.containsKey(id.id)) {
          final query = _queries[id.id];
          if (query != null) {
            query.complete(bytes);
            _queries.remove(id.id);
          }
        } else {
          _log.error('.listen.onData | id \'${id.id}\' - not found');
        }
      },
      onError: (err) {
        _log.error('.listen.onError | Error: $err');
        _message.close();
      },
      onDone: () {
        _log.debug('.listen.onDone | Done');
        _message.close();
      },
    );
  }
  ///
  ///
  Future<Bytes> fetch(String sql) {
    id++;
    if (!_queries.containsKey(id)) {
      _log.debug('.fetch | id: \'$id\',  sql: $sql');
      final Completer<Bytes> completer = Completer();
      _queries[id] = completer;
      final bytes = utf8.encode(sql);
      _message.add(id, bytes);
      _message.flush();
      return completer.future;
    }
    throw Exception('.fetch | Duplicated id \'$id\'');
  }
  ///
  ///
  Future close() {
    return _message.close();
  }
}
