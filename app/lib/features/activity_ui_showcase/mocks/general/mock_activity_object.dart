import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class ActivityMockObject extends Mock implements ActivityObject {
  final String mockType;
  final String? mockObjectId;
  final String? mockTitle;
  final String? mockEmoji;

  ActivityMockObject({
    required this.mockType,
    this.mockObjectId,
    this.mockTitle,
    this.mockEmoji,
  });

  @override
  String typeStr() => mockType;

  @override
  String objectIdStr() => mockObjectId ?? 'object-id';

  @override
  String? title() => mockTitle ?? '';

  @override
  String emoji() => mockEmoji ?? '🚀';
}