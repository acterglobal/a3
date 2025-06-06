import 'package:acter/features/events/providers/notifiers/event_location_notifiers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:mocktail/mocktail.dart';

class MockEventDraftLocationsNotifier extends EventDraftLocationsNotifier {
  MockEventDraftLocationsNotifier() : super();
}

class MockEventLocationInfo extends Mock implements EventLocationInfo {}
