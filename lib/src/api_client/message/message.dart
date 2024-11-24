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
  final Socket _socket;
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
  Message(Socket socket) :
    _socket = socket;
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
      (Uint8List event) {
        // _log.debug('.listen.onData | Event: $event');
        Uint8List? input = event;
        bool isSome = true;
        while (isSome) {
          switch (message.parse(input)) {
            case Some<(FieldId, FieldKind, FieldSize, Bytes)>(value: (final id, final kind, final size, final bytes)):
              _log.debug('.listen.onData | id: $id,  kind: $kind,  size: $size, bytes: $bytes');
              _controller.add((id, kind, bytes));
              input = null;
            case None():
              isSome = false;
              _log.debug('.listen.onData | None');
          }
        }
      },
      onError: (err) {
        _log.error('.listen.onError | Error: $err');
        _subscription?.cancel();
        _socket.close();
      },
      onDone: () {
        _log.warning('.listen.onDone | Done');
        _subscription?.cancel();
        _socket.close();
      },
    );
    return _controller.stream;
  }
  ///
  /// Sends bytes as built [Message] to the specified `socket`
  void add(id, Bytes bytes) {
    final message = _messageBuild.build(bytes, id: id);
    _socket.add(message);
  }
  ///
  /// Close the [stream] and `socket`
  Future<void> close() async {
    try {
      await _subscription?.cancel();
      await _socket.close();
    } catch (error) {
      _log.warning('[.close] error: $error');
    }

  }
}
