
import 'package:ext_rw/src/table_schema/field_value.dart';

///
/// abstruction on the SQL table single row
abstract class SchemaEntry {
  ///
  /// Creates entry from database row
  SchemaEntry.from(Map<String, dynamic> row);
  ///
  /// Creates entry with empty / default values
  SchemaEntry.empty();
  ///
  /// Returns inner unique identificator of the entry, not related to the database table
  String get key;
  ///
  /// Returns field value by field name [key]
  FieldValue value(String key);
  ///
  /// Updates field value by field name [key]
  void update(String key, String value);
  ///
  ///
  bool get isChanged;
}