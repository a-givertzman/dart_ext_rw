import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_id.dart';
import 'package:ext_rw/src/api_client/message/parse_kind.dart';
import 'package:ext_rw/src/api_client/message/parse_syn.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_log.dart';
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
  Log.initialize(level: LogLevel.all);
  final log = const Log('ParseKind.Test');
  group('FieldKind.parse', () {
    test('.parse()', () async {
      // final fieldSyn = FakeFiledSyn(None());
      ParseKind parseKind = ParseKind(
        field: ParseId(
          id: FieldId.def(),
          field: ParseSyn.def(),
        ),
      );
      final List<(int, bool, List<int>, Option<(FieldId, FieldKind)>, List<int>)> testData = [
        (01,  keepGo, [ 11,  12, syn, 00, 00, 00, 01, 40, 14], Some((FieldId(1), FieldKind.string)), [14]),
        (02,  keepGo, [ 21,  23,  24, 25, 26, 27, 28, 29, 30], Some((FieldId(1), FieldKind.string)), [21,  23,  24, 25, 26, 27, 28, 29, 30]),
        (03, restart, [ 31, syn,  00, 00, 00, 02, 17, 34, 35], Some((FieldId(2), FieldKind.uint32)), [34, 35]),
        (04, restart, [ 41,  43,  44, 45, 46], None(                ), []),
        (05,  keepGo, [syn,  00,  00, 01, 01, 40, 55, 55, 56], Some((FieldId(257), FieldKind.string)), [55, 55, 56]),
        (06,  keepGo, [ 61,  62,  63, 64, 65, 66, 67, 68, 69], Some((FieldId(257), FieldKind.string)), [61, 62, 63, 64, 65, 66, 67, 68, 69]),
        (07, restart, [ 18, syn,  00, 00, 00], None(                ), []),
        (08,  keepGo, [ 08,  18,  62,  63, 64, 65], Some((FieldId(8), FieldKind.uint64)), [62, 63, 64, 65]),
        (09,  keepGo, [ 66,  67,  68,  69, 70, 71], Some((FieldId(8), FieldKind.uint64)), [66, 67, 68, 69, 70, 71]),
        (10, restart, [syn,  00,  00, 00, 99, 26,  00, 00, 01], Some((FieldId(99), FieldKind.int64 )), [00, 00, 01]),
        (11,  keepGo, [ 02,  62,  63, 64, 65], Some((FieldId(99), FieldKind.int64 )), [02, 62, 63, 64, 65]),
        (12,  keepGo, [ 66,  67,  68, 69, 70], Some((FieldId(99), FieldKind.int64 )), [66, 67, 68, 69, 70]),
        (13,  keepGo, [ 66,  67,  68, 69, 70], Some((FieldId(99), FieldKind.int64 )), [66, 67, 68, 69, 70]),
      ];
      for (final (step, restart, bytes, targetIdKind, targetBytes) in testData) {
        if (restart) {
          parseKind = ParseKind(
            field: ParseId(
              id: FieldId.def(),
              field: ParseSyn.def(),
            ),
          );
        }
        switch (parseKind.parse(bytes)) {
          case Some(value: (FieldId id, FieldKind kind, Bytes resultBytes)):
            log.debug('.test | id: $id');
            log.debug('.test | kind: $kind');
            expect(
              targetIdKind,
              isA<Some>(),
              reason: 'step: $step \n result: Some() \n target: $targetIdKind',
            );
            expect(
              id,
              targetIdKind.unwrap().$1,
              reason: 'step: $step \n result: $id \n target: ${targetIdKind.unwrap().$1}',
            );
            expect(
              kind,
              targetIdKind.unwrap().$2,
              reason: 'step: $step \n result: $kind \n target: ${targetIdKind.unwrap().$2}',
            );
            expect(
              listEquals(resultBytes, targetBytes),
              true,
              reason: 'step: $step \n result: $resultBytes \n target: $targetBytes',
            );
          case None():
            expect(
              targetIdKind,
              None(),
              reason: 'step: $step \n result: None() \n target: $targetIdKind',
            );
        }
      }
    });
  });
}
