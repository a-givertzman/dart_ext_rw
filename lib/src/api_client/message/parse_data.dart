import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Extracting `payload` part from the input bytes
class ParseData implements MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> {
  final MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> _field;
  final Bytes _buf = [];
  _KindAndSize? _kindSize;
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
    final kindSize = _kindSize;
    if (kindSize == null) {
      return switch (_field.parse(input)) {
        Some(value: (FieldId id, FieldKind kind, FieldSize size, Bytes bytes)) => () {
          _kindSize = _KindAndSize(id, kind, size);
          if (bytes.length >= size.len) {
            _buf.addAll(bytes.sublist(0, size.len)); 
            return Some((id, kind, size, _buf));
          } else {
            _buf.addAll(bytes); 
            return None();
          }
        }() as Option<(FieldId, FieldKind, FieldSize, Bytes)>,
        None() => () {
          // _buf = input;
          return None();
        }(),
      };
    } else {
      return switch (_field.parse(input)) {
        Some(value: (FieldId _, FieldKind _, FieldSize _, Bytes bytes)) => () {
          if ((_buf.length + bytes.length) >= kindSize.size.size) {
            if (_buf.length < kindSize.size.size) {
              final remainder = kindSize.size.size - _buf.length;
              _buf.addAll(bytes.sublist(0, remainder));
            }
            return Some((kindSize.id, kindSize.kind, kindSize.size, _buf));
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
}
///
/// Just contains received kind & size
class _KindAndSize {
  final FieldId id;
  final FieldKind kind;
  final FieldSize size;
  _KindAndSize(this.id, this.kind, this.size);
}