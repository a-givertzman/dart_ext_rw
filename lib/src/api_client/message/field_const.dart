import 'dart:typed_data';

import 'package:ext_rw/src/api_client/message/message_parse.dart';
///
/// Constant `Field` has the same bytes for the entire `Message` lifetime
class FieldConst {
  // final Log _log = Log('FieldConst');
  final int _len;
  final num _val;
  final Endian _endian;
  /// Bytes representation of the specified `val`
  final Bytes bytes;
  ///
  /// Returns [FieldConst] new instance
  /// - `val` - Numeric value to be converted into the bytes
  /// - `len` The length of the field in bytes
  /// - `bytes` - Bytes representation of the specified `val`
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst(int val, int len, this.bytes, {Endian endian = Endian.little}):
    _len = len,
    _endian = endian,
    _val = val;
  ///
  /// Returns [FieldConst] new instance from u8 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromU8(int val, {Endian endian = Endian.little}):
    _len = 1,
    _endian = endian,
    _val = val,
    bytes = Uint8List(1)..buffer.asByteData().setUint8(0, val);
  ///
  /// Returns [FieldConst] new instance from u16 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromU16(int val, {Endian endian = Endian.little}):
    _len = 2,
    _endian = endian,
    _val = val,
    bytes = Uint8List(2)..buffer.asByteData().setUint16(0, val, endian);
  ///
  /// Returns [FieldConst] new instance from u32 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromU32(int val, {Endian endian = Endian.little}):
    _len = 4,
    _endian = endian,
    _val = val,
    bytes = Uint8List(4)..buffer.asByteData().setUint32(0, val, endian);
  ///
  /// Returns [FieldConst] new instance from u64 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromU64(int val, {Endian endian = Endian.little}):
    _len = 8,
    _endian = endian,
    _val = val,
    bytes = Uint8List(8)..buffer.asByteData().setUint64(0, val, endian);
  ///
  /// Returns [FieldConst] new instance from i8 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromI8(int val, {Endian endian = Endian.little}):
    _len = 1,
    _endian = endian,
    _val = val,
    bytes = Uint8List(1)..buffer.asByteData().setInt8(0, val);
  ///
  /// Returns [FieldConst] new instance from i16 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromI16(int val, {Endian endian = Endian.little}):
    _len = 2,
    _endian = endian,
    _val = val,
    bytes = Uint8List(2)..buffer.asByteData().setInt16(0, val, endian);
  ///
  /// Returns [FieldConst] new instance from i32 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromI32(int val, {Endian endian = Endian.little}):
    _len = 4,
    _endian = endian,
    _val = val,
    bytes = Uint8List(4)..buffer.asByteData().setInt32(0, val, endian);
  ///
  /// Returns [FieldConst] new instance from i64 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromI64(int val, {Endian endian = Endian.little}):
    _len = 8,
    _endian = endian,
    _val = val,
    bytes = Uint8List(8)..buffer.asByteData().setInt64(0, val, endian);

  ///
  /// Returns [FieldConst] new instance from f32 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromf32(double val, {Endian endian = Endian.little}):
    _len = 4,
    _endian = endian,
    _val = val,
    bytes = Uint8List(4)..buffer.asByteData().setFloat32(0, val, endian);
  ///
  /// Returns [FieldConst] new instance from i64 value
  /// - `endian` - Word ordeting, default `Endian.little`
  FieldConst.fromF64(double val, {Endian endian = Endian.little}):
    _len = 8,
    _endian = endian,
    _val = val,
    bytes = Uint8List(8)..buffer.asByteData().setFloat64(0, val, endian);
  ///
  /// Returns value as Int
  num get val => _val;
  ///
  /// Returns length of the field in bytes
  int get len => _len;
  //
  //
  @override
  String toString() {
    return 'FieldConst{ val: $_val, len: $_len, endian: $_endian, bytes: ${bytes.map((n) => n.toString().padLeft(2, '0')).toList()} }';
  }
  //
  //
  @override
  bool operator ==(Object other) {
    return (other is FieldConst) 
        && (_len == other._len)
        && (_val == other._val)
        && (_endian == other._endian)
        && (bytes == other.bytes);
  }
  //
  //
  @override
  int get hashCode => Object.hash(_val, bytes);
}
