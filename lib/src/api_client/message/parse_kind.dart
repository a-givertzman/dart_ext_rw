import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Extracting `kind` part from the input bytes
class ParseKind implements MessageParse<Bytes, Option<(FieldId, FieldKind, Bytes)>> {
  final MessageParse<Bytes, Option<(FieldId, Bytes)>> _field;
  _Value? _value;
  ///
  /// # Returns ParseKind new instance
  /// - **in case of Receiving**
  ///   - [field] - is [ParseSyn]
  ParseKind({
    required MessageParse<Bytes, Option<(FieldId, Bytes)>> field,
  }) : _field = field;
  ///
  /// Returns message `Kind` extracted from the input and the remaining bytes
  /// - [input] - input bytes, can be passed multiple times
  /// - if `Kind` is not detected: returns None
  /// - if `Kind` is detected: returns `Kind` and all bytes following the `Kind`
  @override
  Option<(FieldId, FieldKind, Bytes)> parse(Bytes input) {
    final value = _value;
    if (value == null) {
      switch (_field.parse(input)) {
        case Some(value : (final FieldId id, final Bytes bytes)):
          final raw = bytes.firstOrNull;
          if (raw != null) {
            return switch (FieldKind.from(raw)) {
              Ok<FieldKind, Failure>(value: final kind) => () {
                _value = _Value(id, kind);
                return Some((id, kind, bytes.sublist(1)));
              }() as Option<(FieldId, FieldKind, Bytes)>,
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
      return Some((value.id, value.kind, input));
    }
  }
  //
  //
  @override
  void reset() {
    _field.reset();
    _value = null;
  }
}
///
/// Just holds received id & kind
class _Value {
  final FieldId id;
  final FieldKind kind;
  _Value(this.id, this.kind);
}
