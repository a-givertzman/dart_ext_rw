import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
///
class ParseKind implements MessageParse<List<int>, Option<(FieldKind, List<int>)>> {
  final MessageParse<dynamic, Option<List<int>>> _field;
  FieldKind? _kind;
  ///
  ///
  ParseKind({required MessageParse<dynamic, Option<List<int>>> field}) : _field = field;
  //
  //
  @override
  Option<(FieldKind, List<int>)> parse(List<int> input) {
    final kind_ = _kind;
    if (kind_ == null) {
      switch (_field.parse(input)) {
        case Some(value :final bytes):
          final raw = bytes.firstOrNull;
          if (raw != null) {
            return switch (FieldKind.from(raw)) {
              Ok<FieldKind, Failure>(:final value) => () {
                _kind = value;
                return Some((value, bytes.sublist(1)));
              }() as Option<(FieldKind, List<int>)>,
              Err<FieldKind, Failure>() => () {
                return None();
              }(),
            };
          } else {
            return None();
          }
        case None():
          return None();
      }
    } else {
      return Some((kind_, input));
    }
  }
}
