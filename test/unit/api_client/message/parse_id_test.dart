import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_id.dart';
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
///
/// Testing [ParseId].parse
void main() {
  Log.initialize(level: LogLevel.all);
  group('ParseId.parse', () {
    test('.parse()', () async {
      ParseId parseId = ParseId(
        id: FieldId.def(),
        field: ParseSyn.def(),
      );
      final List<(int, bool, List<int>, Option<FieldId>, List<int>)> testData = [
        (01,  keepGo, [ 11,  12, syn, 00, 00], None( ), []),
        (02,  keepGo, [ 00,  02,  25, 26, 27], Some(FieldId(2)), [25, 26, 27]),
        (03, restart, [ 31, syn,  00, 00, 00], None( ), []),
        (04, restart, [ 03,  44,  45, 46, 47], None( ), []),
        (05,  keepGo, [ 48, syn,  00, 00, 00], None( ), []),
        (06,  keepGo, [ 77,  62,  63, 64, 65], Some(FieldId(77)), [62,  63, 64, 65]),
        (07, restart, [syn,  00,  00, 00], None( ), []),
        (08,  keepGo, [ 10,  62,  63, 64], Some(FieldId(10)), [62,  63, 64]),
        (09,  keepGo, [ 65,  66,  67, 68], Some(FieldId(10)), [65,  66, 67, 68]),
        (10, restart, [syn,  00, 00, 01], None( ), []),
        (11,  keepGo, [ 02,  62,  63, 64], Some(FieldId(258)), [62,  63, 64]),
        (12,  keepGo, [ 65,  66,  67, 68, 69], Some(FieldId(258)), [65,  66,  67, 68, 69]),
        (13,  keepGo, [ 70,  71,  72, 73, 74], Some(FieldId(258)), [70,  71,  72, 73, 74]),
        (14, restart, [syn,  00,  01, 02, 03, 62], Some(FieldId(66051)), [62]),
        (15,  keepGo, [ 63,  64,  65, 66, 67, 68], Some(FieldId(66051)), [63,  64,  65, 66, 67, 68]),
        (16,  keepGo, [ 69,  70,  71, 72, 73, 74], Some(FieldId(66051)), [69,  70,  71, 72, 73, 74]),
        (17, restart, [syn,  00, 00, 00, 77, 40,  00, 00, 00, 9,  62, 63, 64, 65, 66, 67, 68, 69, 70, syn, 00, 00, 00, 88, 08, 00, 00, 00, 02, 25, 26], Some(FieldId(77)), [40,  00, 00, 00, 9,  62, 63, 64, 65, 66, 67, 68, 69, 70, syn, 00, 00, 00, 88, 08, 00, 00, 00, 02, 25, 26]),
        (18,  keepGo, [], Some(FieldId(77)), []),
      ];
      for (final (step, restart, bytes, target, targetBytes) in testData) {
        if (restart) {
          parseId = ParseId(
            id: FieldId.def(),
            field: ParseSyn.def(),
          );
        }
        switch (parseId.parse(bytes)) {
          case Some<(FieldId, List<int>)>(value: (FieldId id, Bytes resultBytes)):
            expect(
              target,
              isA<Some>(),
              reason: 'step: $step \n result: ${isA<Some>()} \n target: $target',
            );
            expect(
              id,
              target.unwrap(),
              reason: 'step: $step \n result: $id \n target: ${target.unwrap()}',
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
              reason: 'step: $step \n result: ${isA<None>()} \n target: $target',
            );
        }
      }
    });
  });
}
