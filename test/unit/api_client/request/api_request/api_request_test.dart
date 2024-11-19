import 'dart:io';

import 'package:ext_rw/ext_rw.dart';
import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_data.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/parse_id.dart';
import 'package:ext_rw/src/api_client/message/parse_kind.dart';
import 'package:ext_rw/src/api_client/message/parse_size.dart';
import 'package:ext_rw/src/api_client/message/parse_syn.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';

import 'fake_query_type.dart';
///
/// setup constants
const int syn = 22;
const restart = true;
const keepGo = false;
///
/// Fake socket server
class FakeServer {
  final _log = Log('Server');
  final String host;
  final int port;
  ///
  /// Fake socket server
  FakeServer(this.host, this.port);
  ///
  /// Starting server on the specified [host]:[port] address
  Future start() {
    return ServerSocket.bind(host, port).then(
      (server) {
        _log.debug('.bind | SocketServer ready on: ${server.address}');
        server.listen(
          (socket) {
            _log.debug('.listen | Connection on: ${socket.address}');
            final message = ParseData(
              field: ParseSize(
                size: FieldSize.def(),
                field: ParseKind(
                  field: ParseId(
                  id: FieldId.def(),
                    field: ParseSyn.def(),
                  ),
                ),
              ),
            );
            final messageBuild = MessageBuild(
              syn: FieldSyn.def(),
              id: FieldId.def(),
              kind: FieldKind.string,
              size: FieldSize.def(),
              data: FieldData([]),
            );
            socket.listen(
              (event) {
                // _log.debug('.listen.onData | event (${event.length}): $event');
                Uint8List? input = event;
                bool isSome = true;
                while (isSome) {
                  // _log.debug('.listen.onData | input (${input?.length}): $input');
                  switch (message.parse(input)) {
                    case Some<(FieldId, FieldKind, FieldSize, Bytes)>(value: (final id, final kind, final size, final bytes)):
                      _log.debug('.listen.onData | Parsed | id: $id,  kind: $kind,  size: $size, bytes: $bytes');
                      Future.delayed(Duration(milliseconds: 500), () {
                        final reply = messageBuild.build(bytes, id: id.id);
                        socket.add(reply);
                      });
                      _log.debug('.listen.onData | Microtask started');
                      input = null;
                    case None():
                      _log.debug('.listen.onData | Parsed | None');
                      isSome = false;
                  }
                }
              },
              onError: (err) {
                _log.error('.listen.onError | Error: $err');
              },
              onDone: () {
                _log.debug('.listen.onDone | Done');
              },
            );
          },
          onError: (err) {
            _log.error('.listen.onError | Error: $err');
            server.close();
          },
          onDone: () {
            _log.debug('.listen.onDone | Done');
            server.close();
          },
        );
      },
      onError: (err) {
        _log.error('.bind.onError | Error: $err');
      },
    );
  }
}
///
/// Testing [ParseData].parse
void main() {
  Log.initialize(level: LogLevel.all);
  final log = Log('Test:ApiRequest');
  group('ApiRequest.fetch', () {
    ///
    ///
    test('.socket()', () async {
      final (host, port) = ('127.0.0.1', 5061);
      FakeServer(host, port).start();
      log.debug('.Client.connect | Start connect...');
      Future<Socket> connect() async {
        Socket? socket;
        int connectionErr = 0;
        while (socket == null) {
          socket = await Socket.connect(host, port)
            .timeout(Duration(seconds: 3), onTimeout: () {
                log.error('.Client.connect | Timeout error');          
                throw Exception('.Client.connect | Timeout error');
            })
            .then(
              (s) => s,
                onError: (err) {
                  if (connectionErr++ >= 3) {
                    log.error('.Client.connect.onError | Error: $err');
                    throw Exception('.Client.connect | Timeout error');
                  }
                  log.warning('.Client.connect.onError | Error: $err');
              },
            );
        }
        return socket;
      }
      final socket = await connect();
      log.debug('.Client.connect | Socket connected on: ${socket.address}');
      List<Future> replies = [];
      final time = Stopwatch()..start();
      final request = ApiRequest(
        address: ApiAddress(host: host, port: port),
        authToken: '***token***',
        query: FakeApiQueryType(valid: true, query: ''),
        
      );
      for (final i in Iterable.generate(100)) {
        final query = FakeApiQueryType(valid: true, query: 'Client.Request$i');
        final reply = request.fetchWith(query).then(
          (reply) {
            log.info('.request.fetch | reply: $reply');
            // log.info('.request.fetch | reply text: ${String.fromCharCodes(reply)}');
          },
          onError: (err) {
            log.error('.request.fetch.onError | Error: $err');
            socket.close();
          },
        );
        replies.add(reply);
      }
      await Future.wait(replies);
      log.info('.request | All (${replies.length}) replies finished');
      log.info('.request | Elapsed: ${time.elapsed}');
    });
  });
}