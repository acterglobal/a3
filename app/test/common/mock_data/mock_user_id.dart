import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockUserId extends Mock implements UserId {
  final String _value;

  MockUserId(this._value);

  @override
  String toString() => _value;
}

// Utility function to create mock user IDs from str
MockUserId createMockUserId(String value) => MockUserId(value);
