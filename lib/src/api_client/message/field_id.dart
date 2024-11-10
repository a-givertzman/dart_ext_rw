import 'dart:typed_data';

import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// Used as unique identifier of the `Message`
class FieldId {
  final Log _log = Log('FieldId');
  final int _len;
  final int _id;
  final Endian _endian;
  ///
  /// Returns FieldId new instance
  /// - len the length of the field `Id` in bytes
  /// - endian - ordeting of bytes in the field `Size`:
  ///   - `Endian.big      [00, 00, 00, 01] -> 1`
  ///   - `Endian.little   [01, 00, 00, 00] -> 1`
  FieldId(int id, {int len = 4, Endian endian = Endian.big}):
    _len = len,
    _endian = endian,
    _id = id;
  ///
  /// Returns FieldId new instance
  /// - With default `len = 4 bytes`
  /// - With default `endian = Endian.big`
  FieldId.def():
    _len = 4,
    _endian =  Endian.big,
    _id = 0;
  ///
  /// Returns ho;ding `Id`
  int get id => _id;
  ///
  /// Returns bytes of specified [id] specified [len]
  Uint8List get toBytes => Uint8List(_len)..buffer.asByteData().setInt32(0, _id, _endian);
  ///
  /// Returns length of the field `Size` in the bytes
  int get len => _len;
  ///
  /// Returns `Id` built from bytes
  Result<int, Failure> fromBytes(List<int> bytes) {
    if (bytes.length >= _len) {
      _log.debug('.from | bytes: $bytes');
      final lst = Uint8List(_len)..setAll(0, bytes);
      final id = lst.buffer.asByteData().getInt32(0, _endian);
      return Ok(id);
    }
    return Err(Failure(message: 'FieldId.from | input bytes length less then specified $_len', stackTrace: StackTrace.current));
  }
  //
  //
  @override
  String toString() {
    return 'FieldId{ id: $_id, len: $_len }';
  }
  //
  //
  @override
  bool operator ==(Object other) {
    return (other is FieldId) && (_len == other.len) && (_id == other.id) && (_endian == other._endian);
  }
  //
  //
  @override
  int get hashCode => Object.hash(_endian, _id, _len);
}
