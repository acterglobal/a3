import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockActivityObject extends Mock implements ActivityObject {
  final String mockType;
  final String mockObjectId;
  final String? mockTitle;
  final String mockEmoji;

  MockActivityObject({
    required this.mockType,
    required this.mockObjectId,
    required this.mockTitle,
    required this.mockEmoji,
  });

  @override
  String typeStr() => mockType;

  @override
  String objectIdStr() => mockObjectId;

  @override
  String? title() => mockTitle;

  @override
  String emoji() => mockEmoji;
}
