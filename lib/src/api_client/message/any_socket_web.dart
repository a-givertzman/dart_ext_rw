part of 'message.dart';

///
/// Wrapping a web socket
class _AnySocketWeb implements _AnySocket {
  final _log = Log('_AnySocketWeb');
  final WebSocket _socket;
  ///
  ///
  _AnySocketWeb(WebSocket socket):
    _socket = socket;
  ///
  ///
  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    _log.debug('.listen | ...');
    return _socket.events
      .where((WebSocketEvent event) {
        switch (event) {
          case BinaryDataReceived():
            return true;
          // case CloseReceived():
            // _log.debug('.listen | CloseReceived: $code');
            // return true;
          default:
            return false;
        }
      })
      .map<List<int>>((event) {
        switch (event) {
          case TextDataReceived(:final text):
            _log.warn('.listen | TextDataReceived - not supported for now \n\t$text');
          case BinaryDataReceived(:final data):
            // _log.trace('.listen | BinaryDataReceived \n\t$data');
            return data;
          // case CloseReceived(:final code):
          //   _log.debug('.listen | CloseReceived: $code');
          default:
        }
        return [];
      })
      .listen(
        (event) {
          // _log.trace('.listen | event: $event');
          onData?.call(event);
        },
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );
  }
  ///
  /// Sends binary data to the connected peer.
  /// 
  /// Throws [WebSocketConnectionClosed] if the [WebSocket] is closed (either through [close] or by the peer).
  /// 
  /// Data sent through [sendBytes] will be silently discarded if the peer is disconnected but the disconnect has not yet been detected.
  @override
  void add(data) {
    return _socket.sendBytes(Uint8List.fromList(data));
  }
  ///
  /// Do nothing for the web socket
  @override
  Future<dynamic> flush() {
    return Future.value(null);
  }
  ///
  /// Closes the WebSocket connection and the [events] Stream.
  /// 
  /// Sends a Close frame to the peer. If the optional [code] and [reason] arguments are given, they will be included in the Close frame. If no [code] is set then the peer will see a 1005 status code. If no [reason] is set then the peer will not receive a reason string.
  /// 
  /// Throws an [ArgumentError] if [code] is not 1000 or in the range 3000-4999.
  /// 
  /// Throws an [ArgumentError] if [reason] is longer than 123 bytes when encoded as UTF-8
  /// 
  /// Throws [WebSocketConnectionClosed] if the connection is already closed (including by the peer).
  @override
  Future<dynamic> close() {
    return _socket.close();
  }
}
