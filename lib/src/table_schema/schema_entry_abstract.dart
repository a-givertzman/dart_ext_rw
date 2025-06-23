import 'package:ext_rw/src/table_schema/field_value.dart';

///
/// abstruction on the SQL table single row
abstract interface class SchemaEntryAbstract {
  ///
  /// Returns inner unique identificator of the entry, not related to the database table
  String get key;
  ///
  /// Returns true if any field of entry was changed
  bool get isChanged;
  ///
  /// Returns selection state
  bool get isSelected;
  ///
  /// Returns true if created as Empty / not initialized yet
  bool get isEmpty;
  ///
  /// Returns field value by field name [key]
  FieldValue value(String key);
  ///
  /// Updates field value by field name [key]
  void update(String key, dynamic value);
  ///
  /// Set selection state
  void select(bool selected);
  ///
  /// Subscribe on selection changed
  void selectionChanged(Function(bool isSelected) onChanged);
  ///
  /// Set isChanged to false
  void saved();
  //
  //
  @override
  String toString();
}