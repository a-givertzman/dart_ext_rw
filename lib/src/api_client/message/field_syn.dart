///
/// Used to build / parse a start of the message
class FieldSyn {
  final int _syn;
  final int _len;
  ///
  /// Returns FieldSyn new instance
  FieldSyn({
    required int syn,
    required int len,
  }): _syn = syn, _len = len;
  ///
  /// Returns FieldSyn new instance
  /// - With default `Start` symbol SYN = 22, len = 1 byte
  FieldSyn.def():
    _syn = 22,
    _len = 1;
  ///
  /// Returns specified `SYN` value
  int get syn => _syn;
  ///
  /// Return specified length of field `SYN`
  int get len => _len;
}
