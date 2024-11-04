import 'package:ext_rw/src/api_client/message/field_kind.dart';
import 'package:ext_rw/src/api_client/message/field_size.dart';
import 'package:ext_rw/src/api_client/message/field_syn.dart';

enum MessageField {
  syn(FieldSyn),
  kind(FieldKind),
  size(FieldSize);
  const MessageField(this._value);
  final _value;
}