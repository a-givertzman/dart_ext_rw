import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_log.dart';
///
/// setup constants
const int syn = 22;
const restart = true;
const keepGo = false;
///
/// Testing [MessageBuild].parse
void main() {
  Log.initialize(level: LogLevel.all);
  final log = Log('Test:MessageBuild');
  group('MessageBuild.build', () {
    test('.build()', () async {
      MessageBuild message = MessageBuild(
        syn: FieldSyn.def(),
        kind: FieldKind.string,
        size: FieldSize(),
        data: FieldData([]),
      );
      final List<(int, bool, List<int>, FieldKind, List<int>)> testData = [
        (01,  keepGo, [25, 26],                                 FieldKind.string, [syn, FieldKind.string.kind, 00, 00, 00, 02, 25, 26] ),
        (02,  keepGo, [62, 63, 64, 65],                         FieldKind.string, [syn, FieldKind.string.kind, 00, 00, 00, 04, 62, 63, 64, 65]),
        (03, restart, [62, 63, 64, 65, 66, 67, 68, 69, 70, 71], FieldKind.uint16, [syn, FieldKind.uint16.kind, 00, 00, 00, 10, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71]),
        (04, restart, [for(var i=62; i<=319; i+=1) i],          FieldKind.int64,  [syn, FieldKind.int64.kind,  00, 00, 01, 02, 62, 63, ...[for(var i=64; i<=317; i+=1) i], 318, 319]),
      ];
      for (final (step, restart, bytes, kind, target) in testData) {
        if (restart) {
          message = MessageBuild(
            syn: FieldSyn.def(),
            kind: kind,
            size: FieldSize(),
            data: FieldData([]),
          );
        }
        final result = message.build(bytes);
        log.debug('.parse | step: $step,  result.length: ${result.length}');
        log.debug('.parse |           target.length: ${target.length}');
        expect(
          listEquals(result, target),
          true,
          reason: 'step: $step \n result: $result \n target: $target',
        );
      }
    });
  });
}
