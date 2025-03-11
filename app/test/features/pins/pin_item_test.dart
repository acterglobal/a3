import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import '../../helpers/mock_pins_providers.dart';
import '../../helpers/test_util.dart';

class MockOnTapPinItem extends Mock {
  void call(String pinId);
}

void main() {
  late FakeActerPin mockPin;
  late MockOnTapPinItem mockOnTapPinItem;

  setUp(() {
    mockPin = FakeActerPin();
    mockOnTapPinItem = MockOnTapPinItem();
  });

  Future<void> createWidgetUnderTest({
    required WidgetTester tester,
    bool isShowSpaceName = false,
    bool isPinIndication = false,
    Function(String)? onTapPinItem,
  }) async {
    final mockedNotifier = MockAsyncPinNotifier(shouldFail: false);
    await tester.pumpProviderWidget(
      overrides: [
        pinProvider.overrideWith(() => mockedNotifier),
        roomDisplayNameProvider.overrideWith((a, b) => 'Space Name'),
      ],
      child: PinListItemWidget(
        pinId: mockPin.eventId.toString(),
        showSpace: isShowSpaceName,
        onTaPinItem: onTapPinItem,
        showPinIndication: isPinIndication,
      ),
    );
    // Wait for the async provider to load
    await tester.pump();
  }

  testWidgets('displays pin title', (tester) async {
    await createWidgetUnderTest(tester: tester);
    expect(find.text('Pin Title'), findsOneWidget);
  });

  testWidgets('calls onTapPinItem callback when tapped', (tester) async {
    await createWidgetUnderTest(
      tester: tester,
      onTapPinItem: (mockOnTapPinItem..call('1234')).call,
    );
    await tester.tap(find.byKey(PinListItemWidget.pinItemClick));
    await tester.pump();

    verify(() => mockOnTapPinItem.call('1234')).called(1);
  });

  testWidgets('displays space name when isShowSpaceName is true', (
    tester,
  ) async {
    await createWidgetUnderTest(tester: tester, isShowSpaceName: true);

    expect(find.text('Space Name'), findsOneWidget);
  });

  testWidgets('Do not displays space name when isShowSpaceName is false', (
    tester,
  ) async {
    await createWidgetUnderTest(tester: tester, isShowSpaceName: false);

    expect(find.text('Space Name'), findsNothing);
  });

  testWidgets('displays pin indication when isPinIndication is true', (
    tester,
  ) async {
    await createWidgetUnderTest(tester: tester, isPinIndication: true);

    expect(find.text('Pin'), findsOneWidget);
    expect(find.byIcon(Atlas.pin), findsOneWidget);
  });

  testWidgets('displays pin indication when isPinIndication is true', (
    tester,
  ) async {
    await createWidgetUnderTest(tester: tester, isPinIndication: false);

    expect(find.text('Pin'), findsNothing);
    expect(find.byIcon(Atlas.pin), findsNothing);
  });
}
