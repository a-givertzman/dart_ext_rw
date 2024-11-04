import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Used to build / parse a start of the message
class SynParse implements MessageParse<void> {
  final FieldSyn _syn;
  int _start = -1;
  ///
  /// Returns SynParse new instance
  SynParse({
    required FieldSyn syn,
  }): _syn = syn;
  ///
  /// Returns SynParse new instance
  /// - With default `Start` symbol SYN = 22
  SynParse.def():
    _syn = FieldSyn.def();
  ///
  /// Returns specified SYN value
  int get syn => _syn.syn;
  ///
  /// Returns Ok if `Syn` parsed or Err
  @override
  (Option<void>, List<int>) parse(List<int> bytes) {
    if (_start < 0) {
      _start = bytes.indexWhere((b) => b == _syn.syn);
      if (_start >= 0) {
        return (Some(null), bytes.sublist(_start + 1));
      } else {
        return (None(), []);
      }
    } else {
        return (Some(null), bytes);
    }
  }
}
