import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message.dart';
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
///
/// setup constants
const int syn = 22;
const restart = true;
const keepGo = false;
///
///
class Request {
  final _log = Log('Request');
  final Map<int, StreamController<Bytes>> _fetches = {};
  final Message _message;
  int id = 0;
  ///
  ///
  Request(Message message):
    _message = message {
    _message.stream.listen(
      (event) {
        final (FieldId id, FieldKind kind, Bytes bytes) = event;
        _log.debug('.listen.onData | Event | id: $id,  kind: $kind,  bytes: $bytes');
        if (_fetches.containsKey(id.id)) {
          final m = _fetches[id.id];
          if (m != null) {
            m.add(bytes);
            m.close();
            _fetches.remove(id.id);
          }
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
    final newId = id++;
    if (!_fetches.containsKey(newId)) {
      _log.debug('.fetch | id: $id,  sql: $sql');
      final StreamController<Bytes> controller = StreamController();
      _fetches[newId] = controller;
      final bytes = utf8.encode(sql);
      _message.add(id, bytes);
      return controller.stream.first;
    }
    throw Exception('.fetch | Duplicated id: $id');
  }
  ///
  ///
  Future close() {
    return _message.close();
  }
}
///
/// Testing [ParseData].parse
void main() {
  Log.initialize(level: LogLevel.all);
  final log = Log('Test:Message');
  group('Message.parse', () {
    ///
    ///
    test('.socket()', () async {
      final (host, port) = ('127.0.0.1', 5061);
      ServerSocket.bind(host, port).then(
        (server) {
          log.debug('.Server.bind | SocketServer ready on: ${server.address}');
          server.listen(
            (socket) {
              log.debug('.Server.listen | Connection on: ${socket.address}');
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
                  log.debug('.ServerSocket.listen.onData | event (${event.length}): $event');
                  bool isSome = true;
                  while (isSome) {
                    switch (message.parse(event)) {
                      case Some<(FieldId, FieldKind, FieldSize, Bytes)>(value: (final id, final kind, final size, final bytes)):
                        log.debug('.ServerSocket.listen.onData | id: $id,  kind: $kind,  size: $size, bytes: $bytes');
                        sleep(Duration(milliseconds: 300));
                        final reply = messageBuild.build(bytes, id: id.id);
                        socket.add(reply);
                      case None():
                        isSome = false;
                    }
                    event = Uint8List(0);
                  }
                },
                onError: (err) {
                  log.error('.ServerSocket.listen.onError | Error: $err');
                },
                onDone: () {
                  log.debug('.ServerSocket.listen.onDone | Done');
                },
              );
            },
            onError: (err) {
              log.error('.Server.listen.onError | Error: $err');
              server.close();
            },
            onDone: () {
              log.debug('.Server.listen.onDone | Done');
              server.close();
            },
          );
        },
        onError: (err) {
          log.error('.Server.bind.onError | Error: $err');
        },
      );
      sleep(Duration(milliseconds: 100));
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
                  log.error('.Client.connect.onError | Error: $err');
              },
            );
        }
        return socket;
      }
      final socket = await connect();
      log.debug('.Client.connect | Socket connected on: ${socket.address}');
      final query = 'Client.Request';
      final request = Request(
        Message(socket),
      );
      List<Future> replies = [];
      for (final _ in Iterable.generate(3)) {
        final reply = request.fetch(query).then(
          (reply) {
            log.debug('.request.fetch | reply: $reply');
          },
          onError: (err) {
            log.error('.request.fetch.onError | Error: $err');
            socket.close();
          },
        );
        replies.add(reply);
      }
      await Future.wait(replies);
      request.close();
    });
    ///
    ///
    test('.parse()', () async {
      ParseData parseData = ParseData(
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
      final List<(int, bool, List<int>, Option<(FieldId, FieldKind, int)>, List<int>)> testData = [
        (01,  keepGo, [ 11,  12, syn, 00, 00, 00, 11, 40, 00], None(                       ), []),
        (02,  keepGo, [ 00,  00,  02, 25, 26], Some((FieldId(11), FieldKind.string,   2)), [25, 26]),
        (03, restart, [ 31, syn,  00, 00, 00, 12, 40, 00, 00], None(                       ), []),
        (04, restart, [ 00,  03,  44, 45, 46], None(                       ), []),
        (05,  keepGo, [syn,  00,  00, 00, 13, 40,  00, 00, 00], None(                       ), []),
        (06,  keepGo, [ 04,  62,  63, 64, 65], Some((FieldId(13), FieldKind.string,   4)), [62,  63, 64, 65]),
        (07, restart, [syn,  00,  00, 00, 14, 40,  00, 00, 00], None(                       ), []),
        (08,  keepGo, [ 10,  62,  63, 64, 65], None(                       ), []),
        (09,  keepGo, [ 66,  67,  68, 69, 70], None(                       ), []),
        (09,  keepGo, [ 71                  ], Some((FieldId(14), FieldKind.string,  10)), [62, 63, 64, 65, 66, 67, 68, 69, 70, 71]),
        (10, restart, [syn,  00,  00, 00, 15, 40,  00, 00, 01], None(                       ), []),
        (11,  keepGo, [ 02,  62,  63, 64, 65], None(                       ), []),
        (12,  keepGo, [ 66,  67,  68, 69, 70], None(                       ), []),
        (13,  keepGo, [ 71,  72,  73, 74, 75], None(                       ), []),
        (14,  keepGo, [for(var i=76; i<=316; i+=1) i], None(                ), []),
        (15,  keepGo, [317, 318, 319        ], Some((FieldId(15), FieldKind.string,  258)), [for(var i=62; i<=319; i+=1) i]),
      ];
      for (final (step, restart, bytes, target, targetBytes) in testData) {
        log.debug('.parse | step: $step,  targetBytes.length: ${targetBytes.length}');
        if (restart) {
          parseData = ParseData(
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
        }
        switch (parseData.parse(bytes)) {
          case Some(value: (FieldId id, FieldKind kind, FieldSize size, Bytes resultBytes)):
            final targetId = target.unwrap().$1;
            final targetKind = target.unwrap().$2;
            final targetSize = target.unwrap().$3;
            expect(
              target,
              isA<Some>(),
              reason: 'step: $step \n result: Some() \n target: $target',
            );
            expect(
              id,
              targetId,
              reason: 'step: $step \n result: $id \n target: $targetId',
            );
            expect(
              kind,
              targetKind,
              reason: 'step: $step \n result: $kind \n target: $targetKind',
            );
            expect(
              size.size,
              targetSize,
              reason: 'step: $step \n result: ${size.size} \n target: $targetSize',
            );
            expect(
              listEquals(resultBytes, targetBytes),
              true,
              reason: 'step: $step \n result: $resultBytes \n target: $targetBytes',
            );
          case None():
            expect(
              target,
              isA<None>(),
              reason: 'step: $step \n result: None() \n target: $target',
            );
        }
      }
    });
  });
}
