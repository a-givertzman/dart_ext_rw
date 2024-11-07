import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
///
class ParseData implements MessageParse<Bytes, Option<(FieldKind, FieldSize, Bytes)>> {
  final MessageParse<Bytes, Option<(FieldKind, FieldSize, Bytes)>> _field;
  final Bytes _buf = [];
  _KindAndSize? _kindSize;
  ///
  ///
  ParseData({
    required MessageParse<Bytes, Option<(FieldKind, FieldSize, Bytes)>> field,
  }) :
    _field = field;
  //
  //
  @override
  Option<(FieldKind, FieldSize, Bytes)> parse(Bytes bytes) {
    final kindSize = _kindSize;
    if (kindSize == null) {
      return switch (_field.parse(bytes)) {
        Some(value: (FieldKind kind, FieldSize size, Bytes input)) => () {
          _kindSize = _KindAndSize(kind, size.len);
          if (input.length >= size.len) {
            _buf.addAll(input.sublist(0, size.len)); 
            return Some((kind, size, _buf));
          } else {
            _buf.addAll(input); 
            return None();
          }
        }() as Option<(FieldKind, FieldSize, Bytes)>,
        None() => () {
          // _buf = input;
          return None();
        }(),
      };
    } else {
      return switch (_field.parse(bytes)) {
        Some(value: (FieldKind _, FieldSize _, Bytes input)) => () {
          if ((_buf.length + input.length) >= kindSize.size) {
            if (_buf.length < kindSize.size) {
              final remainder = kindSize.size - _buf.length;
              _buf.addAll(input.sublist(0, remainder));
            }
            return Some((kindSize.kind, FieldSize(len: kindSize.size), _buf));
          } else {
            _buf.addAll(input);
            return None();
          }
        }() as Option<(FieldKind, FieldSize, Bytes)>,
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
  final FieldKind kind;
  final int size;
  _KindAndSize(this.kind, this.size);
}