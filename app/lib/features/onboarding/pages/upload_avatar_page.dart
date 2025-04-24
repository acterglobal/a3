import 'dart:io';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/features/files/actions/pick_avatar.dart';
import 'package:acter/features/onboarding/types.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::onboarding::upload_avatar');

class UploadAvatarPage extends ConsumerWidget {
  static const selectUserAvatar = Key('reg-select-user-avtar');
  static const uploadBtn = Key('reg-upload-btn');
  static const skipBtn = Key('reg-skip-btn');

  final CallNextPage? callNextPage;
  final ValueNotifier<PlatformFile?> selectedUserAvatar = ValueNotifier(null);

  UploadAvatarPage({super.key, required this.callNextPage});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(body: _buildBody(context, ref));
  }

  Widget _buildBody(BuildContext context, WidgetRef ref) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            _buildHeadlineText(context),
            const SizedBox(height: 50),
            _buildAvatarUI(context, ref),
            const Spacer(),
            _buildUploadActionButton(context, ref),
            const SizedBox(height: 20),
            _buildSkipActionButton(context, ref),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      L10n.of(context).avatarAddTitle,
      style: textTheme.headlineMedium?.copyWith(color: colorScheme.secondary),
      textAlign: TextAlign.center,
    );
  }

  Future<void> onSelectAvatar(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result = await pickAvatar(context: context);
    if (result != null && result.files.isNotEmpty) {
      setUserAvatar(result.files.first);
    }
  }

  void setUserAvatar(PlatformFile userAvatar) {
    selectedUserAvatar.value = userAvatar;
  }

  Widget _buildAvatarUI(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      key: UploadAvatarPage.selectUserAvatar,
      onTap: () => onSelectAvatar(context, ref),
      child: Center(
        child: Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(width: 2, color: colorScheme.onSurface),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: selectedUserAvatar,
                builder: (context, userAvatar, child) {
                  return userAvatar?.path.map(
                        (filePath) => CircleAvatar(
                          radius: 100,
                          backgroundImage: FileImage(File(filePath)),
                        ),
                      ) ??
                      const Icon(Atlas.account, size: 50);
                },
              ),
              Positioned.fill(
                right: 5,
                bottom: 5,
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        width: 1,
                        color: colorScheme.onSurface,
                      ),
                      color: colorScheme.surface,
                    ),
                    child: const Icon(Icons.add, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> uploadAvatar(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    try {
      final account = await ref.watch(accountProvider.future);
      final filePath = selectedUserAvatar.value?.path;
      if (filePath == null) {
        if (context.mounted) EasyLoading.showToast(lang.avatarEmpty);
        return;
      }
      if (context.mounted) EasyLoading.show(status: lang.avatarUploading);
      await account.uploadAvatar(filePath);
      ref.invalidate(accountProvider);
      EasyLoading.dismiss(); // close loading
      if (context.mounted) context.goNamed(Routes.main.name);
    } catch (e, s) {
      _log.severe('Failed to upload avatar', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.avatarUploadFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildUploadActionButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      key: UploadAvatarPage.uploadBtn,
      onPressed: () => uploadAvatar(context, ref),
      child: Text(
        L10n.of(context).uploadAvatar,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildSkipActionButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
      key: UploadAvatarPage.skipBtn,
      onPressed: () async {
        if (!context.mounted) return;
        // Handle all post-login steps
        callNextPage?.call();
      },
      child: Text(
        L10n.of(context).skip,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
