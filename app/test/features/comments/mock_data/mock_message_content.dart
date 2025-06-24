import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockMsgContent extends Mock implements MsgContent {
  final String bodyText;
  final String? mockFormattedBody;

  MockMsgContent({required this.bodyText, this.mockFormattedBody});

  @override
  String body() => bodyText;

  @override
  String? formattedBody() => mockFormattedBody;
}
