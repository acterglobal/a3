import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/features/bookmarks/providers/bookmarks_provider.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/pins/widgets/pin_list_item_widget.dart';
import 'package:acter/features/pins/widgets/pin_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/error_helpers.dart';
import '../../helpers/mock_pins_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  late FakeActerPin mockPin;
  setUp(() {
    mockPin = FakeActerPin();
  });

  group('Pin List', () {
    testWidgets('displays empty state when there are no pins', (tester) async {
      //Arrange:
      var emptyState = Text('empty state');
      final provider = FutureProvider<List<ActerPin>>((ref) async => []);

      // Build the widget tree with an empty provider
      await tester.pumpProviderWidget(
        child: PinListWidget(pinListProvider: provider, emptyState: emptyState),
      );

      // Act
      await tester.pumpAndSettle(); // Allow the widget to settle

      // Assert
      expect(
        find.text('empty state'),
        findsOneWidget,
      ); // Ensure the empty state widget is displayed
    });

    testWidgets(
      'displays error state when there is issue in loading pin list',
      (tester) async {
        bool shouldFail = true;

        final provider = FutureProvider<List<ActerPin>>((ref) async {
          if (shouldFail) {
            shouldFail = false;
            throw 'Some Error';
          } else {
            return [];
          }
        });

        // Build the widget tree with the mocked provider
        await tester.pumpProviderWidget(
          child: PinListWidget(pinListProvider: provider),
        );
        await tester.ensureErrorPageWithRetryWorks();
      },
    );
  });

  testWidgets('displays list of pins when data is available', (tester) async {
    // Arrange
    final pinNotifier = RetryMockAsyncPinNotifier();
    final mockPin1 = FakeActerPin(pinTitle: 'Fake Pin1');
    final mockPin2 = FakeActerPin(pinTitle: 'Fake Pin2');
    final mockPin3 = FakeActerPin(pinTitle: 'Fake Pin3');

    final finalListProvider = FutureProvider<List<ActerPin>>(
      (ref) async => [mockPin1, mockPin2, mockPin3],
    );

    // Build the widget tree with the mocked provider
    await tester.pumpProviderWidget(
      overrides: [
        roomMembershipProvider.overrideWith((a, b) => null),
        isBookmarkedProvider.overrideWith((a, b) => false),
        roomDisplayNameProvider.overrideWith((a, b) => 'test'),
        pinsProvider.overrideWith((ref, pin) => []),
        pinListProvider.overrideWith((r, a) => [mockPin]),
        pinProvider.overrideWith(() => pinNotifier),
      ],
      child: PinListWidget(pinListProvider: finalListProvider),
    );
    // Initial build
    await tester.pump();

    // Wait for async operations
    await tester.pump(const Duration(seconds: 1));

    expect(
      find.byType(PinListItemWidget),
      findsNWidgets(3),
      reason: 'Should find 3 PinItem widgets',
    );
  });
}
