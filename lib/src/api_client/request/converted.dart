import 'package:hmi_core/hmi_core_result_new.dart';
///
abstract interface class Converted<I, O> {
  ///
  ResultF<O> valueFrom(I input);
}