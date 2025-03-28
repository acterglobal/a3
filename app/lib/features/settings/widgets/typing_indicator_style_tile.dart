import 'package:acter/common/widgets/typing_indicator.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter/features/settings/widgets/options_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::labs::typing_indicator_style');

class TypingIndicatorStyleTile extends ConsumerWidget {
  const TypingIndicatorStyleTile({super.key});

  String _getModeDescription(TypingIndicatorMode mode) {
    switch (mode) {
      case TypingIndicatorMode.name:
        return 'Show only names';
      case TypingIndicatorMode.avatar:
        return 'Show only avatars';
      case TypingIndicatorMode.nameAndAvatar:
        return 'Show both names and avatars';
    }
  }

  Future<void> _setTypingIndicatorMode(
    WidgetRef ref,
    TypingIndicatorMode mode,
  ) async {
    try {
      // Update UI immediately
      ref.read(chatTypingIndicatorModeProvider.notifier).state = mode;

      EasyLoading.show(status: 'Updating setting...');

      // Then update persistent storage
      switch (mode) {
        case TypingIndicatorMode.name:
          await updateFeatureState(ref, LabsFeature.typingIndicatorName, true);
          await updateFeatureState(
            ref,
            LabsFeature.typingIndicatorAvatar,
            false,
          );
          await updateFeatureState(
            ref,
            LabsFeature.typingIndicatorNameAndAvatar,
            false,
          );
          break;
        case TypingIndicatorMode.avatar:
          await updateFeatureState(ref, LabsFeature.typingIndicatorName, false);
          await updateFeatureState(
            ref,
            LabsFeature.typingIndicatorAvatar,
            true,
          );
          await updateFeatureState(
            ref,
            LabsFeature.typingIndicatorNameAndAvatar,
            false,
          );
          break;
        case TypingIndicatorMode.nameAndAvatar:
          await updateFeatureState(ref, LabsFeature.typingIndicatorName, false);
          await updateFeatureState(
            ref,
            LabsFeature.typingIndicatorAvatar,
            false,
          );
          await updateFeatureState(
            ref,
            LabsFeature.typingIndicatorNameAndAvatar,
            true,
          );
          break;
      }

      EasyLoading.showToast(
        'Setting updated successfully',
        toastPosition: EasyLoadingToastPosition.bottom,
      );
    } catch (e, s) {
      // Revert UI change on error
      ref.invalidate(chatTypingIndicatorModeProvider);

      _log.severe('Failed to update typing indicator style', e, s);
      EasyLoading.showError(
        'Failed to update setting: $e',
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(chatTypingIndicatorModeProvider);

    return OptionsSettingsTile<TypingIndicatorMode>(
      title: 'Typing Indicator Style',
      explainer:
          'Customise the typing indicator style for the Next Generation Chat',
      selected: currentMode,
      options: [
        (
          TypingIndicatorMode.name,
          _getModeDescription(TypingIndicatorMode.name),
        ),
        (
          TypingIndicatorMode.avatar,
          _getModeDescription(TypingIndicatorMode.avatar),
        ),
        (
          TypingIndicatorMode.nameAndAvatar,
          _getModeDescription(TypingIndicatorMode.nameAndAvatar),
        ),
      ],
      onSelect: (mode) => _setTypingIndicatorMode(ref, mode),
    );
  }
}
