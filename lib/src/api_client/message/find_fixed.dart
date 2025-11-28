import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Extracting some identifier symbol from the input bytes
/// - Used to identify a start of the message for example
class FindFixed implements MessageParse<Bytes, Option<Bytes>> {
  final FieldSyn _val;
  Option _value = None();
  ///
  /// Returns [FindFixed] new instance
  /// - [val] - some bytes to be searched in the message,
  FindFixed({
    required FieldSyn val,
  }): _val = val;
  ///
  /// Returns specified SYN value
  int get syn => _val.syn;
  ///
  /// Returns Ok if `Syn` parsed or Err
  @override
  Option<Bytes> parse(Bytes bytes) {
    switch (_value) {
      case Some():
        return Some(bytes);
      case None():
        final pos = bytes.indexWhere((b) => b == _val.syn);
        if (pos >= 0) {
          _value = Some(null);
          return Some(bytes.sublist(pos + 1));
        } else {
          return None();
        }
    }
  }
  //
  //
  @override
  void reset() {
    _value = None();    
  }
}
