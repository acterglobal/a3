import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

import '../../../common/mock_data/mock_user_id.dart';
import 'mock_message_content.dart';

class MockComment extends Fake implements Comment {
  final MockUserId fakeSender;
  final MockMsgContent fakeMsgContent;
  final int fakeOriginServerTs;

  MockComment({
    required this.fakeSender,
    required this.fakeMsgContent,
    required this.fakeOriginServerTs,
  });

  @override
  MockUserId sender() => fakeSender;

  @override
  MockMsgContent msgContent() => fakeMsgContent;

  @override
  int originServerTs() => fakeOriginServerTs;
}

class MockFfiListComment extends Mock implements FfiListComment {
  final List<MockComment> comments;

  MockFfiListComment({required this.comments});

  @override
  List<MockComment> toList({bool growable = false}) =>
      comments.toList(growable: growable);
}
