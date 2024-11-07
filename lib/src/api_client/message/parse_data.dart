import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
///
class ParseData implements MessageParse<Bytes, Option<(FieldKind, FieldSize, Bytes)>> {
  final MessageParse<Bytes, Option<(FieldKind, FieldSize, Bytes)>> _field;
  final Bytes _buf = [];
  int? _size;
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
    final size_ = _size;
    if (size_ == null) {
      return switch (_field.parse(bytes)) {
        Some(value: (FieldKind kind, FieldSize size, Bytes input)) => () {
          _size = size.len;
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
        Some(value: (FieldKind kind, FieldSize size, Bytes input)) => () {
          if ((_buf.length + input.length) >= size_) {
            if (_buf.length < size_) {
              final remainder = size_ - _buf.length;
              _buf.addAll(input.sublist(0, remainder));
            }
            return Some((kind, size, _buf));
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
