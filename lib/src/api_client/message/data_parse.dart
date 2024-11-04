import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
// ignore: implementation_imports
import 'package:hmi_core/src/core/option/option.dart';
// ignore: implementation_imports
import 'package:hmi_core/src/core/result_new/result.dart';
///
///
class DataParse implements MessageParse<void> {
  final MessageParse<int> _field;
  List<int> _buf = [];
  int? _size;
  ///
  ///
  DataParse({
    required MessageParse<int> field,
  }) :
    _field = field;
  //
  //
  @override
  (Option<void>, List<int>) parse(List<int> bytes) {
    final size_ = _size;
    if (size_ == null) {
      final (size, input) = _field.parse(bytes);
      return switch (size) {
        Some(:final value) => () {
          _size = value;
          if (input.length >= value) {
            _buf.addAll(input.sublist(0, value)); 
            return (Some(null), _buf);
          } else {
            _buf.addAll(input); 
            return (None(), <int>[]);
          }
        }() as (Option<void>, List<int>),
        None() => () {
          _buf = input;
          return (None(), <int>[]);
        }(),
      };
    } else {
      final (_, input) = _field.parse(bytes);
      if ((_buf.length + input.length) >= size_) {
        if (_buf.length < size_) {
          final remainder = size_ - _buf.length;
          _buf.addAll(input.sublist(0, remainder));
        }
        return (Some(null), _buf);
      } else {
        _buf.addAll(input);
        return (None(), <int>[]);
      }
    }
  }
}
