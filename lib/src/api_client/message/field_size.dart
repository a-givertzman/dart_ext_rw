import 'dart:typed_data';

import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Used as `size` in bytes of the `data` stored in the `Message`
class FieldSize {
  final Log _log = Log('FieldSize');
  final int _len;
  ///
  /// Returns FieldSize new instance
  /// - By default field `Size` is 4 bytes
  /// - [] length of the field `Size` in the bytes
  FieldSize({int len = 4}):
    _len = len;
  ///
  /// Returns [length] as bytes of specified [len]
  Uint8List size(int length) => Uint8List(_len)..buffer.asByteData().setInt32(0, length, Endian.big);
  ///
  /// Returns length of the field `Size` in the bytes
  int get len => _len;
  ///
  /// Returns Ok(FieldKind) if parsed
  Result<int, Failure> from(List<int> bytes) {
    _log.debug('.from | bytes: $bytes');
    final lst = Uint8List(_len)..setAll(0, bytes);
    final len = lst.buffer.asByteData().getInt32(0, Endian.big);
    return Ok(len);
  }
}
