import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
// ignore: implementation_imports
import 'package:hmi_core/src/core/option/option.dart';
// ignore: implementation_imports
import 'package:hmi_core/src/core/result_new/result.dart';
///
///
class SizeParse implements MessageParse<int> {
  final MessageParse<FieldKind> _field;
  List<int> _buf = [];
  final FieldSize _conf;
  int? _size;
  ///
  ///
  SizeParse({
    required FieldSize size,
    required MessageParse<FieldKind> field,
  }) :
    _conf = size,
    _field = field;
  //
  //
  @override
  (Option<int>, List<int>) parse(List<int> bytes) {
    final size_ = _size;
    if (size_ == null) {
      final (start, input) = _field.parse([..._buf, ...bytes]);
      _buf.clear();
      switch (start) {
        case Some():
          if (input.length >= _conf.len) {
            return switch (_conf.from(input.sublist(0, _conf.len))) {
              Ok(:final value) => () {
                _size = value;
                return (Some(value), input.sublist(_conf.len));
              }() as (Option<int>, List<int>),
              Err() => () {
                _buf = input;
                return (None(), <int>[]);
              }(),
            };
          } else {
            _buf = input;
            return (None(), []);
          }
        case None():
          _buf = input;
          return (None(), []);
      }
    } else {
      return (Some(size_), bytes);
    }
  }
}
