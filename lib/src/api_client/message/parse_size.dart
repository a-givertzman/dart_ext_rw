import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Extracting `size` part from the input bytes
class ParseSize implements MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> {
  final _log = const Log('ParseSize');
  final MessageParse<dynamic, Option<(FieldId, FieldKind, Bytes)>> _field;
  final FieldSize _confSize;
  Bytes _buf = [];
  _Value? _value;
  ///
  /// # Returns ParseSize new instance
  /// - **in case of Receiving**
  ///   - [field] - is [ParseKind]
  ParseSize({
    required FieldSize size,
    required MessageParse<Bytes, Option<(FieldId, FieldKind, Bytes)>> field,
  }) :
    _confSize = size,
    _field = field;
  ///
  /// Returns message `Id`, `Kind`, `Size` extracted from the input and the remaining bytes
  /// - [input] - input bytes, can be passed multiple times
  /// - if `Size` is not detected: returns None
  /// - if `Size` is detected: returns `Kind`, `Size` and all bytes following the `Size`
  @override
  Option<(FieldId, FieldKind, FieldSize, Bytes)> parse(Bytes input) {
    final buf = [..._buf, ...input];
    _buf.clear();
    switch (_field.parse(buf)) {
      case Some(value: (FieldId id, FieldKind kind, Bytes bytes)):
        final value = _value;
        if (value == null) {
          if (bytes.length >= _confSize.len) {
            return switch (_confSize.fromBytes(bytes.sublist(0, _confSize.len))) {
              Ok(value:final size) => () {
                _value = _Value(id, kind, FieldSize(size));
                _log.debug('.parse | bytes: $bytes');
                return Some((id, kind, FieldSize(size), bytes.sublist(_confSize.len)));
              }() as Option<(FieldId, FieldKind, FieldSize, Bytes)>,
              Err() => () {
                _buf = bytes;
                return None();
              }(),
            };
          } else {
            _buf = bytes;
            return None();
          }
        } else {
          return Some((value.id, value.kind, value.size, bytes));
        }
      case None():
        return None();
    }
  }
  //
  //
  @override
  void reset() {
    _field.reset();
    _buf.clear();
    _value = null;
  }
}
///
/// Just holds received id & kind
class _Value {
  final FieldId id;
  final FieldKind kind;
  final FieldSize size;
  _Value(this.id, this.kind, this.size);
}
