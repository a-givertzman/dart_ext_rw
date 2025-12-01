import 'package:ext_rw/src/api_client/message/field_const.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:flutter/foundation.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Searches & Extracts some `Key` symbol from the input bytes
/// - Used to identify a start of the message for example
class FindFixed implements MessageParse<Bytes, Option<Bytes>> {
  final FieldConst _field;
  Option _value = None();
  ///
  /// Returns [FindFixed] new instance
  /// - [val] - some `Key` to be searched in the message,
  FindFixed({
    required FieldConst val,
  }): _field = val;
  // ///
  // /// Returns specified field value
  // int get val => _field.val;
  ///
  /// Returns Ok if `Key` found and parsed or Err
  @override
  Option<Bytes> parse(Bytes bytes) {
    switch (_value) {
      case Some():
        return Some(bytes);
      case None():
        final first = _field.bytes.firstOrNull;
        if (first != null) {
          final pos = bytes.indexWhere((b) => b == first);
          if (pos >= 0) {
            if (_field.bytes.length > 1) {
              final end = pos + _field.bytes.length;
              if (listEquals(bytes.sublist(pos, end), _field.bytes)) {
                _value = Some(null);
                return Some(bytes.sublist(end));
              }
            } else {
              _value = Some(null);
              return Some(bytes.sublist(pos + 1));
            }
          }
        }
        return None();
    }
  }
  //
  //
  @override
  void reset() {
    _value = None();    
  }
}
