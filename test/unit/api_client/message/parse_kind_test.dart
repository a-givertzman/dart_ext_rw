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
      final List<(int, bool, List<int>, Option<FieldKind>, List<int>)> testData = [
        (01,  keepGo, [ 11,  12, syn, 40, 14], Some(FieldKind.string), [14]),
        (02,  keepGo, [ 21,  23,  24, 25, 26], Some(FieldKind.string), [21, 23, 24, 25, 26]),
        (03, restart, [ 31, syn,  17, 34, 35], Some(FieldKind.uint32), [34, 35]),
        (04, restart, [ 41,  43,  44, 45, 46], None(                ), []),
        (05,  keepGo, [syn,  40,  55, 55, 56], Some(FieldKind.string), [55, 55, 56]),
        (06,  keepGo, [ 61,  62,  63, 64, 65], Some(FieldKind.string), [61, 62, 63, 64, 65]),
        (07, restart, [syn,  18,  00, 00, 00], Some(FieldKind.uint64), [00, 00, 00]),
        (08,  keepGo, [ 10,  62,  63, 64, 65], Some(FieldKind.uint64), [10, 62, 63, 64, 65]),
        (09,  keepGo, [ 66,  67,  68, 69, 70], Some(FieldKind.uint64), [66, 67, 68, 69, 70]),
        (10, restart, [syn,  26,  00, 00, 01], Some(FieldKind.int64 ), [00, 00, 01]),
        (11,  keepGo, [ 02,  62,  63, 64, 65], Some(FieldKind.int64 ), [02, 62, 63, 64, 65]),
        (12,  keepGo, [ 66,  67,  68, 69, 70], Some(FieldKind.int64 ), [66, 67, 68, 69, 70]),
        (13,  keepGo, [ 66,  67,  68, 69, 70], Some(FieldKind.int64 ), [66, 67, 68, 69, 70]),
      ];
      for (final (step, restart, bytes, targetKind, targetBytes) in testData) {
        if (restart) {
          fieldKind = ParseKind(
            field: ParseSyn.def(),
          );
        }
        switch (fieldKind.parse(bytes)) {
          case Some<(FieldKind, List<int>)>(value: (FieldKind kind, Bytes resultBytes)):
            expect(
              targetKind,
              isA<Some>(),
              reason: 'step: $step \n result: Some() \n target: $targetKind',
            );
            expect(
              kind,
              targetKind.unwrap(),
              reason: 'step: $step \n result: $kind \n target: ${targetKind.unwrap()}',
            );
            expect(
              listEquals(resultBytes, targetBytes),
              true,
              reason: 'step: $step \n result: $resultBytes \n target: $targetBytes',
            );
          case None():
            expect(
              targetKind,
              None(),
              reason: 'step: $step \n result: None() \n target: $targetKind',
            );
        }
      }
    });
  });
}
