import 'package:ext_rw/src/api_client/message/parse_syn.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
///
const int syn = 22;
const restart = true;
const keepGo = false;
///
/// Testing [ParseSyn].parse
void main() {
  group('FieldSyn.parse', () {
    test('.parse()', () async {
      ParseSyn fieldSyn = ParseSyn.def();
      final testData = [
        (01,  keepGo, [ 11,  12, syn, 13, 14], Some(null), [13, 14]),
        (02,  keepGo, [ 21,  23,  24, 25, 26], Some(null), [21,  23,  24, 25, 26]),
        (03, restart, [ 31, syn,  33, 34, 35], Some(null), [33, 34, 35]),
        (04, restart, [ 41,  43,  44, 45, 46], None(    ), []),
        (05,  keepGo, [syn,  53,  55, 55, 56], Some(null), [53,  55, 55, 56]),
        (06,  keepGo, [ 61,  62,  63, 64, 65], Some(null), [61,  62,  63, 64, 65]),
      ];
      for (final (step, restart, bytes, target, targetBytes) in testData) {
        if (restart) {
          fieldSyn = ParseSyn.def();
        }
        final (result, resultBytes) = fieldSyn.parse(bytes);
        switch (target) {
          case Some():
            expect(
              result,
              isA<Some>(),
              reason: 'step: $step \n result: $result \n target: $target',
            );
          case None():
            expect(
              result,
              isA<None>(),
              reason: 'step: $step \n result: $result \n target: $target',
            );
        }
        expect(
          listEquals(resultBytes, targetBytes),
          true,
          reason: 'step: $step \n result: $resultBytes \n target: $targetBytes',
        );
      }
    });
  });
}
