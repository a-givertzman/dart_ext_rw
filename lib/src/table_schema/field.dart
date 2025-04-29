
import 'package:ext_rw/src/table_schema/relation.dart';
import 'package:ext_rw/src/table_schema/schema_entry_abstract.dart';
import 'package:flutter/widgets.dart';

///
/// Replresentation settings for table column
class Field<T extends SchemaEntryAbstract> {
  final String _key;
  final String _title;
  final String _hint;
  final bool _hidden;
  final bool _edit;
  final Relation _relation;
  final Widget Function(BuildContext ctx, T entry, Function(String)? onComplete)? _builder;
  final int _flex;
  ///
  /// **Represents table column settings**
  /// - [title] - display name of the column, if null, the [key] will be displayed
  /// - [hint] - Hint / tooltip of the column
  /// - [key] 
  ///   - database column name if not relation
  ///   - relation key if this is relation column
  /// - [relation] - represents column, related from another table, where from data will be gotten
  /// - [builder] - callback returns table column cell widget
  const Field({
    required String key,
    String? title,
    String? hint,
    bool hidden = false,
    bool editable = false,
    Relation? relation,
    Widget Function(BuildContext ctx, T entry, Function(String)? onComplete)? builder,
    int flex = 1,
  }) :
    _key = key,
    _title = title ?? key,
    _hint = hint ?? title ?? key,
    _hidden = hidden,
    _edit = editable,
    _relation = relation ?? const Relation.empty(),
    _builder = builder,
    _flex = flex;
  ///
  /// Returns [key] of [Field]
  ///   - database column name if not relation
  ///   - relation key if this is relation column
  String get key => _key;
  ///
  /// Display name of [Field] if not specified, [key] will be displayed
  String get title => _title;
  ///
  /// Hint of [Field] if not specified, [title] will be displayed
  String get hint => _hint;
  ///
  /// Column will not be displayed if `true`
  bool get isHidden => _hidden;
  ///
  /// Can be edited if `true`
  bool get isEditable => _edit;
  ///
  /// Returns [Relations] if specified, or Relation.empty will be returned
  Relation get relation => _relation;
  ///
  /// Returns cell widget build from specified [builder],  
  /// Or by default retirns Text(value)
  Widget Function(BuildContext ctx, T entry, Function(String)? onComplete)? get builder => _builder;
  ///
  /// Returns flex value of current field
  int get flex => _flex;
  //
  //
  @override
  String toString() {
    return '$runtimeType{ key: $_key, title: $_title, hidden: $_hidden, editable: $_edit, relation: $_relation, flex: $_flex }';
  }
}