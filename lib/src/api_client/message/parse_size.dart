import 'dart:typed_data';

import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Extracting `size` part from the input bytes
class ParseSize implements MessageParse<Bytes, Option<(FieldKind, FieldSize, Bytes)>> {
  final MessageParse<dynamic, Option<(FieldKind, Bytes)>> _field;
  final BytesBuilder _buf = BytesBuilder();
  final FieldSize _confSize;
  int? _size;
  FieldKind? _kind;
  ///
  /// # Returns ParseSize new instance
  /// - **in case of Receiving**
  ///   - [field] - is [ParseKind]
  ParseSize({
    required FieldSize size,
    required MessageParse<Bytes, Option<(FieldKind, Bytes)>> field,
  }) :
    _confSize = size,
    _field = field;
  ///
  /// Returns message `Kind`, `Size` extracted from the input and the remaining bytes
  /// - [input] - input bytes, can be passed multiple times
  /// - if `Size` is not detected: returns None
  /// - if `Size` is detected: returns `Kind`, `Size` and all bytes following the `Size`
  @override
  Option<(FieldKind, FieldSize, Bytes)> parse(Bytes bytes) {
    final size_ = _size;
    if (size_ == null) {
      _buf.add(bytes);
      switch (_field.parse(_buf)) {
        case Some(value: (FieldKind kind, Bytes input)):
          _kind = kind;
          if (input.length >= _confSize.len) {
            return switch (_confSize.from(input.sublist(0, _confSize.len))) {
              Ok(value:final size) => () {
                _size = size;
                _buf.clear();
                return Some((kind, FieldSize(size), input.sublist(_confSize.len)));
              }() as Option<(FieldKind, FieldSize, Bytes)>,
              Err() => () {
                // _buf.add(input);  //  = input;
                return None();
              }(),
            };
          } else {
            // _buf = input;
            return None();
          }
        case None():
          return None();
      }
    } else {
      return Some((_kind!, FieldSize(size_), bytes));
    }
  }
}
