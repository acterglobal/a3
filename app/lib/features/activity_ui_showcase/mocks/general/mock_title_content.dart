// Mock title content to show title changes
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockTitleContent extends Mock implements TitleContent {
  final String mockChange;
  final String mockNewVal;

  MockTitleContent({required this.mockChange, required this.mockNewVal});

  @override
  String change() => mockChange;

  @override
  String newVal() => mockNewVal;
}
