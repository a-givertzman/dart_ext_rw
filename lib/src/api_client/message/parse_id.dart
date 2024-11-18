import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Extracting `Id` part from the input bytes
class ParseId implements MessageParse<Bytes, Option<(FieldId, Bytes)>> {
  final _log = const Log('ParseId');
  final MessageParse<Bytes, Option<Bytes>> _field;
  final FieldId _confId;
  Bytes _buf = [];
  Option<FieldId> _value = None();
  ///
  /// # Returns ParseId new instance
  /// - **in case of Receiving**
  ///   - [field] - is [ParseSyn]
  ParseId({
    required FieldId id,
    required MessageParse<Bytes, Option<Bytes>> field,
  }) :
    _confId = id,
    _field = field;
  ///
  /// Returns message `Id` extracted from the input and the remaining bytes
  /// - [input] - input bytes, can be passed multiple times
  /// - if `Id` is not detected: returns None
  /// - if `Id` is detected: returns `Id` and all bytes following the `Id`
  @override
  Option<(FieldId, Bytes)> parse(Bytes input) {
    final buf = [..._buf, ...input];
    _buf.clear();
    switch (_field.parse(buf)) {
      case Some(value: Bytes bytes):
        switch (_value) {
          case Some<FieldId>(:final value):
            return Some((value, bytes));
          case None():
            if (bytes.length >= _confId.len) {
              return switch (_confId.fromBytes(bytes.sublist(0, _confId.len))) {
                Ok(value: final id) => () {
                  _value = Some(FieldId(id));
                  _log.debug('.parse | bytes: $bytes');
                  return Some((FieldId(id), bytes.sublist(_confId.len)));
                }() as Option<(FieldId, Bytes)>,
                Err() => () {
                  _buf = bytes;
                  return None();
                }(),
              };
            } else {
              _buf = bytes;
              return None();
            }
        }
      case None():
        return None();
    }
  }
  //
  //
  @override
  void reset() {
    _field.reset();
    _buf.clear();
    _value = None();
  }
}
