import 'dart:typed_data';

import 'package:hmi_core/hmi_core_failure.dart';
// import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Used as `size` in bytes of the `data` stored in the `Message`
class FieldSize {
  // final Log _log = Log('FieldSize');
  final int _size;
  final int _len;
  final Endian _endian;
  ///
  /// Returns FieldSize new instance
  /// - len the length of the field `Size` in bytes
  /// - endian - ordeting of bytes in the field `Size`:
  ///   - `Endian.big      [00, 00, 00, 01] -> 1`
  ///   - `Endian.little   [01, 00, 00, 00] -> 1`
  FieldSize(int size, {int len = 4, Endian endian = Endian.big}):
    _size = size,
    _len = len,
    _endian = endian;
  ///
  /// Returns FieldSize new instance
  /// - With default `len = 4 bytes`
  /// - With default `endian = Endian.big`
  FieldSize.def():
    _size = 0,
    _len = 4,
    _endian =  Endian.big;
  ///
  /// Returns holding size
  int get size => _size;
  ///
  /// Returns bytes of specified [size] of specified [len]
  Uint8List get toBytes => Uint8List(_len)..buffer.asByteData().setUint32(0, _size, _endian);
  ///
  /// Returns length of the field `Size` in the bytes
  int get len => _len;
  ///
  /// Returns `Size` built from bytes
  Result<int, Failure> fromBytes(List<int> bytes) {
    if (bytes.length >= _len) {
      // _log.debug('.from | bytes: $bytes');
      final lst = Uint8List(_len)..setAll(0, bytes);
      final size = lst.buffer.asByteData().getInt32(0, _endian);
      return Ok(size);
    }
    return Err(Failure(message: 'FieldSize.from | input bytes length less then specified $_len', stackTrace: StackTrace.current));
  }
}
