import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('Typing Indicator Mode Provider', () {
    test('should return name mode when no feature is active', () {
      expect(
        container.read(chatTypingIndicatorModeProvider),
        TypingIndicatorMode.name,
      );
    });

    test('should return name mode when name feature is active', () async {
      await container
          .read(featuresProvider.notifier)
          .setActive(LabsFeature.typingIndicatorName, true);
      expect(
        container.read(chatTypingIndicatorModeProvider),
        TypingIndicatorMode.name,
      );
    });

    test('should return avatar mode when avatar feature is active', () async {
      await container
          .read(featuresProvider.notifier)
          .setActive(LabsFeature.typingIndicatorAvatar, true);
      expect(
        container.read(chatTypingIndicatorModeProvider),
        TypingIndicatorMode.avatar,
      );
    });

    test(
      'should return nameAndAvatar mode when nameAndAvatar feature is active',
      () async {
        await container
            .read(featuresProvider.notifier)
            .setActive(LabsFeature.typingIndicatorNameAndAvatar, true);
        expect(
          container.read(chatTypingIndicatorModeProvider),
          TypingIndicatorMode.nameAndAvatar,
        );
      },
    );

    test('should update mode when feature state changes', () async {
      // Initially name mode
      expect(
        container.read(chatTypingIndicatorModeProvider),
        TypingIndicatorMode.name,
      );

      // Set to avatar mode
      await container
          .read(featuresProvider.notifier)
          .setActive(LabsFeature.typingIndicatorAvatar, true);
      expect(
        container.read(chatTypingIndicatorModeProvider),
        TypingIndicatorMode.avatar,
      );

      // Set to nameAndAvatar mode
      await container
          .read(featuresProvider.notifier)
          .setActive(LabsFeature.typingIndicatorNameAndAvatar, true);
      expect(
        container.read(chatTypingIndicatorModeProvider),
        TypingIndicatorMode.nameAndAvatar,
      );
    });
  });
}
