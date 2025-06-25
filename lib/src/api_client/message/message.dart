import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_data.dart';
import 'package:ext_rw/src/api_client/message/parse_id.dart';
import 'package:ext_rw/src/api_client/message/parse_kind.dart';
import 'package:ext_rw/src/api_client/message/parse_size.dart';
import 'package:ext_rw/src/api_client/message/parse_syn.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
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
  /// Extracting `id`, `kind` and `payload` parts from the socket stream
  Message.web(WebSocket socket) :
    _socket = _AnySocketWeb(socket);
  ///
  /// Returns a stream providing the extracted results
  Stream<(FieldId, FieldKind, Bytes)> get stream {
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
      _subscription = _socket.listen(
        (List<int> event) {
          // _log.debug('.listen.onData | Event: $event');
          List<int>? input = event;
          bool isSome = true;
          while (isSome) {
            switch (message.parse(input)) {
              case Some<(FieldId, FieldKind, FieldSize, Bytes)>(value: (final id, final kind, final _, final bytes)):
                // _log.debug('.listen.onData | id: $id,  kind: $kind,  size: $size, bytes: ${bytes.length > 16 ? bytes.sublist(0, 16) : bytes}');
                _controller.add((id, kind, bytes));
                input = null;
              case None():
                isSome = false;
                // _log.debug('.listen.onData | None');
            }
          }
        },
        onError: (err) async {
          _log.error('.listen.onError | Error: $err');
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
  ///
  Future<dynamic> close();
}
///
/// Wrapping a standart socket
class _AnySocketRaw implements _AnySocket {
  final _log = Log('_AnySocketRaw');
  // final Socket? _socketRaw;
  // final WebSocket? _socketWeb;
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
  /// Adds byte [data] to the associated socket.
  @override
  void add(data) {
    return _socket.add(data);
  }
  ///
  ///
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
            _log.debug('.listen | TextDataReceived - not supported for now \n\t$text');
          case BinaryDataReceived(:final data):
            _log.trace('.listen | BinaryDataReceived \n\t$data');
            return data;
          case CloseReceived(:final code):
            _log.debug('.listen | CloseReceived: $code');
        }
        return [];
      })
      .listen(
        (event) {
          _log.trace('.listen | event: $event');
          onData?.call(event);
        },
        onError: onError,
        onDone: onDone,
      );
  }
  ///
  /// Adds byte [data] to the associated socket.
  @override
  void add(data) {
    return _socket.sendBytes(Uint8List.fromList(data));
    // return _socket.add(data);
  }
  ///
  ///
  @override
  Future<dynamic> close() {
    return _socket.close();
  }
}
