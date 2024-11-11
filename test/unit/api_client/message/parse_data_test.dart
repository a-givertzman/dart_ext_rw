import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/parse_data.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
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
/// Testing [ParseData].parse
void main() {
  Log.initialize(level: LogLevel.all);
  final log = Log('Test:ParseData');
  group('ParseData.parse', () {
    test('.parse()', () async {
      ParseData parseData = ParseData(
        field: ParseSize(
          size: FieldSize.def(),
          field: ParseKind(
            field: ParseId(
              id: FieldId.def(),
              field: ParseSyn.def(),
            ),
          ),
        ),
      );
      final List<(int, bool, List<int>, Option<(FieldId, FieldKind, int)>, List<int>)> testData = [
        (01,  keepGo, [ 11,  12, syn, 00, 00, 00, 11, 40, 00], None(                       ), []),
        (02,  keepGo, [ 00,  00,  02, 25, 26], Some((FieldId(11), FieldKind.string,   2)), [25, 26]),
        (03, restart, [ 31, syn,  00, 00, 00, 12, 40, 00, 00], None(                       ), []),
        (04, restart, [ 00,  03,  44, 45, 46], None(                       ), []),
        (05,  keepGo, [syn,  00,  00, 00, 13, 40,  00, 00, 00], None(                       ), []),
        (06,  keepGo, [ 04,  62,  63, 64, 65], Some((FieldId(13), FieldKind.string,   4)), [62,  63, 64, 65]),
        (07, restart, [syn,  00,  00, 00, 14, 40,  00, 00, 00], None(                       ), []),
        (08,  keepGo, [ 10,  62,  63, 64, 65], None(                       ), []),
        (09,  keepGo, [ 66,  67,  68, 69, 70], None(                       ), []),
        (09,  keepGo, [ 71                  ], Some((FieldId(14), FieldKind.string,  10)), [62, 63, 64, 65, 66, 67, 68, 69, 70, 71]),
        (10, restart, [syn,  00,  00, 00, 15, 40,  00, 00, 01], None(                       ), []),
        (11,  keepGo, [ 02,  62,  63, 64, 65], None(                       ), []),
        (12,  keepGo, [ 66,  67,  68, 69, 70], None(                       ), []),
        (13,  keepGo, [ 71,  72,  73, 74, 75], None(                       ), []),
        (14,  keepGo, [for(var i=76; i<=316; i+=1) i], None(                ), []),
        (15,  keepGo, [317, 318, 319        ], Some((FieldId(15), FieldKind.string,  258)), [for(var i=62; i<=319; i+=1) i]),
      ];
      for (final (step, restart, bytes, target, targetBytes) in testData) {
        log.debug('.parse | step: $step,  targetBytes.length: ${targetBytes.length}');
        if (restart) {
          parseData = ParseData(
            field: ParseSize(
              size: FieldSize.def(),
              field: ParseKind(
                field: ParseId(
                id: FieldId.def(),
                  field: ParseSyn.def(),
                ),
              ),
            ),
          );
        }
        switch (parseData.parse(bytes)) {
          case Some(value: (FieldId id, FieldKind kind, FieldSize size, Bytes resultBytes)):
            final targetId = target.unwrap().$1;
            final targetKind = target.unwrap().$2;
            final targetSize = target.unwrap().$3;
            expect(
              target,
              isA<Some>(),
              reason: 'step: $step \n result: Some() \n target: $target',
            );
            expect(
              id,
              targetId,
              reason: 'step: $step \n result: $id \n target: $targetId',
            );
            expect(
              kind,
              targetKind,
              reason: 'step: $step \n result: $kind \n target: $targetKind',
            );
            expect(
              size.size,
              targetSize,
              reason: 'step: $step \n result: ${size.size} \n target: $targetSize',
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
