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
    switch (val) {
      case 0:
        return Ok(FieldKind.any);
      case 1:
        return Ok(FieldKind.empty);
      case 2:
        return Ok(FieldKind.bytes);
      case 8:
        return Ok(FieldKind.bool);
      case 16:
        return Ok(FieldKind.uint16);
      case 17:
        return Ok(FieldKind.uint32);
      case 18:
        return Ok(FieldKind.uint64);
      case 24:
        return Ok(FieldKind.int16);
      case 25:
        return Ok(FieldKind.int32);
      case 26:
        return Ok(FieldKind.int64);
      case 32:
        return Ok(FieldKind.f32);
      case 33:
        return Ok(FieldKind.f64);
      case 40:
        return Ok(FieldKind.string);
      case 48:
        return Ok(FieldKind.timestamp);
      case 49:
        return Ok(FieldKind.duration);
      default:
        return Err(Failure(message: 'FieldKind.fromBytes | Unknown Kind $val', stackTrace: StackTrace.current));
    }
  }
  @override
  String toString() {
    switch (this) {
      case FieldKind.any:
        return 'FieldKind.any';
      case FieldKind.empty:
        return 'FieldKind.empty';
      case FieldKind.bytes:
        return 'FieldKind.bytes';
      case FieldKind.bool:
        return 'FieldKind.bool';
      case FieldKind.uint16:
        return 'FieldKind.uint16';
      case FieldKind.uint32:
        return 'FieldKind.uint32';
      case FieldKind.uint64:
        return 'FieldKind.uint64';
      case FieldKind.int16:
        return 'FieldKind.int16';
      case FieldKind.int32:
        return 'FieldKind.int32';
      case FieldKind.int64:
        return 'FieldKind.int64';
      case FieldKind.f32:
        return 'FieldKind.f32';
      case FieldKind.f64:
        return 'FieldKind.f64';
      case FieldKind.string:
        return 'FieldKind.string';
      case FieldKind.timestamp:
        return 'FieldKind.timestamp';
      case FieldKind.duration:
        return 'FieldKind.duration';
    }
  }
}