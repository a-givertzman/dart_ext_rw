import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_kind.dart';
import 'package:ext_rw/src/api_client/message/parse_syn.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// setup constants
const int syn = 22;
const restart = true;
const keepGo = false;
// ///
// /// FakeFiledSyn 
// class FakeFiledSyn implements MessageParse<void> {
//   Option<void> syn;
//   FakeFiledSyn(this.syn);
//   @override
//   (Option<void>, List<int>) parse(List<int> bytes) {
//     return (syn, bytes);
//   }
//   void add(Option<void> s) {
//     syn = s;
//   }
// }
///
/// Testing [ParseKind].parse
void main() {
  group('FieldKind.parse', () {
    test('.parse()', () async {
      // final fieldSyn = FakeFiledSyn(None());
      ParseKind fieldKind = ParseKind(
        field: ParseSyn.def(),
      );
      final testData = [
        (01,  keepGo, Some(null), [ 11,  12, syn, 40, 14], Some(FieldKind.string), [14]),
        (02,  keepGo, Some(null), [ 21,  23,  24, 25, 26], Some(FieldKind.string), [21, 23,  24, 25, 26]),
        (03, restart, Some(null), [ 31, syn,  40, 34, 35], Some(FieldKind.string), [34, 35]),
        (04, restart, Some(null), [ 41,  43,  44, 45, 46], None(    ), []),
        (05,  keepGo, Some(null), [syn,  40,  55, 55, 56], Some(FieldKind.string), [55, 55, 56]),
        (06,  keepGo, Some(null), [ 61,  62,  63, 64, 65], Some(FieldKind.string), [61, 62,  63, 64, 65]),
      ];
      final targetKind = FieldKind.string;
      for (final (step, restart, _, bytes, target, targetBytes) in testData) {
        if (restart) {
          fieldKind = ParseKind(
            field: ParseSyn.def(),
            // field: fieldSyn,
          );
        }
        // fieldSyn.add(syn);
        switch (fieldKind.parse(bytes)) {
          case Some<(FieldKind, List<int>)>(value: (FieldKind kind, Bytes resultBytes)):
            expect(
              target,
              isA<Some>(),
              reason: 'step: $step \n result: None() \n target: $target',
            );
            expect(
              kind,
              targetKind,
              reason: 'step: $step \n result: $kind \n target: $targetKind',
            );
            expect(
              listEquals(resultBytes, targetBytes),
              true,
              reason: 'step: $step \n result: $resultBytes \n target: $targetBytes',
            );
          case None():
            expect(
              target,
              isA<None>(),
              reason: 'step: $step \n result: None() \n target: $target',
            );
        }
      }
    });
  });
}
