import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockFfiString extends Mock implements FfiString {
  final String value;

  MockFfiString(this.value);

  @override
  String toDartString() => value;

  @override
  String toString() => value;
}
