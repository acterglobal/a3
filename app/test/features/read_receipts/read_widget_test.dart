import 'package:acter/features/read_receipts/providers/read_receipts.dart';
import 'package:acter/features/read_receipts/widgets/read_counter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/error_helpers.dart';
import '../../helpers/mock_read_receipt_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('ReadReceipt Widget', () {
    testWidgets('Shows Count', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          readReceiptsManagerProvider.overrideWith(
            () => MockAsyncReadReceiptsManagerNotifier(),
          ),
        ],
        child: ReadCounterWidget(
          manager: Future.value(MockReadReceiptsManager(count: 10)),
        ),
      );
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('Make sure Count is independent', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          readReceiptsManagerProvider.overrideWith(
            () => MockAsyncReadReceiptsManagerNotifier(),
          ),
        ],
        child: Column(
          children: [
            ReadCounterWidget(
              manager: Future.value(MockReadReceiptsManager(count: 10)),
            ),
            ReadCounterWidget(
              manager: Future.value(MockReadReceiptsManager(count: 25)),
            ),
            ReadCounterWidget(
              manager: Future.value(MockReadReceiptsManager(count: 0)),
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('Retry on failure', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          readReceiptsManagerProvider.overrideWith(
            () => MockAsyncReadReceiptsManagerNotifier(shouldFail: true),
          ),
        ],
        child: ReadCounterWidget(
          manager: Future.value(MockReadReceiptsManager(count: 10)),
        ),
      );
      await tester.pump();
      expect(find.text('error'), findsOneWidget);
      await tester.ensureInlineErrorWithRetryWorks();
    });
  });

  testWidgets('triggers seen after expected time', (tester) async {
    final manager = MockReadReceiptsManager(count: 19);
    when(manager.announceRead).thenAnswer((_) async => true);
    await tester.pumpProviderWidget(
      overrides: [
        readReceiptsManagerProvider.overrideWith(
          () => MockAsyncReadReceiptsManagerNotifier(),
        ),
      ],
      child: ReadCounterWidget(
        manager: Future.value(manager),
        triggerAfterSecs: 3,
      ),
    );
    await tester.pump();
    expect(find.text('19'), findsOneWidget);
    // not yet called
    verifyNever(() => manager.announceRead());
    await tester.pump(const Duration(seconds: 2));
    verifyNever(() => manager.announceRead());
    await tester.pump(const Duration(seconds: 2));
    verify(() => manager.announceRead()).called(1);
  });

  testWidgets('triggers not if already seen', (tester) async {
    final manager = MockReadReceiptsManager(count: 2, haveIseen: true);
    when(manager.announceRead).thenAnswer((_) async => true);
    await tester.pumpProviderWidget(
      overrides: [
        readReceiptsManagerProvider.overrideWith(
          () => MockAsyncReadReceiptsManagerNotifier(),
        ),
      ],
      child: ReadCounterWidget(
        manager: Future.value(manager),
        triggerAfterSecs: 3,
      ),
    );
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    // not yet called
    verifyNever(() => manager.announceRead());
    await tester.pump(const Duration(seconds: 2));
    verifyNever(() => manager.announceRead());
    await tester.pump(const Duration(seconds: 2));
    verifyNever(() => manager.announceRead());
  });
}
