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
        (01,  keepGo, 123456, [25, 26],                                 FieldKind.string, [syn, 0x00, 0x01, 0xE2, 0x40, FieldKind.string.kind, 00, 00, 00, 02, 25, 26] ),
        (02,  keepGo, 234567, [62, 63, 64, 65],                         FieldKind.string, [syn, 0x00, 0x03, 0x94, 0x47, FieldKind.string.kind, 00, 00, 00, 04, 62, 63, 64, 65]),
        (03, restart, 345678, [62, 63, 64, 65, 66, 67, 68, 69, 70, 71], FieldKind.uint16, [syn, 0x00, 0x05, 0x46, 0x4E, FieldKind.uint16.kind, 00, 00, 00, 10, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71]),
        (04, restart, 456789, [for(var i=62; i<=319; i+=1) i],          FieldKind.int64,  [syn, 0x00, 0x06, 0xF8, 0x55, FieldKind.int64.kind,  00, 00, 01, 02, 62, 63, ...[for(var i=64; i<=317; i+=1) i], 318, 319]),
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
