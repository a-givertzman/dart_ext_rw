import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ext_rw/src/api_client/message/field_const.dart';
import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/find_fixed.dart';
import 'package:ext_rw/src/api_client/message/message.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/parse_fixed.dart';
import 'package:ext_rw/src/api_client/message/parse_sized.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// setup constants
const int syn = 22;
const restart = true;
const keepGo = false;
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
///
/// Fake socket server
class Server {
  final _log = Log('Server');
  final String host;
  final int port;
  ///
  /// Fake socket server
  Server(this.host, this.port);
  ///
  /// Starting server on the specified [host]:[port] address
  Future start() {
    return ServerSocket.bind(host, port).then(
      (server) {
        _log.debug('.bind | SocketServer ready on: ${server.address}');
        server.listen(
          (socket) {
            _log.debug('.listen | Connection on: ${socket.address}');
            final message = ParseSized(
              size: (_, FieldSize size) => size.size,
              fromBytes: (Bytes bytes) => bytes,
              field: ParseFixed<((Null, Null), FieldId), FieldKind, FieldSize>(
                size: 4,
                fromBytes: (Bytes bytes) => switch (FieldSize(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
                  Ok(:final value) => Ok(FieldSize(value)),
                  Err() => Err(null),
                },
                field: ParseFixed<(Null, Null), FieldId, FieldKind>(
                  size: 1,
                  fromBytes: (Bytes bytes) => switch (FieldKind.from(bytes[0])) {
                    Ok(:final value) => Ok(value),
                    Err() => Err(null),
                  },
                  field: ParseFixed<Null, Null, FieldId>(
                    size: 4,
                    fromBytes: (Bytes bytes) => switch (FieldId(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
                      Ok(:final value) => Ok(FieldId(value)),
                      Err() => Err(null),
                    },
                    field: FindFixed(FieldConst.fromU8(syn)),
                    ),
                ),
              ),
            );
            final messageBuild = MessageBuild(
              syn: FieldSyn.def(),
              id: FieldId.def(),
              kind: FieldKind.bytes,
              size: FieldSize.def(),
              data: FieldData([]),
            );
            final remains = BytesBuilder(copy: true);
            socket.listen(
              (event) {
                // _log.debug('.listen.onData | event (${event.length}): $event');
                remains.add(event);
                // _log.debug('.listen.onData | input (${input?.length}): $input');
                switch (message.parse(remains.takeBytes())) {
                  case Some<(((((Null, Null), FieldId), FieldKind), FieldSize), Bytes, Bytes)>(  value: (((((null, null), FieldId id), FieldKind kind), FieldSize size), Bytes bytes, Bytes remainder)  ):
                    remains.add(remainder);
                  // case Some<(FieldId, FieldKind, FieldSize, Bytes)>(value: (final id, final kind, final size, final bytes)):
                    _log.debug('.listen.onData | Parsed | id: $id,  kind: $kind,  size: $size, bytes: $bytes');
                    Future.delayed(Duration(milliseconds: 500), () {
                      final reply = messageBuild.build(bytes, id: id.id);
                      socket.add(reply);
                    });
                    _log.debug('.listen.onData | Microtask started');
                  case None():
                    _log.debug('.listen.onData | Parsed | None');
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
/// Testing [Message]
void main() {
  Log.initialize(level: LogLevel.all);
  final log = Log('Test:Message');
  group('Message.parse', () {
    ///
    ///
    test('.socket()', () async {
      final (host, port) = ('127.0.0.1', 5061);
      Server(host, port).start();
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
      final request = FakeRequest(
        Message(socket),
      );
      List<Future> replies = [];
      final target = 100
      final time = Stopwatch()..start();
      for (final i in Iterable.generate(target)) {
        final reply = request.fetch('$query$i').then(
          (reply) {
            log.info('.request.fetch | reply: $reply');
            log.info('.request.fetch | reply text: ${String.fromCharCodes(reply)}');
          },
          onError: (err) {
            log.error('.request.fetch.onError | Error: $err');
            socket.close();
          },
        );
        replies.add(reply);
      }
      log.info(' | Waiting for ${replies.length} requests being finished...');
      for (final (i, reply) in replies.indexed) {
        await reply;
        log.info(' | Request $i of ${replies.length} finished');
      }
      // await Future.wait(replies);
      log.info('.request | Elapsed: ${time.elapsed}');
      request.close();
    });
    ///
    ///
    test('.parse()', () async {
      final parseSized = ParseSized(
        size: (_, FieldSize size) => size.size,
        fromBytes: (Bytes bytes) => bytes,
        field: ParseFixed<((Null, Null), FieldId), FieldKind, FieldSize>(
          size: 4,
          fromBytes: (Bytes bytes) => switch (FieldSize(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
            Ok(:final value) => Ok(FieldSize(value)),
            Err() => Err(null),
          },
          field: ParseFixed<(Null, Null), FieldId, FieldKind>(
            size: 1,
            fromBytes: (Bytes bytes) => switch (FieldKind.from(bytes[0])) {
              Ok(:final value) => Ok(value),
              Err() => Err(null),
            },
            field: ParseFixed<Null, Null, FieldId>(
              size: 4,
              fromBytes: (Bytes bytes) => switch (FieldId(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
                Ok(:final value) => Ok(FieldId(value)),
                Err() => Err(null),
              },
              field: FindFixed(FieldConst.fromU8(syn)),
              ),
          ),
        ),
      );
      final List<(int, bool, List<int>, Option<(FieldId, FieldKind, int)>, List<int>)> testData = [
        (01,  keepGo, [ 11,  12, syn, 00, 00, 00, 11, 02, 00], None(                       ), []),
        (02,  keepGo, [ 00,  00,  02, 25, 26], Some((FieldId(11), FieldKind.bytes,   2)), [25, 26]),
        (03, restart, [ 31, syn,  00, 00, 00, 12, 02, 00, 00], None(                       ), []),
        (04, restart, [ 00,  03,  44, 45, 46], None(                       ), []),
        (05,  keepGo, [syn,  00,  00, 00, 13, 02,  00, 00, 00], None(                       ), []),
        (06,  keepGo, [ 04,  62,  63, 64, 65], Some((FieldId(13), FieldKind.bytes,   4)), [62,  63, 64, 65]),
        (07, restart, [syn,  00,  00, 00, 14, 02,  00, 00, 00], None(                       ), []),
        (08,  keepGo, [ 10,  62,  63, 64, 65], None(                       ), []),
        (09,  keepGo, [ 66,  67,  68, 69, 70], None(                       ), []),
        (09,  keepGo, [ 71                  ], Some((FieldId(14), FieldKind.bytes,  10)), [62, 63, 64, 65, 66, 67, 68, 69, 70, 71]),
        (10, restart, [syn,  00,  00, 00, 15, 02,  00, 00, 01], None(                       ), []),
        (11,  keepGo, [ 132,  62,  63, 64, 65], None(                       ), []),
        (12,  keepGo, [ 66,  67,  68, 69, 70], None(                       ), []),
        (13,  keepGo, [ 71,  72,  73, 74, 75], None(                       ), []),
        (14,  keepGo, [for(var i=76; i<=255; i+=1) i], None(                ), []),
        (14,  keepGo, [for(var i=254; i>=64; i-=1) i], None(                ), []),
        (15,  keepGo, [63, 62, 61        ], Some((FieldId(15), FieldKind.bytes,  388)), [...[for(var i=62; i<=255; i+=1) i], ...[for(var i=254; i>=61; i-=1) i]]),
      ];
      final remains = BytesBuilder(copy: true);
      for (final (step, restart, bytes, target, targetBytes) in testData) {
        log.debug('.parse | step: $step,  targetBytes.length: ${targetBytes.length}');
        if (restart) {
          parseSized.reset();
        }
        remains.add(bytes);
        switch (parseSized.parse(remains.takeBytes())) {
          case Some<(((((Null, Null), FieldId), FieldKind), FieldSize), Bytes, Bytes)>(  value: (((((null, null), FieldId id), FieldKind kind), FieldSize size), Bytes result, Bytes remainder)  ):
            remains.add(remainder);
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
              listEquals(result, targetBytes),
              true,
              reason: 'step $step \n result: $result \n target: $targetBytes',
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
