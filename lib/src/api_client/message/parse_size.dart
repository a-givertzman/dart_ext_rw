import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
///
class ParseSize implements MessageParse<List<int>, Option<(FieldKind, FieldSize, List<int>)>> {
  final MessageParse<dynamic, Option<(FieldKind, List<int>)>> _field;
  List<int> _buf = [];
  final FieldSize _confSize;
  int? _size;
  FieldKind? _kind;
  ///
  ///
  ParseSize({
    required FieldSize size,
    required MessageParse<dynamic, Option<(FieldKind, List<int>)>> field,
  }) :
    _confSize = size,
    _field = field;
  //
  //
  @override
  Option<(FieldKind, FieldSize, List<int>)> parse(List<int> bytes) {
    final size_ = _size;
    if (size_ == null) {
      switch (_field.parse([..._buf, ...bytes])) {
        case Some(value: (FieldKind kind, List<int> input)):
          _kind = kind;
          if (input.length >= _confSize.len) {
            return switch (_confSize.from(input.sublist(0, _confSize.len))) {
              Ok(value:final size) => () {
                _size = size;
                _buf.clear();
                return Some((kind, FieldSize(len: size), input.sublist(_confSize.len)));
              }() as Option<(FieldKind, FieldSize, List<int>)>,
              Err() => () {
                _buf = input;
                return None();
              }(),
            };
          } else {
            _buf = input;
            return None();
          }
        case None():
          return None();
      }
    } else {
      return Some((_kind!, FieldSize(len: size_), bytes));
    }
  }
}
