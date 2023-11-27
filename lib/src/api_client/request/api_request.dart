import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:ext_rw/src/api_client/address/api_address.dart';
import 'package:ext_rw/src/api_client/reply/api_reply.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hmi_core/hmi_core_result_new.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';


class ApiRequest {
  static final _log = const Log('ApiRequest')..level = LogLevel.info;
  final ApiAddress _address;
  final ApiQueryType _query;
  ///
  ApiRequest({
    required ApiAddress address,
    required ApiQueryType query,
  }) :
    _address = address,
    _query = query;
  ///
  /// sends created request to the remote
  /// returns reply if exists
  Future<Result<ApiReply, Failure>> fetch() async {
    final query = _query.buildJson();
    final bytes = utf8.encode(query);
    if (kIsWeb) {
      return _fetchWebSocket(bytes);
    } else {
      return _fetchSocket(bytes);
    }
  }
  ///
  /// Fetching on tcp socket
  Future<Result<ApiReply, Failure>> _fetchSocket(List<int> bytes) {
    return Socket.connect(_address.host, _address.port, timeout: const Duration(seconds: 3))
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
          const Duration(milliseconds: 3000),
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
  Future<Result<List<int>, Failure>> _read(Socket socket) async {
    try {
      List<int> message = [];
      final subscription = socket
        .timeout(
          const Duration(milliseconds: 3000),
          onTimeout: (sink) {
            sink.close();
          },
        )
        .listen((event) {
          message.addAll(event);
        });
      await subscription.asFuture();
      // _log.fine('._read | socket message: $message');
      _closeSocket(socket);
      return Ok(message);
    } catch (error) {
      _log.warning('._read | socket error: $error');
      await _closeSocket(socket);
      return Err(
        Failure.connection(
          message: '._read | socket error: $error', 
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
  ///
  Future<Result<bool, Failure>> _sendWeb(WebSocket socket, List<int> bytes) async {
    try {
      socket.add(bytes);
      return Future.value(const Ok(true));
    } catch (error) {
      _log.warning('._send | web socket error: $error');
      return Err(
        Failure.connection(
          message: '._send | web socket error: $error', 
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
  ///
  Future<Result<bool, Failure>> _send(Socket socket, List<int> bytes) async {
    try {
      socket.add(bytes);
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
  Future<void> _closeSocketWeb(WebSocket? socket) async {
    try {
      socket?.close();
      // socket?.destroy();
    } catch (error) {
      _log.warning('[.close] error: $error');
    }
  }  
  ///
  Future<void> _closeSocket(Socket? socket) async {
    try {
      await socket?.close();
      socket?.destroy();
    } catch (error) {
      _log.warning('[.close] error: $error');
    }
  }  
}