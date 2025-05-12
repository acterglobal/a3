import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockDescriptionContent extends Mock implements DescriptionContent {
  final String mockChange;
  final String? mockNewVal;

  MockDescriptionContent({required this.mockChange, this.mockNewVal});

  @override
  String change() => mockChange;

  @override
  String? newVal() => mockNewVal;
}
