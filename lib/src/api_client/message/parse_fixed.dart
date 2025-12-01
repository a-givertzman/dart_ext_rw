import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Extracting field of fixed size from the input bytes
class ParseFixed<FldIn, FldOut, Out> implements MessageParse<(FldIn, FldOut), Out, Bytes> {
  // final _log = const Log('ParseSized');
  final int _size;
  final Result<Out, Null> Function(Bytes) _fromBytes;
  final MessageParse<FldIn, FldOut, Bytes> _field;
  Bytes _buf = [];
  Option<Out> _value = None();
  ///
  /// # Returns [ParseFixed] new instance
  /// - [size] - bytes to be parsed into [Out] type
  /// - [fromBytes] - converts bytes into [Out] type
  /// - [field] - child field, the previous in the message structure
  ParseFixed({
    required int size,
    required Result<Out, Null> Function(Bytes) fromBytes,
    required MessageParse<FldIn, FldOut, Bytes> field,
  }) :
    _size = size,
    _fromBytes = fromBytes,
    _field = field;
  ///
  /// Returns message `Id`, `Kind`, `Size` extracted from the input and the remaining bytes
  /// - [input] - input bytes, can be passed multiple times
  /// - if `Size` is not detected: returns None
  /// - if `Size` is detected: returns `Kind`, `Size` and all bytes following the `Size`
  @override
  Option<((FldIn, FldOut), Out, Bytes)> parse(Bytes input) {
    final buf = [..._buf, ...input];
    _buf.clear();
    switch (_field.parse(buf)) {
      case Some(value: (FldIn passIn, FldOut passOut, Bytes bytes)):
        switch (_value) {
          case Some<Out>(value: final val):
            return Some(((passIn, passOut), val, bytes));
          case None():
            if (bytes.length >= _size) {
              switch (_fromBytes(bytes.sublist(0, _size))) {
                case Ok(value:final val):
                  _value = Some(val);
                  // _log.debug('.parse | bytes: $bytes');
                  return Some(((passIn, passOut), val, bytes.sublist(_size)));
                case Err():
                  _buf = bytes;
                  return None();
              }
            }
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
    _value = None();
  }
}
