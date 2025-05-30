import 'package:flutter_test/flutter_test.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:riverpod/riverpod.dart';

import '../../helpers/mock_space_providers.dart';

void main() {
  group('Space Provider Tests', () {
    late ProviderContainer container;
    const testSpaceId = 'test-space-id';

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('returns space when maybeSpaceProvider returns a space', () async {
      final mockSpace = MockSpace(id: testSpaceId);

      container = ProviderContainer(
        overrides: [
          maybeSpaceProvider.overrideWith(
            () => MaybeMockAsyncSpaceNotifier(mockSpace: mockSpace),
          ),
        ],
      );

      final result = await container.read(spaceProvider(testSpaceId).future);
      expect(result, equals(mockSpace));
    });

    test('pends forever when maybeSpaceProvider returns null', () async {
      container = ProviderContainer(
        overrides: [
          maybeSpaceProvider.overrideWith(() => MaybeMockAsyncSpaceNotifier()),
        ],
      );

      // The future should never complete
      await expectLater(
        container.read(spaceProvider(testSpaceId).future),
        doesNotComplete,
      );
    });

    test('updates when maybeSpaceProvider changes from null to space', () async {
      final mockSpace = MockSpace(id: testSpaceId);

      // Start with null space
      container = ProviderContainer(
        overrides: [
          maybeSpaceProvider.overrideWith(() => MaybeMockAsyncSpaceNotifier()),
        ],
      );

      // Initially returns null
      final future = container.read(spaceProvider(testSpaceId).future);
      await expectLater(future, doesNotComplete);

      // Update to return a space by creating a new container with a new notifier
      container = ProviderContainer(
        overrides: [
          maybeSpaceProvider.overrideWith(
            () => RetryMockAsyncSpaceNotifier(
              mockSpace: mockSpace,
              shouldFail: false,
            ),
          ),
        ],
      );

      // Now the future should complete with the space
      final result = await container.read(spaceProvider(testSpaceId).future);
      expect(result, equals(mockSpace));
    });

    test(
      'updates when maybeSpaceProvider changes from space to null',
      () async {
        final mockSpace = MockSpace(id: testSpaceId);

        // Start with a space
        container = ProviderContainer(
          overrides: [
            maybeSpaceProvider.overrideWith(
              () => MaybeMockAsyncSpaceNotifier(mockSpace: mockSpace),
            ),
          ],
        );

        // Initially returns a space
        final result1 = await container.read(spaceProvider(testSpaceId).future);
        expect(result1, equals(mockSpace));

        // Update to return null by creating a new container with a new notifier
        container = ProviderContainer(
          overrides: [
            maybeSpaceProvider.overrideWith(
              () => MaybeMockAsyncSpaceNotifier(),
            ),
          ],
        );

        // The new future should not complete
        await expectLater(
          container.read(spaceProvider(testSpaceId).future),
          doesNotComplete,
        );
      },
    );
  });
}
