import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
import 'package:web_socket/web_socket.dart';

part 'any_socket_tcp.dart';
part 'any_socket_web.dart';
part 'any_socket.dart';
///
/// Extracting `id`, `kind` and `payload` parts from the socket stream
/// 
/// Usage:
/// 
/// ```dart
/// final message = Message(
///   await Socket.connect(host, port),
/// );
/// message.stream.listen(
///   (event) {
///     final (FieldId id, FieldKind kind, Bytes bytes) = event;
///     final text = String.fromCharCodes(bytes);
///     print('onData | id: $id,  kind: $kind,  text: $text');
///   },
///   onError: (err) {
///     print('onError | Error: $err');
///     message.close();
///   },
///   onDone: () {
///     print('onDone | Done');
///     message.close();
///   },
/// );
class Message<T> {
  final _log = Log('Message');
  final StreamController<T> _controller = StreamController();
  final _AnySocket _socket;
  late StreamSubscription? _subscription;
  final MessageParse<T> _messageParse;
  final MessageBuild _messageBuild = MessageBuild(
    syn: FieldSyn.def(),
    id: FieldId.def(),
    kind: FieldKind.bytes,
    size: FieldSize.def(),
    data: FieldData([]),
  );
  ///
  /// Extracting `id`, `kind` and `payload` parts from the socket stream
  /// - by default [Socket] expected,
  /// - to have [WebSocket] use `Message.web`
  Message(Socket socket, {MessageParse<(FldIn, FldOut), Out, Bytes>? parse}) :
    _socket = _AnySocketRaw(socket),
    _messageParse = parse ?? _DefaultMessageParse();
    // ParseSized(
    //   size: (_, fldOut) => (fldOut as FieldSize).size,
    //   fromBytes: (Bytes bytes) => bytes as Out,
    //   field: ParseFixed<((Null, Null), FieldId), FieldKind, FieldSize>(           // Field (u32) Size
    //     size: 4,
    //     fromBytes: (Bytes bytes) => switch (FieldSize(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
    //       Ok(:final value) => Ok(FieldSize(value)),
    //       Err() => Err(null),
    //     },
    //     field: ParseFixed<(Null, Null), FieldId, FieldKind>(                      // Field (u8) Kind 
    //       size: 1,
    //       fromBytes: (Bytes bytes) => switch (FieldKind.from(bytes[0])) {
    //         Ok(:final value) => Ok(value),
    //         Err() => Err(null),
    //       },
    //       field: ParseFixed<Null, Null, FieldId>(                                 // Field (u32) Id
    //         size: 4,
    //         fromBytes: (Bytes bytes) => switch (FieldId(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
    //           Ok(:final value) => Ok(FieldId(value)),
    //           Err() => Err(null),
    //         },
    //         field: FindFixed.fromBytes([FieldSyn.def().syn]),                     // Field (u8) SYN
    //         ),
    //     ),
    //   ) as MessageParse<FldIn, FldOut, Bytes>
    // );
  ///
  /// Extracting `id`, `kind` and `payload` parts from the web-socket stream
  Message.web(WebSocket socket, {MessageParse<(FldIn, FldOut), Out, Bytes>? parse}) :
    _socket = _AnySocketWeb(socket),
    _messageParse = parse ?? _DefaultMessageParse();

  ///
  /// Returns a stream providing the extracted results
  Stream<(FldIn, FldOut, Out)> get stream {
    final message = _messageParse;
    final remains = BytesBuilder(copy: true);
    _subscription = _socket.listen(
      (List<int> event) {
        // _log.debug('.listen.onData | Event: $event');
        remains.add(event);
        bool keepGo = true;
        while (remains.isNotEmpty && keepGo) {
          switch (message.parse(remains.takeBytes())) {
            case Some<((FldIn, FldOut), Out, Bytes)>(value: ((FldIn fldIn, FldOut fldOut), Out out, Bytes remainder)):
            // case Some<(((((Null, Null), FieldId), FieldKind), FieldSize), Bytes, Bytes)>(value: (((((null, null), FieldId id), FieldKind kind), FieldSize size), Bytes bytes, Bytes remainder)):
              // _log.debug('.listen.onData | id: $id,  kind: $kind,  size: $size, bytes: ${bytes.length > 16 ? bytes.sublist(0, 16) : bytes}');
              _log.debug('.listen.onData | fldIn: $fldIn,  fldOut: $fldOut,  out: $out,  remainder: ${remainder.length > 16 ? remainder.sublist(0, 16) : remainder}');
              remains.add(remainder);
              _controller.add((fldIn, fldOut, out));
            case None():
              // _log.debug('.listen.onData | None');
              keepGo = false;
          }
        }
      },
      onError: (err) async {
        // _log.error('.listen.onError | Error: $err');
        await Future.wait([
          _subscription?.cancel() ?? Future.value(),
          _socket.close(),
          _controller.close(),
        ]);
        return err;
      },
      onDone: () async {
        // _log.debug('.listen.onDone | Done');
        await Future.wait([
          _subscription?.cancel() ?? Future.value(),
          _socket.close(),
          _controller.close(),
        ]);
      },
    );
    return _controller.stream;
  }
  ///
  /// Sends bytes as built [Message] to the specified `socket`
  void add(int id, Bytes bytes) {
    // _log.debug('.add | id: $id,  bytes: ${bytes.length > 16 ? bytes.sublist(0, 16) : bytes}');
    final message = _messageBuild.build(bytes, id: id);
    _socket.add(message);
  }
  ///
  /// Returns a [Future] that completes once all buffered data is accepted by the underlying [StreamConsumer].
  /// 
  /// This method must not be called while an [addStream] is incomplete.
  /// 
  /// NOTE: This is not necessarily the same as the data being flushed by the operating system.
  Future<dynamic> flush() {
    return _socket.flush();
  }
  ///
  /// Close the [stream] and `socket`
  Future<void> close() async {
    try {
      await Future.wait([
        _subscription?.cancel() ?? Future.value(),
        _socket.close(),
        _controller.close(),
      ]);
    } catch (error) {
      _log.warning('.close | error: $error');
    }

  }
}
class _DefaultMessageParse implements MessageParse<(FieldId, FieldKind), Bytes, Bytes> {
  final MessageParse<(((Null, Null), FieldId), FieldKind), FieldSize, Bytes> _parse = ParseSized(
    size: (_, fldOut) => (fldOut as FieldSize).size,
    fromBytes: (Bytes bytes) => bytes,
    field: ParseFixed<((Null, Null), FieldId), FieldKind, FieldSize>(           // Field (u32) Size
      size: 4,
      fromBytes: (Bytes bytes) => switch (FieldSize(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
        Ok(:final value) => Ok(FieldSize(value)),
        Err() => Err(null),
      },
      field: ParseFixed<(Null, Null), FieldId, FieldKind>(                      // Field (u8) Kind 
        size: 1,
        fromBytes: (Bytes bytes) => switch (FieldKind.from(bytes[0])) {
          Ok(:final value) => Ok(value),
          Err() => Err(null),
        },
        field: ParseFixed<Null, Null, FieldId>(                                 // Field (u32) Id
          size: 4,
          fromBytes: (Bytes bytes) => switch (FieldId(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
            Ok(:final value) => Ok(FieldId(value)),
            Err() => Err(null),
          },
          field: FindFixed.fromBytes([                                          // Field (u8) SYN
            FieldSyn.def().syn
          ]),
        ),
      ),
    ),
  );
  //
  @override
  Option<((FldIn, FldOut), Out, Bytes)> parse(Bytes input) {
    return _parse.parse(input);
  }
  //
  @override
  void reset() {
    _parse.reset();
  }
}