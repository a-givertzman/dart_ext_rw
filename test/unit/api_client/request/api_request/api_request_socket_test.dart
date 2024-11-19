import 'dart:convert';
import 'dart:io';

import 'package:ext_rw/ext_rw.dart';
import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_id.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:ext_rw/src/api_client/message/parse_data.dart';
import 'package:ext_rw/src/api_client/message/parse_id.dart';
import 'package:ext_rw/src/api_client/message/parse_kind.dart';
import 'package:ext_rw/src/api_client/message/parse_size.dart';
import 'package:ext_rw/src/api_client/message/parse_syn.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';
import 'package:hmi_core/hmi_core_option.dart';
///
/// For testing only
class FakeApiQueryType implements ApiQueryType {
  final bool _valid;
  final String _query;
  ///
  /// For testing only
  FakeApiQueryType({
    required bool valid,
    required String query,
  })  : _valid = valid,
        _query = query;
  //
  @override
  bool valid() => _valid;
  //
  @override
  String buildJson({String authToken = '', bool debug = false}) => _query;
  ///
  /// insert directly into _query in fake implementation
  @override
  String get id => '';
}

void main() {
  Log.initialize(level: LogLevel.all);
  final log = Log('Test:MessageBuild');
  group('ApiRequest socket', () {
    late ApiAddress address;
    late ServerSocket serverSocket;
    setUp(() async {
      // bind socket server to unused port and start listening
      serverSocket = await ServerSocket.bind(
        InternetAddress.loopbackIPv4.host,
        0,
      );
      // respond with received data
      serverSocket.listen((socket) {
        socket.listen((bytes) {
          final messageRcv = ParseData(
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
          final (id, kind, size, data) = messageRcv.parse(bytes).unwrap();
          log.debug('ServerSocket.listen | id: $id,  kind: $kind,  size: $size,  data: ${data.take(16).toList()}...');
          final query = String.fromCharCodes(data);
          log.debug('ServerSocket.listen | query: $query');
          if (query == 'timeout') {
            log.debug('ServerSocket.listen | Timeout requested');
            sleep(Duration(seconds: 5));
          } else if (query == 'error') {
            log.debug('ServerSocket.listen | error requested');
            socket.add([0, 1]);
          } else {
            final messageSend = MessageBuild(
              syn: FieldSyn.def(),
              id: FieldId.def(),
              kind: FieldKind.string,
              size: FieldSize.def(),
              data: FieldData([]),
            );
            socket.add(messageSend.build(data, id: id.id));
          }
        });
      });
      address = ApiAddress(
        host: serverSocket.address.host,
        port: serverSocket.port,
      );
    });
    test('.fetch() with valid query', () async {
      final queryList = [
        '{"authToken": "testToken", "id": "testID", "query": "testQuery", "data": []}',
        '{"authToken": "testToken", "id": "testID", "query": "testQuery", "data": [{"stringDataKey":"dataValue"}]}',
        '{"authToken": "testToken", "id": "testID", "query": "testQuery", "data": [{"booleanDataKey":true}]}',
        '{"authToken": "testToken", "id": "testID", "query": "testQuery", "data": [{"listDataKey":[1,"2",{"lik":"liv"},[]]}]}',
      ];
      for (final query in queryList) {
        final apiRequest = ApiRequest(
          address: address,
          authToken: '+++',
          query: FakeApiQueryType(
            valid: true,
            query: query,
          ),
        );
        final stopwatch = Stopwatch()..start();
        final result = await apiRequest.fetch();
        log.debug('Fetch done, elapsed: ${stopwatch.elapsed}');        
        expect(
          result,
          isA<Ok>(),
          reason: 'valid api request should return Ok as Result',
        );
        final reply = result.unwrap();
        final replyAsJson = '{"authToken": "${reply.authToken}", "id": "${reply.id}", "query": "${reply.sql}", "data": ${json.encode(reply.data)}}';
        expect(
          replyAsJson,
          query,
          reason: 'data should be transferred correctly',
        );
      }
    });
    ///
    test('.fetch() with invalid query', () async {
      final queryList = [
        (01, 'timeout', isA<Err>()),
        (02, 'error', isA<Err>()),
      ];
      for (final (step, query, target) in queryList) {
        final apiRequest = ApiRequest(
          address: address,
          authToken: '+++',
          query: FakeApiQueryType(
            valid: false,
            query: query,
          ),
        );
        final result = await apiRequest.fetch();
        log.debug('.fetch() with invalid query | result: $result');
        expect(
          result,
          target,
          reason: '.fetch() with invalid query | step: $step, \n result: $result \n target: $target',
        );
      }
    });
    //
    tearDown(() async {
      serverSocket.close();
    });
  });
}
