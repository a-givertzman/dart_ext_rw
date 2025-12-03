import 'dart:typed_data';

import 'package:ext_rw/src/api_client/message/message_parse.dart';
// import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// Extracting variable size `Field` from the input bytes
class ParseSized<FldIn, FldOut, Out> implements MessageParse<((FldIn, FldOut), Out, Bytes)> {
  // final _log = const Log('ParseSized');
  final int Function(FldIn, FldOut) _size;
  final Out Function(Bytes) _fromBytes;
  final MessageParse<(FldIn, FldOut, Bytes)> _field;
  /// `(In, Out, Size)`
  Option<(FldIn, FldOut, int)> _fieldVal;
  final _remains = BytesBuilder(copy: true);
  ///
  /// # Returns ParseSized new instance
  /// - [size] - closure returns bytes to be parsed into [Out] type
  /// - [fromBytes] - converts bytes of `size` into [Out] type
  /// - [field] - child field, the previous in the message structure
  ParseSized({
    required int Function(FldIn, FldOut) size,
    required Out Function(Bytes) fromBytes,
    required MessageParse<(FldIn, FldOut, Bytes)> field,
  }) :
    _size = size,
    _fromBytes = fromBytes,
    _field = field,
    _fieldVal = None();
  ///
  /// Returns `payload` extracted from the input bytes
  /// - [input] - input bytes, can be passed multiple times, until required payload size is riched
  /// - remains bytes will be returned in last argument of tuple in the result
  @override
  Option<((FldIn, FldOut), Out, Bytes)> parse(Bytes input) {
    _remains.add(input);
    switch (_fieldVal) {
      case Some<(FldIn, FldOut, int)>(:final value):
        final (fldIn, fldOut, size) = value;
        if (_remains.length >= size) {
          _fieldVal = None();
          final remains = _remains.takeBytes();
          // _log.debug('.parse | bytes: $bytes');
          // _log.debug('.parse | remaining: ${bytes.sublist(size.size)}');
          return Some(((fldIn, fldOut), _fromBytes(remains.sublist(0, size)), remains.sublist(size)));
        }
        return None();
      case None():
        switch (_field.parse(_remains.takeBytes())) {
          case Some(value: (FldIn fldIn, FldOut fldOut, Bytes remains)):
            _field.reset();
            final size = _size(fldIn, fldOut);
            if (remains.length >= size) {
              // _log.debug('.parse | bytes: $bytes');
              // _log.debug('.parse | remaining: ${bytes.sublist(size.size)}');
              return Some(((fldIn, fldOut), _fromBytes(remains.sublist(0, size)), remains.sublist(size)));
            } else {
              _fieldVal = Some((fldIn, fldOut, size));
              _remains.add(remains);
              return None();
            }
          case None():
            return None();
        }
    }
  }
  //
  //
  @override
  void reset() {
    _field.reset();
    _fieldVal = None();
    _remains.clear();
  }
}
