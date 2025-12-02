import 'dart:typed_data';

import 'package:ext_rw/src/api_client/message/field_const.dart';
import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/find_fixed.dart';
import 'package:ext_rw/src/api_client/message/message_parse.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/parse_fixed.dart';
import 'package:ext_rw/src/api_client/message/parse_sized.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_option.dart';
import 'package:hmi_core/hmi_core_result.dart';
///
/// setup constants
const int syn = 22;
const restart = true;
const keepGo = false;
///
/// Testing [ParseSized].parse
void main() {
  Log.initialize(level: LogLevel.all);
  final log = Log('Test:ParseSized');
  group('ParseSized.parse', () {
    test('.parse()', () async {
      final parseSized = ParseSized(
        size: (_, FieldSize size) => size.size,
        fromBytes: (Bytes bytes) => Ok(bytes),
        field: ParseFixed<((Null, Null), FieldId), FieldKind, FieldSize>(
          size: 4,
          fromBytes: (Bytes bytes) => switch (FieldSize(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
            Ok(:final value) => Ok(FieldSize(value)),
            Err() => Err(null),
          },
          field: ParseFixed<(Null, Null), FieldId, FieldKind>(
            size: 1,
            fromBytes: (Bytes bytes) => switch (FieldKind.from(bytes[0])) {
              Ok(:final value) => Ok(value),
              Err() => Err(null),
            },
            field: ParseFixed<Null, Null, FieldId>(
              size: 4,
              fromBytes: (Bytes bytes) {
                return switch (FieldId(0, len: 4, endian: Endian.big).fromBytes(bytes)) {
                  Ok(:final value) => Ok(FieldId(value)),
                  Err() => Err(null),
                };
              },
              field: FindFixed(FieldConst.fromU8(syn)),
              ),
          ),
        ),
      );
      final List<(int, bool, List<int>, Option<(FieldId, FieldKind, int)>, List<int>)> testData = [
        (01,  keepGo, [ 11,  12, syn, 00, 00, 00, 11,  40,  00], None(                       ), []),
        (02,  keepGo, [ 00,  00,  02, 25, 26], Some((FieldId(11), FieldKind.string,   2)), [25, 26]),
        (03,  keepGo, [ 31, syn,  00, 00, 00, 12, 40, 00, 00], None(                       ), []),
        (04, restart, [ 00,  03,  44, 45, 46], None(                       ), []),
        (05,  keepGo, [syn,  00,  00, 00, 13,  40,  00, 00, 00], None(                       ), []),
        (06,  keepGo, [ 04,  62,  63, 64, 65], Some((FieldId(13), FieldKind.string,   4)), [62,  63, 64, 65]),
        (07,  keepGo, [syn,  00,  00, 00, 14,  40,  00, 00, 00], None(                       ), []),
        (08,  keepGo, [ 10,  62,  63, 64, 65], None(                       ), []),
        (09,  keepGo, [ 66,  67,  68, 69, 70], None(                       ), []),
        (10,  keepGo, [ 71                  ], Some((FieldId(14), FieldKind.string,  10)), [62, 63, 64, 65, 66, 67, 68, 69, 70, 71]),
        (11,  keepGo, [syn,  00,  00, 00, 15,  40,  00, 00, 01], None(                       ), []),
        (12,  keepGo, [ 135,  62,  63, 64, 65], None(                       ), []),
        (13,  keepGo, [ 66,  67,  68, 69, 70], None(                       ), []),
        (14,  keepGo, [ 71,  72,  73, 74, 75], None(                       ), []),
        (15,  keepGo, [for(var i=76; i<=255; i+=1) i], None(                ), []),
        (16,  keepGo, [for(var i=254; i>=61; i-=1) i], None(                ), []),
        (17,  keepGo, [60, 59, 58        ], Some((FieldId(15), FieldKind.string,  391)), [...[for(var i=62; i<=255; i+=1) i], ...[for(var i=254; i>=58; i-=1) i]]),
        (18,  keepGo, [syn,  00, 00, 00, 77, 40,  00, 00, 00, 9,  62, 63, 64, 65, 66, 67, 68, 69, 70, syn, 00, 00, 00, 88, 08, 00, 00, 00, 03, 25, 26, 27], Some((FieldId(77), FieldKind.string, 9)), [62,  63, 64, 65, 66,  67,  68, 69, 70]),
        (19,  keepGo, [], Some((FieldId(88), FieldKind.bool, 3)), [25, 26, 27]),
      ];
      final remains = BytesBuilder(copy: true);
      for (final (step, restart, bytes, target, targetBytes) in testData) {
        log.debug(' | step $step,  targetBytes.length: ${targetBytes.length}');
        if (restart) {
          parseSized.reset();
        }
        remains.add(bytes);
        switch (parseSized.parse(remains.takeBytes())) {
          // <(((Null, Null), FieldId), FieldKind), FieldSize, Ok<List<int>, dynamic>>
          case Some<(((((Null, Null), FieldId), FieldKind), FieldSize), Ok<Bytes, dynamic>, Bytes)>(  value: (((((null, null), FieldId id), FieldKind kind), FieldSize size), Result<Bytes, dynamic> resultBytes, Bytes remainder)  ):
            remains.add(remainder);
            log.debug(' | step $step \n result: id $id, kind $kind, size $size, bytes $resultBytes, \n target: $target');
            log.debug(' | step $step \n remainder: $remainder');
            final targetId = target.expect('Step $step').$1;
            final targetKind = target.expect('Step $step').$2;
            final targetSize = target.expect('Step $step').$3;
            expect(
              target,
              isA<Some>(),
              reason: 'step $step \n result: Some() \n target: $target',
            );
            expect(
              id,
              targetId,
              reason: 'step $step \n result: $id \n target: $targetId',
            );
            expect(
              kind,
              targetKind,
              reason: 'step $step \n result: $kind \n target: $targetKind',
            );
            expect(
              size.size,
              targetSize,
              reason: 'step $step \n result: ${size.size} \n target: $targetSize',
            );
            switch (resultBytes) {
              case Ok<Bytes, dynamic>(value: final result):
                expect(
                  listEquals(result, targetBytes),
                  true,
                  reason: 'step $step \n result: $result \n target: $targetBytes',
                );
              case Err<Bytes, dynamic>(:final error):
                throw Exception('step $step \n result: $error \n target: $targetBytes');
            }
          case None():
            expect(
              target,
              isA<None>(),
              reason: 'step $step \n result: None() \n target: $target',
            );
        }
      }
    });
  });
}
