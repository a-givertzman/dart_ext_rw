part of 'message.dart';

///
/// Switch [Socket] or [WebSocket]
abstract class _AnySocket {
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  });
  ///
  /// Adds byte [data] to the associated socket.
  void add(List<int> data);
  ///
  /// Returns a [Future] that completes once all buffered data is accepted by the underlying [StreamConsumer].
  /// 
  /// This method must not be called while an [addStream] is incomplete.
  ///
  /// NOTE: This is not necessarily the same as the data being flushed by the operating system.
  Future<dynamic> flush();
  ///
  /// Closes associated socket
  Future<dynamic> close();
}
