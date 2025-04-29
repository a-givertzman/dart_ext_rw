///
/// - [id] - where from get the data
/// - [field] - name of field to be presented from data
class Relation {
  final String _id;
  final String _field;
  final bool _isEmpty;
  ///
  ///
  const Relation({
    required String id,
    required String field,
  }) :
    _id = id,
    _field = field,
    _isEmpty = false;
  ///
  const Relation.empty() :
    _id = '',
    _field = '',
    _isEmpty = true;
  ///
  /// Where from get the data
  String get id => _id;
  ///
  /// Name of field to be presented from data
  String get field => _field;
  ///
  /// Returns true if [Relation] was created empty
  bool get isEmpty => _isEmpty;
  ///
  /// Returns true if [Relation] was created not empty
  bool get isNotEmpty => !_isEmpty;
}