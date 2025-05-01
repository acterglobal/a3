import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockUserId extends Mock implements UserId {
  final String? mockUserId;
  MockUserId({this.mockUserId});

  @override
  String toString() => mockUserId ?? 'userId';
}
