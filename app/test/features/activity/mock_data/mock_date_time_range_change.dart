import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockUtcDateTime extends Mock implements UtcDateTime {
  @override
  int timestamp() => 1710000000; // Mocked Unix timestamp

  @override
  int timestampMillis() => 1710000000000; // Mocked timestamp in milliseconds

  @override
  String toRfc3339() => '2025-03-17T12:00:00Z'; // Mocked date-time string

  @override
  String toRfc2822() => 'Sun, 9 Mar 2025 12:00:00 +0000'; // Mocked date-time format
}

class MockDateTimeRangeContent extends Mock implements DateTimeRangeContent {
  @override
  UtcDateTime? startNewVal() => MockUtcDateTime(); // Mocked new value

  @override
  UtcDateTime? endNewVal() => null; // Mocked new value
}
