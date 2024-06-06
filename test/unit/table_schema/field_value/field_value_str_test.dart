import 'package:ext_rw/src/table_schema/field_value.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestObject {
  const _TestObject();
}

void main() {
  test('FieldValue str correctly serializes its value', () {
    const valueMaps = [
      {
        'value': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
        'type': FieldType.string,
        'str': '\'_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}\'',
      },
      {
        'value': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
        'type': FieldType.int,
        'str': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
      },
      {
        'value': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
        'type': FieldType.double,
        'str': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
      },
      {
        'value': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
        'type': FieldType.bool,
        'str': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
      },
      {
        'value': 123,
        'type': FieldType.string,
        'str': '\'123\'',
      },
      {
        'value': 123,
        'type': FieldType.int,
        'str': '123',
      },
      {
        'value': 123,
        'type': FieldType.double,
        'str': '123',
      },
      {
        'value': 123,
        'type': FieldType.bool,
        'str': '123',
      },
      {
        'value': 321.321,
        'type': FieldType.string,
        'str': '\'321.321\'',
      },
      {
        'value': 321.321,
        'type': FieldType.int,
        'str': '321.321',
      },
      {
        'value': 321.321,
        'type': FieldType.double,
        'str': '321.321',
      },
      {
        'value': 321.321,
        'type': FieldType.bool,
        'str': '321.321',
      },
      {
        'value': false,
        'type': FieldType.string,
        'str': '\'false\'',
      },
      {
        'value': true,
        'type': FieldType.string,
        'str': '\'true\'',
      },
      {
        'value': true,
        'type': FieldType.int,
        'str': 'true',
      },
      {
        'value': false,
        'type': FieldType.double,
        'str': 'false',
      },
      {
        'value': true,
        'type': FieldType.bool,
        'str': 'true',
      },
      {
        'value': null,
        'type': FieldType.unknown,
        'str': 'null',
      },
      {
        'value': null,
        'type': FieldType.string,
        'str': 'null',
      },
      {
        'value': null,
        'type': FieldType.int,
        'str': 'null',
      },
      {
        'value': null,
        'type': FieldType.double,
        'str': 'null',
      },
      {
        'value': null,
        'type': FieldType.bool,
        'str': 'null',
      },
      {
        'value': _TestObject(),
        'type': FieldType.string,
        'str': '\'Instance of \'_TestObject\'\'',
      },
      {
        'value': _TestObject(),
        'type': FieldType.int,
        'str': 'Instance of \'_TestObject\'',
      },
      {
        'value': _TestObject(),
        'type': FieldType.double,
        'str': 'Instance of \'_TestObject\'',
      },
      {
        'value': _TestObject(),
        'type': FieldType.bool,
        'str': 'Instance of \'_TestObject\'',
      },
    ];
    for(final {
      'value': value, 
      'type': type as FieldType, 
      'str': str as String?,
    } in valueMaps) {
      final fieldValue = FieldValue(value, type: type);
      expect(fieldValue.str, equals(str), reason: 'value: $value, type: $type, str: $str');
    }
  });
}