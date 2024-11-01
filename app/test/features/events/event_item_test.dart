import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/datetime/providers/utc_now_provider.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/providers/event_type_provider.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter/features/events/widgets/event_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mock_event_providers.dart';
import '../../helpers/test_util.dart';

class MockOnTapEventItem extends Mock {
  void call(String eventId);
}

void main() {
  late MockEvent mockEvent;
  late MockOnTapEventItem mockOnTapEventItem;
  late MockUtcNowNotifier mockUtcNowNotifier;
  late MockAsyncRsvpStatusNotifier mockAsyncRsvpStatusNotifier;

  setUp(() {
    mockEvent = MockEvent();
    mockOnTapEventItem = MockOnTapEventItem();
    mockUtcNowNotifier = MockUtcNowNotifier();
    mockAsyncRsvpStatusNotifier = MockAsyncRsvpStatusNotifier();
  });

  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    bool isShowRsvp = true,
    bool isShowSpaceName = false,
    Function(String)? onTapEventItem,
    EventFilters eventFilter = EventFilters.upcoming,
  }) async {
    final mockedNotifier = MockAsyncCalendarEventNotifier();
    await tester.pumpProviderWidget(
      overrides: [
        utcNowProvider.overrideWith((ref) => mockUtcNowNotifier),
        eventTypeProvider.overrideWith((ref, event) => eventFilter),
        calendarEventProvider.overrideWith(() => mockedNotifier),
        myRsvpStatusProvider.overrideWith(() => mockAsyncRsvpStatusNotifier),
        roomMembershipProvider.overrideWith((a, b) => null),
        isBookmarkedProvider.overrideWith((a, b) => false),
        roomDisplayNameProvider.overrideWith((a, b) => 'test'),
      ],
      child: EventItem(
        event: mockEvent,
        isShowRsvp: isShowRsvp,
        isShowSpaceName: isShowSpaceName,
        onTapEventItem: onTapEventItem,
      ),
    );
  }

  testWidgets('displays event title', (tester) async {
    await createWidgetUnderTest(tester: tester);
    expect(find.text('Fake Event'), findsOneWidget);
  });

  testWidgets('displays "Happening Now" indication for ongoing events',
      (tester) async {
    await createWidgetUnderTest(
      tester: tester,
      eventFilter: EventFilters.ongoing,
    );
    expect(find.text('Live'), findsOneWidget);
  });

  testWidgets('calls onTapEventItem callback when tapped', (tester) async {
    await createWidgetUnderTest(
      tester: tester,
      onTapEventItem: (mockOnTapEventItem..call('1234')).call,
    );

    await tester.tap(find.byKey(EventItem.eventItemClick));
    await tester.pumpAndSettle();

    verify(() => mockOnTapEventItem.call('1234')).called(1);
  });

  testWidgets('displays space name when isShowSpaceName is true',
      (tester) async {
    await createWidgetUnderTest(tester: tester, isShowSpaceName: true);

    expect(find.text('test'), findsOneWidget);
  });

  testWidgets('displays event date and time when isShowSpaceName is false',
      (tester) async {
    await createWidgetUnderTest(tester: tester, isShowSpaceName: false);

    final expectedDateTime =
        '${formatDate(mockEvent)} (${formatTime(mockEvent)})';
    expect(find.text(expectedDateTime), findsOneWidget);
  });
}
