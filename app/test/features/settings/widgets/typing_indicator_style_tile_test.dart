import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeatureUpdater extends Mock {
  void updateFeatureFlag(LabsFeature feature, bool active);
}

class LabsFeatureFake extends Fake {
  // We can't directly implement an enum, so we just make it a Fake
}

void main() {
  group('TypingIndicatorStyleTile', () {
    late MockFeatureUpdater mockUpdater;
    late ProviderContainer container;

    setUpAll(() {
      // Register fallback value for LabsFeature
      registerFallbackValue(LabsFeature.typingIndicatorName);
    });

    setUp(() {
      mockUpdater = MockFeatureUpdater();
      container = ProviderContainer(
        overrides: [
          chatTypingIndicatorModeProvider.overrideWith(
            (ref) => TypingIndicatorMode.name,
          ),
        ],
      );
    });

    void setTypingIndicatorMode(
      ProviderContainer container,
      MockFeatureUpdater updater,
      TypingIndicatorMode mode,
    ) {
      container.read(chatTypingIndicatorModeProvider.notifier).state = mode;

      switch (mode) {
        case TypingIndicatorMode.name:
          updater.updateFeatureFlag(LabsFeature.typingIndicatorName, true);
          updater.updateFeatureFlag(LabsFeature.typingIndicatorAvatar, false);
          updater.updateFeatureFlag(
            LabsFeature.typingIndicatorNameAndAvatar,
            false,
          );
          break;
        case TypingIndicatorMode.avatar:
          updater.updateFeatureFlag(LabsFeature.typingIndicatorName, false);
          updater.updateFeatureFlag(LabsFeature.typingIndicatorAvatar, true);
          updater.updateFeatureFlag(
            LabsFeature.typingIndicatorNameAndAvatar,
            false,
          );
          break;
        case TypingIndicatorMode.nameAndAvatar:
          updater.updateFeatureFlag(LabsFeature.typingIndicatorName, false);
          updater.updateFeatureFlag(LabsFeature.typingIndicatorAvatar, false);
          updater.updateFeatureFlag(
            LabsFeature.typingIndicatorNameAndAvatar,
            true,
          );
          break;
      }
    }

    test('selecting name mode updates feature flag correctly', () {
      when(() => mockUpdater.updateFeatureFlag(any(), any())).thenReturn(null);

      setTypingIndicatorMode(container, mockUpdater, TypingIndicatorMode.name);

      expect(
        container.read(chatTypingIndicatorModeProvider),
        equals(TypingIndicatorMode.name),
      );

      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorName,
          true,
        ),
      ).called(1);
      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorAvatar,
          false,
        ),
      ).called(1);
      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorNameAndAvatar,
          false,
        ),
      ).called(1);
    });

    test('selecting avatar mode updates feature flag correctly', () {
      when(() => mockUpdater.updateFeatureFlag(any(), any())).thenReturn(null);

      setTypingIndicatorMode(
        container,
        mockUpdater,
        TypingIndicatorMode.avatar,
      );

      expect(
        container.read(chatTypingIndicatorModeProvider),
        equals(TypingIndicatorMode.avatar),
      );

      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorName,
          false,
        ),
      ).called(1);
      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorAvatar,
          true,
        ),
      ).called(1);
      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorNameAndAvatar,
          false,
        ),
      ).called(1);
    });

    test('selecting nameAndAvatar mode updates feature flag correctly', () {
      when(() => mockUpdater.updateFeatureFlag(any(), any())).thenReturn(null);

      setTypingIndicatorMode(
        container,
        mockUpdater,
        TypingIndicatorMode.nameAndAvatar,
      );

      expect(
        container.read(chatTypingIndicatorModeProvider),
        equals(TypingIndicatorMode.nameAndAvatar),
      );

      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorName,
          false,
        ),
      ).called(1);
      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorAvatar,
          false,
        ),
      ).called(1);
      verify(
        () => mockUpdater.updateFeatureFlag(
          LabsFeature.typingIndicatorNameAndAvatar,
          true,
        ),
      ).called(1);
    });
  });
}
