
import 'package:ext_rw/src/table_schema/relation.dart';

///
/// Replresentation settings for table column
class Field {
  final String _key;
  final String _name;
  final bool _hidden;
  final bool _edit;
  final Relation _relation;
  ///
  const Field({
    required String key,
    String? name,
    bool hidden = false,
    bool edit = true,
    Relation? relation,
  }) :
    _key = key,
    _name = name ?? key,
    _hidden = hidden,
    _edit = edit,
    _relation = relation ?? const Relation.empty();
  ///
  ///
  String get key => _key;
  ///
  ///
  String get name => _name;
  ///
  ///
  bool get hidden => _hidden;
  ///
  ///
  bool get edit => _edit;
  ///
  ///
  Relation get relation => _relation;
}