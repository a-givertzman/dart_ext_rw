
import 'package:ext_rw/src/table_schema/relation.dart';
import 'package:flutter/widgets.dart';

///
/// Replresentation settings for table column
class Field<T> {
  final String _key;
  final String _title;
  final bool _hidden;
  final bool _edit;
  final Relation _relation;
  final Widget Function(BuildContext, T)? _builder;
  ///
  /// **Represents table column settings**
  /// - [title] - display name of the column, if null, the [key] will be displayed
  /// - [key] 
  ///   - database column name if not relation
  ///   - relation key if this is relation column
  /// - [relation] - represents column, related from another table, where from data will be gotten
  /// - [builder] - callback returns table column cell widget
  const Field({
    required String key,
    String? title,
    bool hidden = false,
    bool editable = false,
    Relation? relation,
    Widget Function(BuildContext, T)? builder,
  }) :
    _key = key,
    _title = title ?? key,
    _hidden = hidden,
    _edit = editable,
    _relation = relation ?? const Relation.empty(),
    _builder = builder;
  ///
  ///
  String get key => _key;
  ///
  ///
  String get title => _title;
  ///
  ///
  bool get isHidden => _hidden;
  ///
  ///
  bool get isEditable => _edit;
  ///
  ///
  Relation get relation => _relation;
  ///
  /// Returns cell widget build from specified [builder],  
  /// Or by default retirns Text(value)
  Widget build(BuildContext context, T value) {
    final builder = _builder;
    if (builder != null) {
      return builder(context, value);
    }
    return Text('$value');
  }
  //
  //
  @override
  String toString() {
    return '$runtimeType{ key: $_key, title: $_title, hidden: $_hidden, editable: $_edit, relation: $_relation }';
  }
}