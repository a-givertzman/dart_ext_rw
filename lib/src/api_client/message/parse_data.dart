import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
// import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Extracting `payload` part from the input bytes
class ParseData implements MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> {
  // final _log = const Log('ParseData');
  final MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> _field;
  Bytes _buf = [];
  Bytes _remains = [];
  ///
  /// # Returns ParseData new instance
  /// - **in case of Receiving**
  ///   - [field] - is [ParseSize]
  ParseData({
    required MessageParse<Bytes, Option<(FieldId, FieldKind, FieldSize, Bytes)>> field,
  }) :
    _field = field;
  ///
  /// Returns `payload` extracted from the input bytes
  /// - [input] input bytes, can be passed multiple times, until required payload length is riched
  @override
  Option<(FieldId, FieldKind, FieldSize, Bytes)> parse(Bytes? input) {
    final Bytes all = [..._remains, ...input ?? []];
    _remains.clear();
    switch (_field.parse(all)) {
      case Some(value: (FieldId id, FieldKind kind, FieldSize size, Bytes buf)):
        final bytes = [..._buf, ...buf];
        _buf.clear();
        if (bytes.length >= size.size) {
          // _log.debug('.parse | bytes: $bytes');
          if (bytes.length > size.size) {
            // _log.debug('.parse | remaining: ${bytes.sublist(size.size)}');
            _remains = bytes.sublist(size.size);
          }
          _field.reset();
          return Some((id, kind, size, bytes.sublist(0, size.size)));
        } else {
          _buf = bytes;
          return None();
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
  }
}
