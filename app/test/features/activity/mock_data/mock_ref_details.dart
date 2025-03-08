import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockRefDetails extends Mock implements RefDetails {
  final String mockTitle;
  final String mockType;
  final String? mockTargetId;

  MockRefDetails({
    required this.mockTitle,
    required this.mockType,
    this.mockTargetId,
  });

  @override
  String title() => mockTitle;

  @override
  String typeStr() => mockType;

  @override
  String? targetIdStr() => mockTargetId;
}
