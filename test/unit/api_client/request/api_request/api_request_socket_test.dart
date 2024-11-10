import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ext_rw/ext_rw.dart';
import 'package:ext_rw/src/api_client/message/field_data.dart';
import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';
import 'package:ext_rw/src/api_client/message/message_build.dart';
import 'package:ext_rw/src/api_client/message/parse_data.dart';
import 'package:ext_rw/src/api_client/message/parse_kind.dart';
import 'package:ext_rw/src/api_client/message/parse_size.dart';
import 'package:ext_rw/src/api_client/message/parse_syn.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hmi_core/hmi_core_log.dart';
import 'package:hmi_core/hmi_core_result.dart';
import 'package:hmi_core/hmi_core_option.dart';

class FakeApiQueryType implements ApiQueryType {
  final bool _valid;
  final String _query;

  FakeApiQueryType({
    required bool valid,
    required String query,
  })  : _valid = valid,
        _query = query;

  @override
  bool valid() => _valid;

  @override
  String buildJson({String authToken = '', bool debug = false}) => _query;

  // insert directly into _query in fake implementation
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
                field: ParseSyn.def(),
              ),
            ),
          );
          final (kind, size, data) = messageRcv.parse(bytes).unwrap();
          final messageSend = MessageBuild(
            syn: FieldSyn.def(),
            kind: FieldKind.string,
            size: FieldSize.def(),
            data: FieldData(Uint8List(0)),
          );
          socket.add(messageSend.build(data));
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
        '',
      ];
      for (final query in queryList) {
        final apiRequest = ApiRequest(
          address: address,
          authToken: '+++',
          query: FakeApiQueryType(
            valid: false,
            query: query,
          ),
        );
        final result = await apiRequest.fetch();
        expect(
          result,
          isA<Err>(),
          reason: 'Api request with invalid query should return Err as Result',
        );
      }
    });
    //
    tearDown(() async {
      serverSocket.close();
    });
  });
}
