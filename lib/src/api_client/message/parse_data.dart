import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Extracting `payload` part from the input bytes
class ParseData implements MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> {
  final _log = const Log('ParseData');
  final MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> _field;
  final Bytes _buf = [];
  _Value? _value;
  ///
  /// # Returns ParseData new instance
  /// - **in case of Receiving**
  ///   - [field] - is [ParseSize]
  ParseData({
    required MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> field,
  }) :
    _field = field;
  ///
  /// Returns `payload` extracted from the input bytes
  /// - [input] input bytes, can be passed multiple times, until required payload length is riched
  @override
  Option<(FieldId, FieldKind, FieldSize, Bytes)> parse(Bytes input) {
    final value = _value;
    if (value == null) {
      return switch (_field.parse(input)) {
        Some(value: (FieldId id, FieldKind kind, FieldSize size, Bytes bytes)) => () {
          _value = _Value(id, kind, size);
          if (bytes.length >= size.size) {
            _buf.addAll(bytes.sublist(0, size.size)); 
            _log.debug('.parse | bytes: $bytes');
            reset();
            return Some((id, kind, size, _buf));
          } else {
            _buf.addAll(bytes); 
            return None();
          }
        }() as Option<(FieldId, FieldKind, FieldSize, Bytes)>,
        None() => () {
          return None();
        }(),
      };
    } else {
      return switch (_field.parse(input)) {
        Some(value: (FieldId _, FieldKind _, FieldSize _, Bytes bytes)) => () {
          if ((_buf.length + bytes.length) >= value.size.size) {
            if (_buf.length < value.size.size) {
              final remainder = value.size.size - _buf.length;
              _buf.addAll(bytes.sublist(0, remainder));
            }
            reset();
            return Some((value.id, value.kind, value.size, _buf));
          } else {
            _buf.addAll(bytes);
            return None();
          }
        }() as Option<(FieldId, FieldKind, FieldSize, Bytes)>,
          None() => () {
            return None();
        }(),
      };
    }
  }
  //
  //
  @override
  void reset() {
    _field.reset();
    // _buf.clear();
    _value = null;
  }
}
///
/// Just contains received kind & size
class _Value {
  final FieldId id;
  final FieldKind kind;
  final FieldSize size;
  _Value(this.id, this.kind, this.size);
}