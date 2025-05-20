import 'package:acter/features/chat_ui_showcase/mocks/general/mock_userId.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockReactionRecord extends Mock implements ReactionRecord {
  final MockUserId mockSenderId;
  final int mockTimestamp;
  final bool mockSentByMe;

  MockReactionRecord({
    required this.mockSenderId,
    required this.mockTimestamp,
    required this.mockSentByMe,
  });

  @override
  UserId senderId() => mockSenderId;

  @override
  int timestamp() => mockTimestamp;

  @override
  bool sentByMe() => mockSentByMe;
}
