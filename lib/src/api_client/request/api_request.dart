import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/query/api_query_type.dart';
import 'package:ext_rw/src/api_client/address/api_address.dart';
import 'package:ext_rw/src/api_client/reply/api_reply.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:ext_rw/src/api_client/request/messages.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hmi_core/hmi_core_result.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:web_socket_channel/io.dart';
///
/// Performs the request to the API server
/// - Can be fetched multiple times
/// - Keeps socket connection opened
class ApiRequest {
  static final _log = const Log('ApiRequest')..level = LogLevel.debug;
  final ApiAddress _address;
  final String _authToken;
  final ApiQueryType _query;
  final Duration _timeout;
  // final Duration _connectTimeout;
  final bool _debug;
  final Messages _messages;
  // Message? _message;
  // StreamSubscription<(FieldId, FieldKind, List<int>)>? _messageSubscription;
  // bool _isConnecting = false;
  int _id = 0;
  ///
  /// Request to the API server
  /// - authToken
  /// - address - IP and port of the API server
  /// - query - paload data to be sent to the API server, containing specific kind of API query
  /// - timeout
  /// - connectTimeout
  ApiRequest({
    required String authToken,
    required ApiAddress address,
    required ApiQueryType query,
    Duration timeout = const Duration(milliseconds: 3000),
    // Duration connectTimeout = const Duration(milliseconds: 256),
    bool debug = false,
  }) :
    _authToken = authToken,
    _address = address,
    _query = query,
    _timeout = timeout,
    // _connectTimeout = connectTimeout,
    _debug = debug,
    _messages = Messages(address: address, timeout: timeout);
  // ///
  // /// Conecting the socket, setup the message listener
  // Future<Result<Message, Failure>> _connect(int id) async {
  //   _log.warning('._connect | id $id  to ${_address.host}:${_address.port}');
  //   _isConnecting = true;
  //   return await Socket
  //     .connect(_address.host, _address.port, timeout: _connectTimeout)
  //     .then(
  //       (socket) async {
  //         _log.warning('._connect | connected');
  //         socket.setOption(SocketOption.tcpNoDelay, true);
  //         final message = Message(socket);
  //         _messages.putIfAbsent(0, () => message);
  //         _messages.putIfAbsent(id, () => message);
  //         _isConnecting = false;
  //         _log.warning('._connect | _messages $_messages');
  //         message.stream.listen(
  //             (event) {
  //               final (FieldId id, FieldKind kind, Bytes bytes) = event;
  //               // _log.warning('.listen.onData | Event | id: $id,  kind: $kind');
  //               _log.debug('.listen.onData | id: $id,  kind: $kind,  bytes: ${bytes.length > 16 ? bytes.sublist(0, 16) : bytes}');
  //               final query = _queries[id.id];
  //               if (query != null) {
  //                 query.complete(
  //                   Ok(ApiReply.fromJson(
  //                     utf8.decode(bytes),
  //                   )),
  //                 );
  //                 _queries.remove(id.id);
  //                 _messages.remove(id.id);
  //               } else {
  //                 _log.error('._connect.listen.onData | id \'${id.id}\' - not found');
  //               }
  //             },
  //             onError: (err) {
  //               _log.error('._connect.listen.onError | Error: $err');
  //               // message.close();
  //               // _message = None();
  //               return err;
  //             },
  //             onDone: () async {
  //               _log.warning('._connect.listen.onDone | Done');
  //               _messages.removeWhere((_, m) => m == message);
  //               _log.warning('._connect.listen.onDone | _messages $_messages');
  //               // _messageSubscription?.cancel();
  //               // _messageSubscription = null;
  //             },
  //           );
  //         return Ok(message);
  //       },
  //       onError: (err) {
  //         _isConnecting = false;
  //         _log.warning('._connect | Error $err');
  //         return Err(Failure(message: 'ApiRequest._fetchSocket | Connection error: $err', stackTrace: StackTrace.current));
  //       },
  //     );
  // }
  // ///
  // /// Conecting the socket, setup the message listener
  // Future<Result<Message, Failure>> _message(int id) async {
  //   _log.warning('._message | id $id');
  //   if (_messages.keys.contains(id)) {
  //     final message = _messages.entries.elementAtOrNull(id)?.value;
  //     return Future.value(Ok(message!));
  //   } else {
  //     final message = _messages.entries.elementAtOrNull(0)?.value;
  //     if (message != null) {
  //       _log.warning('._message | Found stored message $id');
  //       _messages.putIfAbsent(id, () => message!);
  //       return Future.value(Ok(message));
  //     } else {
  //       _log.warning('._message | Connecting new message $id');
  //       return _connect(id);
  //     }
  //   } 
  // }
  ///
  /// Returns specified authToken
  String get authToken => _authToken;
  ///
  /// Sends created request to the remote
  /// - returns reply if exists
  Future<Result<ApiReply, Failure>> fetch() async {
    final queryJson = _query.buildJson(authToken: _authToken, debug: _debug);
    final bytes = utf8.encode(queryJson);
    if (kIsWeb) {
      return _fetchWebSocket(bytes, _query.keepAlive);
    } else {
      return _fetchSocket(bytes, _query.keepAlive);
    }
  }
  ///
  /// Sends created request with new query to the remote
  /// - returns reply if exists
  Future<Result<ApiReply, Failure>> fetchWith(ApiQueryType query) async {
    final queryJson = query.buildJson(authToken: _authToken, debug: _debug);
    final bytes = utf8.encode(queryJson);
    if (kIsWeb) {
      return _fetchWebSocket(bytes, query.keepAlive);
    } else {
      return _fetchSocket(bytes, query.keepAlive);
    }
  }
  ///
  /// Fetching on tcp socket
  Future<Result<ApiReply, Failure>> _fetchSocket(Bytes bytes, bool keepAlive) async {
    // if (_isConnecting) {
    //   final time = Stopwatch()..start();
    //   while (_isConnecting) {
    //     _log.debug('._fetchSocket | Await while connecting');
    //     sleep(Duration(milliseconds: 300));
    //     if (time.elapsed > _timeout) {
    //       return Err(Failure(message: 'ApiRequest._fetchSocket | Timeout ($_timeout) expired', stackTrace: StackTrace.current));
    //     }
    //   }
    // }
    _id++;
    return _messages.fetch(_id, bytes, keepAlive);
    // switch (await _message(_id)) {
    //   case Ok(value: final message):
    //     if (!_queries.containsKey(_id)) {
    //       _log.debug('._fetchSocket | Sending  id: \'$_id\',  sql: ${bytes.length > 16 ? bytes.sublist(0, 16) : bytes}');
    //       final Completer<Result<ApiReply, Failure>> completer = Completer();
    //       _queries[_id] = completer;
    //       message.add(_id, bytes);
    //       return completer.future.timeout(_timeout, onTimeout: () {
    //         return Err<ApiReply, Failure>(Failure(message: 'ApiRequest._fetchSocket | Timeout ($_timeout) expired', stackTrace: StackTrace.current));
    //       });
    //       // if (message case Some(value: final message)) {
    //       // } else {
    //       //   return Err<ApiReply, Failure>(Failure(message: '._fetchSocket | Not ready _message', stackTrace: StackTrace.current));
    //       // }
    //     }
    //     return Err<ApiReply, Failure>(Failure(message: 'ApiRequest._fetchSocket | Duplicated _id \'$_id\'', stackTrace: StackTrace.current));
    //   case Err(: final error):
    //     return Err<ApiReply, Failure>(Failure(message: 'ApiRequest._fetchSocket | Connection error $error', stackTrace: StackTrace.current));
    // }
  }
  ///
  /// Fetching on web socket
  Future<Result<ApiReply, Failure>> _fetchWebSocket(Bytes bytes, bool keepAlive) {
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
  /// Reads bytes from web socket
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
  /// Sends bytes over WEB socket
  Future<Result<bool, Failure>> _sendWeb(WebSocket socket, Bytes bytes) async {
    final message = MessageBuild(
      syn: FieldSyn.def(),
      id: FieldId.def(),
      kind: FieldKind.bytes,
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
  /// Closes web socket
  Future<void> _closeSocketWeb(WebSocket? socket) async {
    try {
      socket?.close();
      // socket?.destroy();
    } catch (error) {
      _log.warning('[.close] error: $error');
    }
  }  
}
