import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ext_rw/src/api_client/message/parse_data.dart';
import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/parse_kind.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_size.dart';
import 'package:ext_rw/src/api_client/message/parse_syn.dart';
import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:ext_rw/src/api_client/address/api_address.dart';
import 'package:ext_rw/src/api_client/reply/api_reply.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';


class ApiRequest {
  static final _log = const Log('ApiRequest')..level = LogLevel.info;
  final ApiAddress _address;
  final String _authToken;
  final ApiQueryType _query;
  final Duration _timeout;
  final Duration _connectTimeout;
  final bool _debug;
  ///
  ApiRequest({
    required String authToken,
    required ApiAddress address,
    required ApiQueryType query,
    Duration timeout = const Duration(milliseconds: 3000),
    Duration connectTimeout = const Duration(milliseconds: 256),
    bool debug = false,
  }) :
    _authToken = authToken,
    _address = address,
    _query = query,
    _timeout = timeout,
    _connectTimeout = connectTimeout,
    _debug = debug;
  ///
  String get authToken => _authToken;
  ///
  /// Sends created request to the remote
  /// - returns reply if exists
  Future<Result<ApiReply, Failure>> fetch() async {
    final query = _query.buildJson(authToken: _authToken, debug: _debug);
    final bytes = utf8.encode(query);
    if (kIsWeb) {
      return _fetchWebSocket(bytes);
    } else {
      return _fetchSocket(bytes);
    }
  }
  ///
  /// Sends created request with new query to the remote
  /// - returns reply if exists
  Future<Result<ApiReply, Failure>> fetchWith(ApiQueryType query) async {
    final queryJson = query.buildJson(authToken: _authToken, debug: _debug);
    final bytes = utf8.encode(queryJson);
    if (kIsWeb) {
      return _fetchWebSocket(bytes);
    } else {
      return _fetchSocket(bytes);
    }
  }
  ///
  /// Fetching on tcp socket
  Future<Result<ApiReply, Failure>> _fetchSocket(List<int> bytes) {
    return Socket.connect(_address.host, _address.port, timeout: _connectTimeout)
      .then((socket) async {
        return _send(socket, bytes)
          .then((result) {
            return switch(result) {
              Ok() => _read(socket).then((result) {
                return switch (result) {
                  Ok(:final value) => Ok<ApiReply, Failure>(
                    ApiReply.fromJson(
                      utf8.decode(value),
                    ),
                  ),
                  Err(:final error) => Err<ApiReply, Failure>(error),
                };
              }),
              Err(:final error) => Future<Result<ApiReply, Failure>>.value(
                  Err<ApiReply, Failure>(error),
              ),
            };
          });
      })
      .catchError((error) {
          return Err<ApiReply, Failure>(
            Failure.connection(
              message: '.fetch | socket error: $error', 
              stackTrace: StackTrace.current,
            ),
          );
      });
  }
  ///
  /// Fetching on web socket
  Future<Result<ApiReply, Failure>> _fetchWebSocket(List<int> bytes) {
    return WebSocket.connect('ws://${_address.host}:${_address.port}')
      .then((wSocket) async {
        return _sendWeb(wSocket, bytes)
          .then((result) {
            return switch(result) {
              Ok() => _readWeb(wSocket)
                .then((result) {
                  final Result<ApiReply, Failure> r = switch(result) {
                    Ok(:final value) => Ok(
                      ApiReply.fromJson(
                        utf8.decode(value),
                      ),
                    ),
                    Err(:final error) => Err(error),
                  };
                  return r;
                }), 
              Err(:final error) => Future<Result<ApiReply, Failure>>.value(
                  Err(error),
                ),
            };
          });
      })
      .catchError((error) {
          return Err<ApiReply, Failure>(
            Failure(
              message: '.fetch | web socket error: $error', 
              stackTrace: StackTrace.current,
            ),
          );
      });
  }
  ///
  Future<Result<List<int>, Failure>> _readWeb(WebSocket socket) async {
    try {
      List<int> message = [];
      final subscription = socket
        .timeout(
          _timeout,
          onTimeout: (sink) {
            sink.close();
          },
        )
        .listen((event) {
          message.addAll(event);
        });
      await subscription.asFuture();
      // _log.fine('._read | socket message: $message');
      _closeSocketWeb(socket);
      return Ok(message);
    } catch (error) {
      _log.warning('._read | socket error: $error');
      await _closeSocketWeb(socket);
      return Err(
        Failure.connection(
          message: '._read | socket error: $error', 
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
  ///
  Result<List<int>, Failure> _parse(ParseData message, Bytes bytes) {
    switch (message.parse(bytes)) {
      case Some(value: (FieldKind kind, FieldSize _, Bytes data)):
        switch (kind) {
          case FieldKind.any:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.empty:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.bytes:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.bool:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.uint16:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.uint32:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.uint64:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.int16:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.int32:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.int64:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.f32:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.f64:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.string:
            return Ok(data);
          case FieldKind.timestamp:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
          case FieldKind.duration:
            return Err(Failure(message: '._read | Socket message of kind "$kind" - is not supported, was skipped', stackTrace: StackTrace.current));
        }
      case None():
        final logBytes = bytes.length > 24 ? '${bytes.sublist(0, 24)}...' : bytes;
        return Err(Failure(message: '._read | Socket message not parsed: $logBytes', stackTrace: StackTrace.current));    
    }
  }
  ParseData resetParseMessage() {
    return ParseData(
      field: ParseSize(
        size: FieldSize.def(),
        field: ParseKind(
          field: ParseSyn.def(),
        ),
      ),
    );
  }
  ///
  /// Returns message read from the socket
  Future<Result<List<int>, Failure>> _read(Socket socket) async {
    final ParseData message = resetParseMessage();
    int maxChunks = 10;
    try {
      Result<List<int>, Failure> result = Err(Failure(message: 'ApiRequest._read | Result is not assigned', stackTrace: StackTrace.current));
      final subscription = socket
        .timeout(
          _timeout,
          onTimeout: (sink) {
            sink.close();
          },
        )
        .listen((bytes) {
          if (maxChunks-- > 0) {
            result = _parse(message, bytes);
          }
          maxChunks = 10;
          result = Err(Failure(message: 'ApiRequest._read | No valid messages in the socket', stackTrace: StackTrace.current));    
        });
      await subscription.asFuture();
      // _log.fine('._read | socket message: $message');
      _closeSocket(socket);
      return result;
    } catch (error) {
      _log.warning('._read | Socket error: $error');
      await _closeSocket(socket);
      return Err(
        Failure.connection(
          message: '._read | Socket error: $error', 
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
  ///
  /// Sends bytes over WEB socket
  Future<Result<bool, Failure>> _sendWeb(WebSocket socket, List<int> bytes) async {
    final message = MessageBuild(
      syn: FieldSyn.def(),
      kind: FieldKind.string,
      size: FieldSize.def(),
      data: FieldData([]),
    );
    try {
      socket.add(message.build(bytes));
      return Future.value(const Ok(true));
    } catch (error) {
      _log.warning('._send | Web socket error: $error');
      return Err(
        Failure.connection(
          message: '._send | Web socket error: $error', 
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
  ///
  /// Sends bytes over raw TCP socket
  Future<Result<bool, Failure>> _send(Socket socket, List<int> bytes) async {
    final message = MessageBuild(
      syn: FieldSyn.def(),
      kind: FieldKind.string,
      size: FieldSize.def(),
      data: FieldData([]),
    );
    try {
      socket.add(message.build(bytes));
      return Future.value(const Ok(true));
    } catch (error) {
      _log.warning('._send | socket error: $error');
      return Err(
        Failure.connection(
          message: '._send | socket error: $error', 
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
  ///
  /// Closes the socket
  Future<void> _closeSocketWeb(WebSocket? socket) async {
    try {
      socket?.close();
      // socket?.destroy();
    } catch (error) {
      _log.warning('[.close] error: $error');
    }
  }  
  ///
  /// Closes the socket
  Future<void> _closeSocket(Socket? socket) async {
    try {
      await socket?.close();
      socket?.destroy();
    } catch (error) {
      _log.warning('[.close] error: $error');
    }
  }  
}