import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockOptionString extends Mock implements OptionString {
  final String? mockText;

  MockOptionString({this.mockText});

  @override
  String? text() => mockText;
}
