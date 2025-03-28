import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProviderContainer container;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Typing Indicator Mode Labs Feature', () {
    test('should update typing indicator mode features correctly', () async {
      // Initially, nameAndAvatar mode should be active
      expect(
        container.read(isActiveProvider(LabsFeature.typingIndicatorName)),
        false,
      );
      expect(
        container.read(isActiveProvider(LabsFeature.typingIndicatorAvatar)),
        false,
      );
      expect(
        container.read(
          isActiveProvider(LabsFeature.typingIndicatorNameAndAvatar),
        ),
        false,
      );

      // set name mode and verify
      await container
          .read(featuresProvider.notifier)
          .setActive(LabsFeature.typingIndicatorName, true);
      expect(
        container.read(isActiveProvider(LabsFeature.typingIndicatorName)),
        true,
      );
      expect(
        container.read(isActiveProvider(LabsFeature.typingIndicatorAvatar)),
        false,
      );
      expect(
        container.read(
          isActiveProvider(LabsFeature.typingIndicatorNameAndAvatar),
        ),
        false,
      );

      // set avatar mode and verify
      await container
          .read(featuresProvider.notifier)
          .setActive(LabsFeature.typingIndicatorAvatar, true);
      expect(
        container.read(isActiveProvider(LabsFeature.typingIndicatorName)),
        false,
      );
      expect(
        container.read(isActiveProvider(LabsFeature.typingIndicatorAvatar)),
        true,
      );
      expect(
        container.read(
          isActiveProvider(LabsFeature.typingIndicatorNameAndAvatar),
        ),
        false,
      );

      // set name and avatar mode and verify
      await container
          .read(featuresProvider.notifier)
          .setActive(LabsFeature.typingIndicatorNameAndAvatar, true);
      expect(
        container.read(isActiveProvider(LabsFeature.typingIndicatorName)),
        false,
      );
      expect(
        container.read(isActiveProvider(LabsFeature.typingIndicatorAvatar)),
        false,
      );
      expect(
        container.read(
          isActiveProvider(LabsFeature.typingIndicatorNameAndAvatar),
        ),
        true,
      );
    });

    test('should persist typing indicator mode features', () async {
      // set a mode and verify
      await container
          .read(featuresProvider.notifier)
          .setActive(LabsFeature.typingIndicatorNameAndAvatar, true);

      // Wait for the state to be persisted
      await Future.delayed(const Duration(milliseconds: 100));

      // create a new container to simulate app restart and verify
      final newContainer = ProviderContainer();
      expect(
        newContainer.read(
          isActiveProvider(LabsFeature.typingIndicatorNameAndAvatar),
        ),
        true,
      );
      newContainer.dispose();
    });
  });
}
