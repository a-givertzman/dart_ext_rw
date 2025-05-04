class FieldValue<T> {
  T _value;
  FieldType _type;
  bool _isChanged = false;
  ///
  ///
  FieldValue(
    T value, {
    FieldType type = FieldType.unknown,
  }) :
    _value = value,
    _type = type;
  ///
  /// Returns inner value as [T]
  T get value => _value;
  ///
  /// Returns a string representation of the inner value
  String get str {
    if (_value == null || '$_value'.toLowerCase() == 'null') {
      return 'null';
    }
    switch (type) {
      case FieldType.bool:
        return '$_value';
      case FieldType.int:
        return '$_value';
      case FieldType.double:
        return '$_value';
      case FieldType.string:
        return "'$_value'";
      case FieldType.unknown:
        return "'$_value'";
      // default:
    }
  }
  ///
  ///
  FieldType get type {
    if (_type != FieldType.unknown) {
      return _type;
    }
    if (value.runtimeType == bool) {
      _type = FieldType.bool;
    } else if (value.runtimeType == int) {
      _type = FieldType.int;
    } else if (value.runtimeType == double) {
      _type = FieldType.double;
    } else if (value.runtimeType == String) {
      _type = FieldType.string;
    }
    return _type;
  }
  ///
  /// Returns true if changed
  bool update(T value) {
    if (_value != value) {
      _isChanged = true;
      if (value == null) {
        _value = value;
      } else {
        switch (type) {
          case FieldType.bool:
            // TODO Add type convertion
            _value = value;
            return true;
          case FieldType.int:
            // TODO Add type convertion
            _value = value;
            return true;
          case FieldType.double:
            // TODO Add type convertion
            _value = value;
            return true;
          case FieldType.string:
            _value = '$value' as T;
            return true;
          case FieldType.unknown:
            _value = value;
            return true;
        }
      }
    }
    return false;
  }
  ///
  /// Returns true if value was updated
  bool get isChanged => _isChanged;
  //
  //
  @override
  String toString() {
    return '$runtimeType{type: $type, value: $_value}';
  }
}


enum FieldType {
  bool,
  int,
  double,
  string,
  unknown,
}
