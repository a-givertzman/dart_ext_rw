///
/// # Messages received over socket.
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
abstract class MessageParse<I, T> {
  ///
  /// # Returns MessageParse result
  /// - **in case of Sending**
  ///   - [kind] - Kind of sending message
  ///   - [size] - Size in bytes of the data
  ///   - [data] - Sending data
  /// - **in case of Receiving**
  ///   - [kind] - Not required, ignored if specified
  ///   - [size] - The length of the data will be used to read data from the socket
  ///   - [data] - Data of length specified in [size] will be fetched from the socket
  ///
  /// Returns T if parsed
  T parse(I input);
}
///
/// Input bytes type
typedef Bytes = List<int>;