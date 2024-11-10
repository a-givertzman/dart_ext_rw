import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Extracting `SYN` symbol from the input bytes
/// - Used to identify a start of the message
class ParseSyn implements MessageParse<Bytes, Option<Bytes>> {
  final FieldSyn _syn;
  int _start = -1;
  ///
  /// Returns ParseSyn new instance
  /// - [syn] - some byte identyfies a start of the message,
  /// - By default 22 can be used
  ParseSyn({
    required FieldSyn syn,
  }): _syn = syn;
  ///
  /// Returns ParseSyn new instance
  /// - With default `Start` symbol SYN = 22
  ParseSyn.def():
    _syn = FieldSyn.def();
  ///
  /// Returns specified SYN value
  int get syn => _syn.syn;
  ///
  /// Returns Ok if `Syn` parsed or Err
  @override
  Option<Bytes> parse(Bytes bytes) {
    if (_start < 0) {
      _start = bytes.indexWhere((b) => b == _syn.syn);
      if (_start >= 0) {
        return Some(bytes.sublist(_start + 1));
      } else {
        return None();
      }
    } else {
        return Some(bytes);
    }
  }
}
