import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_id.dart';
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
    test('.build()', () {
      MessageBuild message = MessageBuild(
        syn: FieldSyn.def(),
        id: FieldId.def(),
        kind: FieldKind.string,
        size: FieldSize.def(),
        data: FieldData([]),
      );
      final List<(int, bool, int, List<int>, FieldKind, List<int>)> testData = [
        (01,  keepGo, 3755744309, [25, 26],                                 FieldKind.string, [syn, 0xDF, 0xDC, 0x1C, 0x35, FieldKind.string.kind, 00, 00, 00, 02, 25, 26] ),
        (02,  keepGo, 1981952532, [62, 63, 64, 65],                         FieldKind.string, [syn, 0x76, 0x22, 0x32, 0x14, FieldKind.string.kind, 00, 00, 00, 04, 62, 63, 64, 65]),
        (03, restart,  208151755, [62, 63, 64, 65, 66, 67, 68, 69, 70, 71], FieldKind.uint16, [syn, 0x0C, 0x68, 0x24, 0xCB, FieldKind.uint16.kind, 00, 00, 00, 10, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71]),
        (04, restart, 2729228274, [for(var i=62; i<=319; i+=1) i],          FieldKind.int64,  [syn, 0xA2, 0xAC, 0xB7, 0xF2, FieldKind.int64.kind,  00, 00, 01, 02, 62, 63, ...[for(var i=64; i<=317; i+=1) i], 318, 319]),
        (04, restart, 4294967295, [for(var i=62; i<=319; i+=1) i],          FieldKind.int64,  [syn, 0xFF, 0xFF, 0xFF, 0xFF, FieldKind.int64.kind,  00, 00, 01, 02, 62, 63, ...[for(var i=64; i<=317; i+=1) i], 318, 319]),
      ];
      for (final (step, restart, id, bytes, kind, target) in testData) {
        if (restart) {
          message = MessageBuild(
            syn: FieldSyn.def(),
            id: FieldId.def(),
            kind: kind,
            size: FieldSize.def(),
            data: FieldData([]),
          );
        }
        final result = message.build(bytes, id: id);
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
// 12345678901  0xDF DC 1C 35
// 23456789012  0x76 22 32 14
// 34567890123  0x0C 68 24 CB
// 45678901234  0xA2 AC B7 F2