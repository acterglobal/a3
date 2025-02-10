import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationSender extends Mock implements NotificationSender {
  final String username;
  final String? name;

  MockNotificationSender({this.username = "@none:user.tld", this.name});

  @override
  String userId() => username;

  @override
  String? displayName() => name;
}

class MockMsgContent extends Mock implements MsgContent {
  final String content;

  MockMsgContent({required this.content});

  @override
  String body() => content;
}
