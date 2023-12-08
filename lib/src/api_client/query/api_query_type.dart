abstract class ApiQueryType {
  bool valid();
  ///
  Map<String, dynamic> buildJson();
  ///
  String get id;
}