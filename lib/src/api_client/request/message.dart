//!
//! # Messages transmitted over socket.
//! 
//! - Data can be encoded using varius data `Kind`, `Size` and payload Data
//! 
//! - Message format
//!     Field name | Start | Kind |  Size  | Data |
//!     ---       |  ---  | ---  |  ---   | ---  |
//!     Data type |  u8   | u8   | u32    | [u8; Size] |
//!     Value     |  22   | StringValue | xxx    | [..., ...]  |
//!     
//!     - Start - Each message starts with SYN (22)
//!     - Kind - The `Kind` of the data stored in the `Data` field, refer to
//!     - Size - The length of the `Data` field in bytes
//!     - Data - Data structured depending on it `Kind`
//! 
//! - `Kind` of data
//!     - 00, Any
//!     - 01, Empty
//!     - 02, Bytes
//!     - 08, Bool
//!     - 16, UInt16
//!     - 17, UInt32
//!     - 18, UInt64
//!     - 24, Int16
//!     - 25, Int32
//!     - 26, Int64
//!     - 32, F32
//!     - 33, F64
//!     - 40, String
//!     - 48, Timestamp
//!     - 49, Duration
//!     - .., ...

import 'dart:typed_data';
///
///
class FieldSyn {
  final int syn;
  ///
  /// Returns FieldSyn new instance
  /// - By default `Start` symbol is SYN = 22
  const FieldSyn({
    this.syn = 22,
  });
}
///
///
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
}
///
///
class FieldSize {
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
}
///
///
class FieldData {
  final List<int> bytes;
  ///
  /// Returns FieldData new instance
  FieldData(this.bytes);
}
///
///
class Message {
  final FieldSyn syn;
  final FieldKind kind;
  final FieldSize size;
  final FieldData data;
  ///
  /// # Returns Message instance
  /// - **in case of Sending**
  ///   - [kind] - Kind of sending message
  ///   - [size] - Size in bytes of the data
  ///   - [data] - Sending data
  /// - **in case of Receiving**
  ///   - [kind] - Not required, ignored if specified
  ///   - [size] - The length of the data will be used to read data from the socket
  ///   - [data] - Data of length specified in [size] will be fetched from the socket
  Message({
    this.syn = const FieldSyn(),
    required this.kind,
    required this.size,
    required this.data,
  });
  ///
  /// Returns message bytes built of the specified fields
  List<int> bytes() {
    return [syn.syn, kind.kind, ...size.size(data.bytes.length), ...data.bytes];
  }

}