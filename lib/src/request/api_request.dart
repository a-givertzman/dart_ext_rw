import 'dart:convert';
import 'dart:io';

import 'package:dart_api_client/src/core/api_query_type/api_query_type.dart';
import 'package:dart_api_client/src/core/entities/api_address.dart';
import 'package:dart_api_client/src/reply/api_reply.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';


class ApiRequest {
  static final _log = const Log('ApiRequest')..level = LogLevel.info;
  final ApiAddress _address;
  final ApiQueryType _query;
  ///
  ApiRequest({
    required ApiAddress address,
    required ApiQueryType sqlQuery,
  }) :
    _address = address,
    _query = sqlQuery;
  ///
  /// sends created request to the remote
  /// returns reply if exists
  Future<Result<ApiReply>> fetch() async {
    final query = _query.buildJson();
    final bytes = utf8.encode(query);
    return Socket.connect(_address.host, _address.port, timeout: const Duration(seconds: 3))
      .then((socket) async {
        return _send(socket, bytes)
          .then((result) {
            return result.fold(
              onData: (_) {
                return _read(socket).then((result) {
                  return result.fold(
                    onData: (bytes) {
                      return Result<ApiReply>(
                        data: ApiReply.fromJson(
                          utf8.decode(bytes),
                        ),
                      );
                    }, 
                    onError: (err) {
                      return Result<ApiReply>(error: err);
                    },
                  );
                });
              }, 
              onError: (err) {
                return Future.value(
                  Result<ApiReply>(error: err),
                );
              },
            );
          });
      })
      .catchError((error) {
          return Result<ApiReply>(
            error: Failure.connection(
              message: '.fetch | socket error: $error', 
              stackTrace: StackTrace.current,
            ),
          );
      });
  }
  ///
  Future<Result<List<int>>> _read(Socket socket) async {
    try {
      List<int> message = [];
      final subscription = socket
        .timeout(
          const Duration(milliseconds: 500),
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
      return Result(data: message);
    } catch (error) {
      _log.warning('._read | socket error: $error');
      await _closeSocket(socket);
      return Result(
        error: Failure.connection(
          message: '._read | socket error: $error', 
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
  ///
  Future<Result<bool>> _send(Socket socket, List<int> bytes) async {
    try {
      socket.add(bytes);
      return Future.value(const Result(data: true));
    } catch (error) {
      _log.warning('._send | socket error: $error');
      return Result(
        error: Failure.connection(
          message: '._send | socket error: $error', 
          stackTrace: StackTrace.current,
        ),
      );
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