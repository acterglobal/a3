import 'package:acter/features/read_receipts/providers/read_receipts.dart';
import 'package:acter/features/read_receipts/widgets/read_counter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/error_helpers.dart';
import '../../helpers/mock_read_receipt_providers.dart';
import '../../helpers/test_util.dart';

void main() {
  group('ReadReceipt Widget', () {
    testWidgets('Shows Count', (tester) async {
      await tester.pumpProviderWidget(
        overrides: [
          readReceiptsManagerProvider
              .overrideWith(() => MockAsyncReadReceiptsManagerNotifier()),
        ],
        child: ReadCounterWidget(
          manager: Future.value(MockReadReceiptsManager(count: 10)),
        ),
      );
      await tester.pump();
      expect(find.text('10'), findsOneWidget);
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
}
