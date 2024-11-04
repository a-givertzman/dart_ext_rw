import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
// ignore: implementation_imports
import 'package:hmi_core/src/core/error/failure.dart';
// ignore: implementation_imports
import 'package:hmi_core/src/core/option/option.dart';
// ignore: implementation_imports
import 'package:hmi_core/src/core/result_new/result.dart';
///
///
class KindParse implements MessageParse<FieldKind> {
  final MessageParse _field;
  FieldKind? _kind;
  ///
  ///
  KindParse({required MessageParse field}) : _field = field;
  //
  //
  @override
  (Option<FieldKind>, List<int>) parse(List<int> bytes) {
    final kind_ = _kind;
    if (kind_ == null) {
      final (start, input) = _field.parse(bytes);
      switch (start) {
        case Some():
          final raw = input.firstOrNull;
          if (raw != null) {
            return switch (FieldKind.from(raw)) {
              Ok<FieldKind, Failure>(:final value) => () {
                _kind = value;
                return (Some(value), input.sublist(1));
              }() as (Option<FieldKind>, List<int>),
              Err<FieldKind, Failure>() => () {
                return (None(), <int>[]);
              }(),
            };
          } else {
            return (None(), []);
          }
        case None():
          return (None(), []);
      }
    } else {
      return (Some(kind_), bytes);
    }
  }
}
