import 'package:ext_rw/src/table_schema/field.dart';
import 'package:ext_rw/src/table_schema/relation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Field constructor', () {
    test('sets default values with only required parameters provided', () {
      const key = 'key';
      const field = Field(key: key);
      expect(field.key, equals(key));
      expect(field.title, equals(key));
      expect(field.isHidden, equals(false));
      expect(field.isEditable, equals(false));
      expect(field.relation, equals(const Relation.empty()));
    });
    test('sets provided values', () {
      const valueMaps = [
        {
          'key': '123af',
          'name': 'wejlrk',
          'hidden': true,
          'edit': true,
          'relation': Relation(id: '1', field: '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}'),
        },
        {
          'key': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
          'name': 'WEJLRK',
          'hidden': false,
          'edit': false,
          'relation': Relation(id: '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}', field: 'reydfg'),
        },
        {
          'key': 'KJLSDFKJuio)()',
          'name': '_+-+()*&^%\$;:?№"#@!`~\\|/.,[]{}',
          'hidden': true,
          'edit': false,
          'relation': Relation.empty(),
        },
        {
          'key': '&^A*23jh4b#@\$%^&',
          'name': '&^*(hjl)',
          'hidden': false,
          'edit': true,
          'relation': Relation(id: '235', field: 'dfghew54'),
        },
        {
          'key': '35i4ilj32n',
          'name': 'nsewjri',
          'hidden': true,
          'edit': false,
          'relation': Relation(id: '1sgd43', field: 'sdg543'),
        },
      ];
      for(final map in valueMaps) {
        final {
          'key': key, 
          'name': name, 
          'hidden': hidden, 
          'edit': edit, 
          'relation': relation,
        } = map;
        final field = Field(
          key: key as String,
          title: name as String,
          hidden: hidden as bool,
          editable: edit as bool,
          relation: relation as Relation,
        );
        expect(field.key, equals(key));
        expect(field.title, equals(name));
        expect(field.isHidden, equals(hidden));
        expect(field.isEditable, equals(edit));
        expect(field.relation, equals(relation));
      }
    });
  });
}
