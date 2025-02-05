import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_a3sdk.dart';
import '../../helpers/mock_client_provider.dart';

void main() {
  group('Always Client Provider tests', () {
    testWidgets('is pending on none', (tester) async {
      final container = ProviderContainer(
        overrides: [
          // no client
          clientProvider.overrideWith(() => MockClientNotifier(client: null)),
        ],
      );
      await expectLater(
        container.read(alwaysClientProvider.future),
        doesNotComplete,
      );
      expect(container.read(alwaysClientProvider).isLoading, true);
      await container.pump();
      await expectLater(
        container.read(alwaysClientProvider.future),
        doesNotComplete,
      );
      expect(container.read(alwaysClientProvider).isLoading, true);
      await tester.pumpAndSettle();
    });

    testWidgets('future updates on set', (tester) async {
      final provider = MockClientNotifier(client: null);
      final container = ProviderContainer(
        overrides: [
          // no client
          clientProvider.overrideWith(() => provider),
        ],
      );
      // it updates
      final ftr = container.read(alwaysClientProvider.future);
      expect(container.read(alwaysClientProvider).isLoading, true);
      final cl = MockClient();

      provider.state = AsyncValue.data(cl);
      expect(container.read(alwaysClientProvider).isLoading, false);
      expect(container.read(alwaysClientProvider).value, cl);

      expect(ftr, completes);
      await tester.pumpAndSettle();
    });

    testWidgets('double set and reset', (tester) async {
      final provider = MockClientNotifier(client: null);
      final container = ProviderContainer(
        overrides: [
          // no client
          clientProvider.overrideWith(() => provider),
        ],
      );
      // it updates
      final ftr = container.read(alwaysClientProvider.future);
      expect(container.read(alwaysClientProvider).isLoading, true);
      final cl = MockClient();

      provider.state = AsyncValue.data(cl);
      expect(container.read(alwaysClientProvider).isLoading, false);
      expect(container.read(alwaysClientProvider).value, cl);

      expect(ftr, completes);
      await tester.pumpAndSettle();

      // user changes to another client
      final newCl = MockClient();

      provider.state = AsyncValue.data(newCl);
      expect(container.read(alwaysClientProvider).isLoading, false);
      expect(container.read(alwaysClientProvider).value, newCl);

      expect(ftr, completes);
      await tester.pumpAndSettle();

      // user logs out, no client left
      provider.state = AsyncValue.data(null);
      expect(container.read(alwaysClientProvider).isLoading, true);
      await container.pump();
      await expectLater(
        container.read(alwaysClientProvider.future),
        doesNotComplete,
      );
      expect(container.read(alwaysClientProvider).isLoading, true);
      await tester.pumpAndSettle();
    });
  });
}
