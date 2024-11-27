import 'dart:async';
import 'dart:io';

import 'package:ext_rw/src/api_client/address/api_address.dart';
import 'package:ext_rw/src/api_client/message/message.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/reply/api_reply.dart';
import 'package:ext_rw/src/api_client/request/arc_message.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';

///
/// Provide multiple requests via [Message]
class Messages {
  static final _log = const Log('Messages')..level = LogLevel.debug;
  final List<ArcMessage> _messages = [];
  final ApiAddress _address;
  final Duration _timeout;
  Completer<Result<ArcMessage, Failure>>? _connection;
  ///
  ///
  Messages({
    required ApiAddress address,
    Duration timeout = const Duration(milliseconds: 3000),
  }):
    _address = address,
    _timeout = timeout;
  ///
  ///
  Future<Result<ApiReply, Failure>> fetch(int id, Bytes bytes, bool keepAlive) async {
    int index = 0;
    while (index < _messages.length) {
      final message = _messages.elementAt(index);
      if (message.done) {
        _log.debug('.fetch | Removing done message: $message');
        _messages.remove(message);
      } else if (message.keep) {
        _log.debug('.fetch | Found message: $message');
        return message.fetch(id, bytes);
      } else {
        index++;
      }
    }
    return _check(id, bytes, keepAlive).then(
        (result) {
          switch (result) {
            case Ok<ArcMessage, Failure>(value: final message):
              return message.fetch(id, bytes);
            case Err<ArcMessage, Failure>(: final error):
              return Err(Failure(message: 'Messages.fetch | Error: $error', stackTrace: StackTrace.current));
          }
        },
        onError: (error) {
            return Err(Failure(message: 'Messages.fetch | Error: $error', stackTrace: StackTrace.current));
        },
      );
  }
  ///
  ///
  Future<Result<ArcMessage, Failure>> _check(int id, Bytes bytes, bool keepAlive) {
    final connection = _connection;
    if (connection == null) {
      _log.debug('._check | New connection...');
      final connection = Completer<Result<ArcMessage, Failure>>();
      _connection = connection;
      _connect(id, bytes, keepAlive).then(
        (result) {
          _log.debug('._check | New connection result: $result');
          switch (result) {
            case Ok<ArcMessage, Failure>(value: final message):
              connection.complete(Ok(message));
              _connection = null;
            case Err<ArcMessage, Failure>(: final error):
              connection.complete(
                Err(Failure(message: 'Messages._check | Error: $error', stackTrace: StackTrace.current)),
              );
              _connection = null;
          }
        },
        onError: (error) {
          _log.debug('._check | Error: $error');
          connection.complete(
            Err(Failure(message: 'Messages._check | Error: $error', stackTrace: StackTrace.current)),
          );
          _connection = null;
        },
      );
    }
    final conn = _connection;
    if (conn != null) {
      _log.debug('._check | Await connection...');
      return conn.future;
    }
    return Future.value(
      Err(Failure(message: 'Messages._check | Not connected', stackTrace: StackTrace.current)),
    );
  }
  ///
  ///
  Future<Result<ArcMessage, Failure>> _connect(int id, Bytes bytes, bool keepAlive) {
    return Socket
      .connect(_address.host, _address.port, timeout: _timeout)
      .then(
        (socket) async {
          _log.debug('._connect | connected');
          socket.setOption(SocketOption.tcpNoDelay, true);
          final message = ArcMessage(Message(socket), keepAlive);
          _messages.add(message);
          _log.warning('._connect | _messages $_messages');
          return Ok(message);
        },
        onError: (err) {
          _log.warning('._connect | Error $err');
          return Err(Failure(message: 'ApiRequest._fetchSocket | Connection error: $err', stackTrace: StackTrace.current));
        },
      );
  }
}
