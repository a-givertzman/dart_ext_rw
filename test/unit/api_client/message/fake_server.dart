import 'dart:io';
import 'dart:typed_data';

import 'package:ext_rw/src/api_client/message/field_const.dart';
import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/find_fixed.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_fixed.dart';
import 'package:ext_rw/src/api_client/message/parse_sized.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';

///
/// Fake socket server
class Server {
  final _log = Log('Server');
  final String host;
  final int port;
  final int syn;
  ///
  /// Fake socket server
  Server(this.host, this.port, this.syn);
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
                bool keepGo = true;
                while (remains.isNotEmpty && keepGo) {
                  switch (message.parse(remains.takeBytes())) {
                    case Some<(((((Null, Null), FieldId), FieldKind), FieldSize), Bytes, Bytes)>(  value: (((((null, null), FieldId id), FieldKind kind), FieldSize size), Bytes bytes, Bytes remainder)  ):
                      remains.add(remainder);
                    // case Some<(FieldId, FieldKind, FieldSize, Bytes)>(value: (final id, final kind, final size, final bytes)):
                      _log.debug('.listen.onData | Parsed | id: $id,  kind: $kind,  size: $size, bytes: $bytes');
                      final reply = messageBuild.build(bytes, id: id.id);
                      Future.delayed(Duration(milliseconds: 300), () {
                        socket.add(reply);
                      });
                      _log.debug('.listen.onData | Microtask started');
                    case None():
                      _log.debug('.listen.onData | Parsed | None');
                      keepGo = false;
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
