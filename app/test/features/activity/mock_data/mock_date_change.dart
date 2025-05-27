import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockDateContent extends Mock implements DateContent {
  final String mockChange;
  final String? mockNewVal;

  MockDateContent({required this.mockChange, this.mockNewVal});

  @override
  String change() => mockChange;

  @override
  String? newVal() => mockNewVal;
}
