import 'package:ext_rw/src/api_client/message/field_const.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:flutter/foundation.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Searches & Extracts some `Key` symbol from the input bytes
/// - Used to identify a start of the message for example
class FindFixed implements MessageParse<Null, Null, Bytes> {
  final List<int> _bytes;
  Option _value = None();
  ///
  /// Returns [FindFixed] new instance
  /// - [val] - some `Key` to be searched in the message,
  FindFixed(
    FieldConst val,
  ): _bytes = val.bytes;
  ///
  /// Returns [FindFixed] new instance
  /// - [val] - some `Key` to be searched in the message,
  FindFixed.fromBytes(
    List<int> bytes,
  ): _bytes = bytes;
  ///
  /// Returns Ok if `Key` found and parsed or Err
  @override
  Option<(Null, Null, Bytes)> parse(Bytes bytes) {
    switch (_value) {
      case Some():
        return Some((null, null, bytes));
      case None():
        final first = _bytes.firstOrNull;
        if (first != null) {
          final pos = bytes.indexWhere((b) => b == first);
          if (pos >= 0) {
            if (_bytes.length > 1) {
              final end = pos + _bytes.length;
              if (listEquals(bytes.sublist(pos, end), _bytes)) {
                _value = Some(null);
                return Some((null, null, bytes.sublist(end)));
              }
            } else {
              _value = Some(null);
              return Some((null, null, bytes.sublist(pos + 1)));
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
