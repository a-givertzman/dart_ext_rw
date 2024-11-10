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
      final List<(int, bool, Some<Null>, List<int>, Option<int>, List<int>)> testData = [
        (01,  keepGo, Some(null), [ 11,  12, syn, 00, 00], None( ), []),
        (02,  keepGo, Some(null), [ 00,  02,  25, 26, 27], Some(2), [25, 26, 27]),
        (03, restart, Some(null), [ 31, syn,  00, 00, 00], None( ), []),
        (04, restart, Some(null), [ 03,  44,  45, 46, 47], None( ), []),
        (05,  keepGo, Some(null), [ 48, syn,  00, 00, 00], None( ), []),
        (06,  keepGo, Some(null), [ 77,  62,  63, 64, 65], Some(77), [62,  63, 64, 65]),
        (07, restart, Some(null), [syn,  00,  00, 00], None( ), []),
        (08,  keepGo, Some(null), [ 10,  62,  63, 64], Some(10), [62,  63, 64]),
        (09,  keepGo, Some(null), [ 65,  66,  67, 68], Some(10), [65,  66, 67, 68]),
        (10, restart, Some(null), [syn,  00, 00, 01], None( ), []),
        (11,  keepGo, Some(null), [ 02,  62,  63, 64], Some(258), [62,  63, 64]),
        (12,  keepGo, Some(null), [ 65,  66,  67, 68, 69], Some(258), [65,  66,  67, 68, 69]),
        (13,  keepGo, Some(null), [ 70,  71,  72, 73, 74], Some(258), [70,  71,  72, 73, 74]),
        (14, restart, Some(null), [syn,  00,  01, 02, 03, 62], Some(66051), [62]),
        (15,  keepGo, Some(null), [ 63,  64,  65, 66, 67, 68], Some(66051), [63,  64,  65, 66, 67, 68]),
        (16,  keepGo, Some(null), [ 69,  70,  71, 72, 73, 74], Some(66051), [69,  70,  71, 72, 73, 74]),
      ];
      for (final (step, restart, _, bytes, target, targetBytes) in testData) {
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
              id.id,
              target.unwrap(),
              reason: 'step: $step \n result: ${id.id} \n target: ${target.unwrap()}',
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
