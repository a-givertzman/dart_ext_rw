import 'package:ext_rw/src/api_client/message/data_parse.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
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
/// Testing [DataParse].parse
void main() {
  Log.initialize(level: LogLevel.all);
  group('DataParse.parse', () {
    test('.parse()', () async {
      DataParse dataParse = DataParse(
        field: ParseSize(
          size: FieldSize(),
          field: ParseKind(
            field: ParseSyn.def(),
          ),
        ),
      );
      final testData = [
        (01,  keepGo, Some(null), [ 11,  12, syn, 40, 00], None( ), []),
        (02,  keepGo, Some(null), [ 00,  00,  02, 25, 26], Some(null), [25, 26]),
        (03, restart, Some(null), [ 31, syn,  40, 00, 00], None( ), []),
        (04, restart, Some(null), [ 00,  03,  44, 45, 46], None( ), []),
        (05,  keepGo, Some(null), [syn,  40,  00, 00, 00], None( ), []),
        (06,  keepGo, Some(null), [ 04,  62,  63, 64, 65], Some(null), [62,  63, 64, 65]),
        (07, restart, Some(null), [syn,  40,  00, 00, 00], None( ), []),
        (08,  keepGo, Some(null), [ 10,  62,  63, 64, 65], Some(10), [62,  63, 64, 65]),
        (09,  keepGo, Some(null), [ 66,  67,  68, 69, 70], Some(10), [66,  67,  68, 69, 70]),
        (10, restart, Some(null), [syn,  40,  00, 00, 01], None( ), []),
        (11,  keepGo, Some(null), [ 02,  62,  63, 64, 65], Some(258), [62,  63, 64, 65]),
        (12,  keepGo, Some(null), [ 66,  67,  68, 69, 70], Some(258), [66,  67,  68, 69, 70]),
        (13,  keepGo, Some(null), [ 66,  67,  68, 69, 70], Some(258), [66,  67,  68, 69, 70]),
      ];
      final targetKind = FieldKind.string;
      for (final (step, restart, _, bytes, target, targetBytes) in testData) {
        if (restart) {
          dataParse = DataParse(
            field: ParseSize(
              size: FieldSize(),
              field: ParseKind(
                field: ParseSyn.def(),
              ),
            ),
          );
        }
        // final Option(FieldKind kind, size, resultBytes) = dataParse.parse(bytes);
        switch (dataParse.parse(bytes)) {
          case Some(value: (FieldKind kind, FieldSize size, List<int> resultBytes)):
            expect(
              kind,
              targetKind,
              reason: 'step: $step \n result: $kind \n target: $targetBytes',
            );
            expect(
              size,
              targetBytes.length,
              reason: 'step: $step \n result: $size \n target: ${targetBytes.length}',
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
        // expect(
        //   ,
        //   target,
        //   reason: 'step: $step \n result: $result \n target: $target',
        // );
      }
    });
  });
}
