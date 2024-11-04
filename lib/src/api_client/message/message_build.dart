import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
///
/// # Messages transmitted over socket.
/// 
/// - Data can be encoded using varius data `Kind`, `Size` and payload Data
/// 
/// - Message format
///     Field name | Start | Kind |  Size  | Data |
///     ---       |  ---  | ---  |  ---   | ---  |
///     Data type |  u8   | u8   | u32    | [u8; Size] |
///     Value     |  22   | StringValue | xxx    | [..., ...]  |
///     
///     - Start - Each message starts with SYN (22)
///     - Kind - The `Kind` of the data stored in the `Data` field, refer to
///     - Size - The length of the `Data` field in bytes
///     - Data - Data structured depending on it `Kind`
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
class MessageBuild {
  late final FieldSyn syn;
  final FieldKind kind;
  final FieldSize size;
  final FieldData data;
  ///
  /// # Returns MessageBuild instance
  /// - **in case of Sending**
  ///   - [kind] - Kind of sending message
  ///   - [size] - Size in bytes of the data
  ///   - [data] - Sending data
  /// - **in case of Receiving**
  ///   - [kind] - Not required, ignored if specified
  ///   - [size] - The length of the data will be used to read data from the socket
  ///   - [data] - Data of length specified in [size] will be fetched from the socket
  MessageBuild({
    required this.syn,
    required this.kind,
    required this.size,
    required this.data,
  });
  ///
  /// Returns message built according to specified fields and [bytes]
  List<int> build(List<int> bytes) {
    return [syn.syn, kind.kind, ...size.size(bytes.length), ...bytes];
  }
}