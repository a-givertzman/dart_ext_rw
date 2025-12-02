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
class Message {
  final _log = Log('Message');
  final StreamController<(FieldId, FieldKind, Bytes)> _controller = StreamController();
  final _AnySocket _socket;
  late StreamSubscription? _subscription;
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
  Message(Socket socket) :
    _socket = _AnySocketRaw(socket);
  ///
  /// Extracting `id`, `kind` and `payload` parts from the web-socket stream
  Message.web(WebSocket socket) :
    _socket = _AnySocketWeb(socket);
  ///
  /// Returns a stream providing the extracted results
  Stream<(FieldId, FieldKind, Bytes)> get stream {
    final message = ParseSized(
      size: (_, FieldSize size) => size.size,
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
            field: FindFixed.fromBytes([FieldSyn.def().syn]),                     // Field (u8) SYN
            ),
        ),
      ),
    );
    final remains = BytesBuilder(copy: true);
    _subscription = _socket.listen(
      (List<int> event) {
        // _log.debug('.listen.onData | Event: $event');
        remains.add(event);
        switch (message.parse(remains.takeBytes())) {
          case Some<(((((Null, Null), FieldId), FieldKind), FieldSize), Bytes, Bytes)>(value: (((((null, null), FieldId id), FieldKind kind), FieldSize size), Bytes bytes, Bytes remainder)):
            // _log.debug('.listen.onData | id: $id,  kind: $kind,  size: $size, bytes: ${bytes.length > 16 ? bytes.sublist(0, 16) : bytes}');
            _log.debug('.listen.onData | id: ${id.id},  kind: $kind,  size: ${size.size}, remainder: ${remainder.length > 16 ? remainder.sublist(0, 16) : remainder}');
            remains.add(remainder);
            _controller.add((id, kind, bytes));
          case None():
            final _ = null;
            // _log.debug('.listen.onData | None');
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
  void flush() {
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
///
/// Switch [Socket] or [WebSocket]
abstract class _AnySocket {
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });
  ///
  /// Adds byte [data] to the associated socket.
  void add(List<int> data);
  ///
  /// Returns a [Future] that completes once all buffered data is accepted by the underlying [StreamConsumer].
  /// 
  /// This method must not be called while an [addStream] is incomplete.
  ///
  /// NOTE: This is not necessarily the same as the data being flushed by the operating system.
  void flush();
  ///
  /// Closes associated socket
  Future<dynamic> close();
}
///
/// Wrapping a standart socket
class _AnySocketRaw implements _AnySocket {
  final _log = Log('_AnySocketRaw');
  final Socket _socket;
  ///
  ///
  _AnySocketRaw(Socket socket):
    _socket = socket;
  ///
  ///
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _log.debug('.listen | ...');
    return _socket.listen(onData, onError: onError, onDone: onDone);
  }
  ///
  /// Adds byte [data] to the target consumer, ignoring [encoding].
  /// 
  /// The [encoding] does not apply to this method, and the [data] list is passed directly to the target consumer as a stream event.
  /// 
  /// This method must not be called when a stream is currently being added using [addStream].
  /// 
  /// This operation is non-blocking. See [flush] or [done] for how to get any errors generated by this call.
  /// 
  /// The data list should not be modified after it has been passed to add because it is not defined whether the target consumer will receive the list in the original or modified state.
  /// 
  /// Individual values in [data] which are not in the range 0 .. 255 will be truncated to their low eight bits, as if by [int.toUnsigned], before being used.
  @override
  void add(data) {
    return _socket.add(data);
  }
  ///
  /// Returns a [Future] that completes once all buffered data is accepted by the underlying [StreamConsumer].
  /// 
  /// This method must not be called while an [addStream] is incomplete.
  /// 
  /// NOTE: This is not necessarily the same as the data being flushed by the operating system.
  @override
  Future<dynamic> flush() {
    return _socket.flush();
  }
  ///
  /// Close the target consumer.
  /// 
  /// NOTE: Writes to the [IOSink] may be buffered, and may not be flushed by a call to close(). To flush all buffered writes, call flush() before calling close().
  /// 
  /// Copied from IOSink.
  @override
  Future<dynamic> close() {
    return _socket.close();
  }
}
///
/// Wrapping a web socket
class _AnySocketWeb implements _AnySocket {
  final _log = Log('_AnySocketWeb');
  final WebSocket _socket;
  ///
  ///
  _AnySocketWeb(WebSocket socket):
    _socket = socket;
  ///
  ///
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _log.debug('.listen | ...');
    return _socket.events
      .where((WebSocketEvent event) {
        switch (event) {
          case BinaryDataReceived():
            return true;
          // case CloseReceived():
            // _log.debug('.listen | CloseReceived: $code');
            // return true;
          default:
            return false;
        }
      })
      .map<List<int>>((event) {
        switch (event) {
          case TextDataReceived(:final text):
            _log.warn('.listen | TextDataReceived - not supported for now \n\t$text');
          case BinaryDataReceived(:final data):
            // _log.trace('.listen | BinaryDataReceived \n\t$data');
            return data;
          // case CloseReceived(:final code):
          //   _log.debug('.listen | CloseReceived: $code');
          default:
        }
        return [];
      })
      .listen(
        (event) {
          // _log.trace('.listen | event: $event');
          onData?.call(event);
        },
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
  }
  ///
  /// Sends binary data to the connected peer.
  /// 
  /// Throws [WebSocketConnectionClosed] if the [WebSocket] is closed (either through [close] or by the peer).
  /// 
  /// Data sent through [sendBytes] will be silently discarded if the peer is disconnected but the disconnect has not yet been detected.
  @override
  void add(data) {
    return _socket.sendBytes(Uint8List.fromList(data));
  }
  ///
  /// Do nothing for the web socket
  @override
  Future<dynamic> flush() {
    return Future.value(null);
  }
  ///
  /// Closes the WebSocket connection and the [events] Stream.
  /// 
  /// Sends a Close frame to the peer. If the optional [code] and [reason] arguments are given, they will be included in the Close frame. If no [code] is set then the peer will see a 1005 status code. If no [reason] is set then the peer will not receive a reason string.
  /// 
  /// Throws an [ArgumentError] if [code] is not 1000 or in the range 3000-4999.
  /// 
  /// Throws an [ArgumentError] if [reason] is longer than 123 bytes when encoded as UTF-8
  /// 
  /// Throws [WebSocketConnectionClosed] if the connection is already closed (including by the peer).
  @override
  Future<dynamic> close() {
    return _socket.close();
  }
}
