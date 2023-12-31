class FieldValue<T> {
  T _value;
  FieldType _type;
  ///
  ///
  FieldValue(
    T value, {
    FieldType type = FieldType.unknown,
  }) :
    _value = value,
    _type = type;
  ///
  ///
  T get value => _value;
  ///
  /// Returns a string representation of the inner value
  String? get str {
    if (_value == null) {
      return null;
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
      switch (type) {
        case FieldType.bool:
          _value = value;
          return true;
        case FieldType.int:
          _value = value;
          return true;
        case FieldType.double:
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
    return false;
  }
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
