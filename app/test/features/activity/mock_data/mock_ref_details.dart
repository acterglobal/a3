import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockRefDetails extends Mock implements RefDetails {
  final String mockTitle;
  final String mockType;

  MockRefDetails({
    required this.mockTitle,
    required this.mockType,
  });

  @override
  String title() => mockTitle;

  @override
  String typeStr() => mockType;
}
