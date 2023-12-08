class ApiAddress {
  final String _host;
  final int _port;
  ///
  const ApiAddress({
    required String host,
    required int port,
  }) : 
    _host = host,
    _port = port;
  ///
  const ApiAddress.localhost({
    int port = 8899,
  }) : 
    _host = '127.0.0.1',
    _port = port;
  ///
  String get host => _host;
  ///
  int get port => _port;
}