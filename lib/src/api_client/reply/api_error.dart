///
/// Contains errors from API
class ApiError {
  // final _log = Log('ApiError');
  final Map<String, dynamic>? _errors;
  ///
  ApiError({
    required Map<String, dynamic>? errors,
  }) : 
    _errors = errors;
  ///
  /// Returns error message
  String get message => _errors?['message'] ?? '';
  ///
  /// Returns error details
  String get details => _errors?['details'] ?? '';
  ///
  /// Returns true if no errors
  bool get isEmpty {
    return message.isEmpty && details.isEmpty;
  }
  ///
  /// Returns true if at least one error exists
  bool get isNotEmpty {
    return !isEmpty;
  }
  //
  @override
  String toString() {
    return '''$ApiError {
\t\tmessage: $message;
\t\tdetails: $details;
\t}''';
  }
}
