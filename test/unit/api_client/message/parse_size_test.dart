import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_id.dart';
import 'package:ext_rw/src/api_client/message/parse_kind.dart';
import 'package:ext_rw/src/api_client/message/parse_size.dart';
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
/// Testing [ParseSize].parse
void main() {
  Log.initialize(level: LogLevel.all);
  group('SizeParse.parse', () {
    test('.parse()', () async {
      ParseSize sizeParse = ParseSize(
        size: FieldSize.def(),
        field: ParseKind(
          field: ParseId(
            id: FieldId.def(),
            field: ParseSyn.def(),
            ),
        ),
      );
      final List<(int, bool, List<int>, Option<int>, List<int>)> testData = [
        (01,  keepGo, [ 11,  12, syn, 00, 00, 00, 01, 40, 00], None( ), []),
        (02,  keepGo, [ 00,  00,  02, 25, 26], Some(2), [25, 26]),
        (03, restart, [ 31, syn,  00, 00, 00, 02, 40, 00, 00], None( ), []),
        (04, restart, [ 00,  03,  44, 45, 46], None( ), []),
        (05,  keepGo, [syn,  00, 00, 00, 01, 40,  00, 00, 00], None( ), []),
        (06,  keepGo, [ 04,  62,  63, 64, 65], Some(4), [62,  63, 64, 65]),
        (07, restart, [syn,  00, 00, 00, 01, 40,  00, 00, 00], None( ), []),
        (08,  keepGo, [ 10,  62,  63, 64, 65], Some(10), [62,  63, 64, 65]),
        (09,  keepGo, [ 66,  67,  68, 69, 70], Some(10), [66,  67,  68, 69, 70]),
        (10, restart, [syn,  00, 00, 00, 01, 40,  00, 00, 01], None( ), []),
        (11,  keepGo, [ 02,  62,  63, 64, 65], Some(258), [62,  63, 64, 65]),
        (12,  keepGo, [ 66,  67,  68, 69, 70], Some(258), [66,  67,  68, 69, 70]),
        (13,  keepGo, [ 71,  72,  73, 74, 75], Some(258), [71,  72,  73, 74, 75]),
        (17, restart, [syn,  00, 00, 00, 77, 02,  00, 00, 00, 9,  62, 63, 64, 65, 66, 67, 68, 69, 70, syn, 00, 00, 00, 88, 08, 00, 00, 00, 02, 25, 26], Some(9), [62, 63, 64, 65, 66, 67, 68, 69, 70, syn, 00, 00, 00, 88, 08, 00, 00, 00, 02, 25, 26]),
        (18,  keepGo, [], Some(9), []),
      ];
      for (final (step, restart, bytes, target, targetBytes) in testData) {
        if (restart) {
          sizeParse = ParseSize(
            size: FieldSize.def(),
            field: ParseKind(
              field: ParseId(
                id: FieldId.def(),
                field: ParseSyn.def(),
              ),
            ),
          );
        }
        switch (sizeParse.parse(bytes)) {
          case Some(value: (FieldId _, FieldKind _, FieldSize size, Bytes resultBytes)):
            expect(
              target,
              isA<Some>(),
              reason: 'step: $step \n result: ${isA<Some>()} \n target: $target',
            );
            expect(
              size.size,
              target.unwrap(),
              reason: 'step: $step \n result: ${size.size} \n target: ${targetBytes.length}',
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
