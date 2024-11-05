import 'package:ext_rw/src/api_client/message/message_parse.dart';

///
/// Used for storing paload data bytes
/// - which size in the bytes defined in the [FieldSize]
class FieldData {
  final List<int> bytes;
  ///
  /// Returns FieldData new instance
  FieldData(this.bytes);
}
