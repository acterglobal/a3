import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/labs/feature_flagger.dart';
import 'package:acter/features/labs/providers/notifiers/labs_features.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFeaturesNotifier extends SharedPrefFeaturesNotifier {
  MockFeaturesNotifier(Ref ref) : super('test_key', ref);

  @override
  Future<void> setActive(LabsFeature f, bool active) async {
    final currentFlags = List<FeatureFlag<LabsFeature>>.from(state.flags);
    final existingIndex = currentFlags.indexWhere((flag) => flag.feature == f);

    if (existingIndex >= 0) {
      currentFlags[existingIndex] = FeatureFlag<LabsFeature>(
        feature: f,
        active: active,
      );
    } else {
      currentFlags.add(FeatureFlag<LabsFeature>(feature: f, active: active));
    }

    state = Features(flags: currentFlags, defaultOn: LabsFeature.defaults);
  }
}

void main() {
  group('Typing Indicator Provider Tests', () {
    test('default mode is nameAndAvatar when no lab features are active', () {
      final container = ProviderContainer(
        overrides: [
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            // Ensure all typing indicator features are inactive
            notifier.setActive(LabsFeature.typingIndicatorName, false);
            notifier.setActive(LabsFeature.typingIndicatorAvatar, false);
            notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, false);
            return notifier;
          }),
        ],
      );

      final mode = container.read(chatTypingIndicatorModeProvider);
      expect(mode, equals(TypingIndicatorMode.nameAndAvatar));

      container.dispose();
    });

    test('mode is set to name when typingIndicatorName feature is active', () {
      final container = ProviderContainer(
        overrides: [
          featuresProvider.overrideWith((ref) {
            final notifier = MockFeaturesNotifier(ref);
            // Activate name mode only
            notifier.setActive(LabsFeature.typingIndicatorName, true);
            notifier.setActive(LabsFeature.typingIndicatorAvatar, false);
            notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, false);
            return notifier;
          }),
        ],
      );

      final mode = container.read(chatTypingIndicatorModeProvider);
      expect(mode, equals(TypingIndicatorMode.name));

      container.dispose();
    });

    test(
      'mode is set to avatar when typingIndicatorAvatar feature is active',
      () {
        final container = ProviderContainer(
          overrides: [
            featuresProvider.overrideWith((ref) {
              final notifier = MockFeaturesNotifier(ref);
              // Activate avatar mode only
              notifier.setActive(LabsFeature.typingIndicatorName, false);
              notifier.setActive(LabsFeature.typingIndicatorAvatar, true);
              notifier.setActive(
                LabsFeature.typingIndicatorNameAndAvatar,
                false,
              );
              return notifier;
            }),
          ],
        );

        final mode = container.read(chatTypingIndicatorModeProvider);
        expect(mode, equals(TypingIndicatorMode.avatar));

        container.dispose();
      },
    );

    test(
      'mode is set to nameAndAvatar when typingIndicatorNameAndAvatar feature is active',
      () {
        final container = ProviderContainer(
          overrides: [
            featuresProvider.overrideWith((ref) {
              final notifier = MockFeaturesNotifier(ref);
              // Activate nameAndAvatar mode only
              notifier.setActive(LabsFeature.typingIndicatorName, false);
              notifier.setActive(LabsFeature.typingIndicatorAvatar, false);
              notifier.setActive(
                LabsFeature.typingIndicatorNameAndAvatar,
                true,
              );
              return notifier;
            }),
          ],
        );

        final mode = container.read(chatTypingIndicatorModeProvider);
        expect(mode, equals(TypingIndicatorMode.nameAndAvatar));

        container.dispose();
      },
    );

    test('mode changes when lab features are updated', () async {
      late SharedPrefFeaturesNotifier notifier;

      final container = ProviderContainer(
        overrides: [
          featuresProvider.overrideWith((ref) {
            notifier = MockFeaturesNotifier(ref);
            // Start with nameAndAvatar mode
            notifier.setActive(LabsFeature.typingIndicatorName, false);
            notifier.setActive(LabsFeature.typingIndicatorAvatar, false);
            notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, true);
            return notifier;
          }),
        ],
      );

      // Initial mode should be nameAndAvatar
      var mode = container.read(chatTypingIndicatorModeProvider);
      expect(mode, equals(TypingIndicatorMode.nameAndAvatar));

      // Change to name mode
      await notifier.setActive(LabsFeature.typingIndicatorName, true);
      await notifier.setActive(LabsFeature.typingIndicatorNameAndAvatar, false);

      // Mode should update to name
      mode = container.read(chatTypingIndicatorModeProvider);
      expect(mode, equals(TypingIndicatorMode.name));

      // Change to avatar mode
      await notifier.setActive(LabsFeature.typingIndicatorName, false);
      await notifier.setActive(LabsFeature.typingIndicatorAvatar, true);

      // Mode should update to avatar
      mode = container.read(chatTypingIndicatorModeProvider);
      expect(mode, equals(TypingIndicatorMode.avatar));

      container.dispose();
    });
  });
}
