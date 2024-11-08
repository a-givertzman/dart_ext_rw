import 'package:hmi_core/hmi_core_failure.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// - `Kind` of data
///     - 00, Any
///     - 01, Empty
///     - 02, Bytes
///     - 08, Bool
///     - 16, UInt16
///     - 17, UInt32
///     - 18, UInt64
///     - 24, Int16
///     - 25, Int32
///     - 26, Int64
///     - 32, F32
///     - 33, F64
///     - 40, String
///     - 48, Timestamp
///     - 49, Duration
///     - .., ...
enum FieldKind {
  any(0),
  empty(1),
  bytes(2),
  bool(8),
  uint16(16),
  uint32(17),
  uint64(18),
  int16(24),
  int32(25),
  int64(26),
  f32(32),
  f64(33),
  string(40),
  timestamp(48),
  duration(49);
  ///
  /// Returns FieldKind new instance
  const FieldKind(this._value);
  final int _value;
  ///
  int get kind => _value;
  ///
  /// Return specified length of field `Kind`
  int get len => 1;
  ///
  /// Returns Ok(FieldKind) if parsed
  static Result<FieldKind, Failure> from(int? val) {
    return switch (val) {
      0 => Ok(FieldKind.any),
      1 => Ok(FieldKind.empty),
      2 => Ok(FieldKind.bytes),
      8 => Ok(FieldKind.bool),
      16 => Ok(FieldKind.uint16),
      17 => Ok(FieldKind.uint32),
      18 => Ok(FieldKind.uint64),
      24 => Ok(FieldKind.int16),
      25 => Ok(FieldKind.int32),
      26 => Ok(FieldKind.int64),
      32 => Ok(FieldKind.f32),
      33 => Ok(FieldKind.f64),
      40 => Ok(FieldKind.string),
      48 => Ok(FieldKind.timestamp),
      49 => Ok(FieldKind.duration),
      _ => Err(Failure(message: 'FieldKind.fromBytes | Unknown Kind $val', stackTrace: StackTrace.current)),
    };
  }
  //
  //
  @override
  String toString() {
    return switch (this) {
      FieldKind.any => 'FieldKind.any',
      FieldKind.empty => 'FieldKind.empty',
      FieldKind.bytes => 'FieldKind.bytes',
      FieldKind.bool => 'FieldKind.bool',
      FieldKind.uint16 => 'FieldKind.uint16',
      FieldKind.uint32 => 'FieldKind.uint32',
      FieldKind.uint64 => 'FieldKind.uint64',
      FieldKind.int16 => 'FieldKind.int16',
      FieldKind.int32 => 'FieldKind.int32',
      FieldKind.int64 => 'FieldKind.int64',
      FieldKind.f32 => 'FieldKind.f32',
      FieldKind.f64 => 'FieldKind.f64',
      FieldKind.string => 'FieldKind.string',
      FieldKind.timestamp => 'FieldKind.timestamp',
      FieldKind.duration => 'FieldKind.duration',
    };
  }
}
