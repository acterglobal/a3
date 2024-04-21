import 'dart:io';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class UploadAvatarPage extends ConsumerWidget {
  static const selectUserAvatar = Key('reg-select-user-avtar');
  static const uploadBtn = Key('reg-upload-btn');
  static const skipBtn = Key('reg-skip-btn');

  UploadAvatarPage({super.key});

  final ValueNotifier<PlatformFile?> selectedUserAvatar = ValueNotifier(null);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: _buildBody(context, ref),
    );
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
            _buildSkipActionButton(context),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    return Text(
      L10n.of(context).avatarAddTitle,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: greenColor,
          ),
      textAlign: TextAlign.center,
    );
  }

  Future<void> pickAvtar(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: L10n.of(context).uploadAvatar,
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setUserAvatar(result.files.first);
    }
  }

  void setUserAvatar(PlatformFile userAvatar) {
    selectedUserAvatar.value = userAvatar;
  }

  Widget _buildAvatarUI(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      key: UploadAvatarPage.selectUserAvatar,
      onTap: () => pickAvtar(context, ref),
      child: Center(
        child: Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              width: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: selectedUserAvatar,
                builder: (context, userAvatar, child) {
                  if (userAvatar == null && userAvatar?.path == null) {
                    return const Icon(Atlas.account, size: 50);
                  }
                  return CircleAvatar(
                    radius: 100,
                    backgroundImage: FileImage(File(userAvatar!.path!)),
                  );
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
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      color: Theme.of(context).colorScheme.surface,
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
    try {
      final accountProfile = await ref.watch(accountProfileProvider.future);
      if (selectedUserAvatar.value == null ||
          selectedUserAvatar.value?.path == null) {
        if (context.mounted) {
          EasyLoading.showToast(L10n.of(context).avatarEmpty);
        }
        return;
      }
      if (context.mounted) {
        EasyLoading.show(status: L10n.of(context).avatarUploading);
      }
      await accountProfile.account
          .uploadAvatar(selectedUserAvatar.value!.path!);
      ref.invalidate(accountProfileProvider);
      if (context.mounted) context.goNamed(Routes.main.name);
      // close loading
      EasyLoading.dismiss();
    } catch (error) {
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).avatarUploadFailed(error),
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

  Widget _buildSkipActionButton(BuildContext context) {
    return OutlinedButton(
      key: UploadAvatarPage.skipBtn,
      onPressed: () => context.goNamed(Routes.main.name),
      child: Text(
        L10n.of(context).skip,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
