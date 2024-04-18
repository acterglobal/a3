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

final userAvatarProvider = StateProvider<PlatformFile?>((ref) => null);

class UserAvatarPage extends ConsumerWidget {
  static const selectUserAvatar = Key('reg-select-user-avtar');
  static const uploadBtn = Key('reg-upload-btn');

  const UserAvatarPage({super.key});

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
            const SizedBox(height: 100),
            _buildHeadlineText(context),
            const SizedBox(height: 50),
            _buildAvatarUI(context, ref),
            const SizedBox(height: 100),
            _buildUploadActionButton(context, ref),
            const SizedBox(height: 20),
            _buildSkipActionButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    return Text(
      L10n.of(context).userAvatarTitle,
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
    if (result != null) {
      ref
          .read(userAvatarProvider.notifier)
          .update((state) => result.files.first);
    }
  }

  Widget _buildAvatarUI(BuildContext context, WidgetRef ref) {
    final selectedAvtar = ref.watch(userAvatarProvider);
    return GestureDetector(
      key: selectUserAvatar,
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
              if (selectedAvtar == null && selectedAvtar?.path == null)
                const Icon(Atlas.account, size: 50)
              else
                CircleAvatar(
                  radius: 100,
                  backgroundImage: FileImage(File(selectedAvtar!.path!)),
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
      final selectedAvtar = ref.read(userAvatarProvider);
      if (selectedAvtar != null && context.mounted) {
        EasyLoading.show(status: L10n.of(context).uploadingProfileAvatar);
        await accountProfile.account.uploadAvatar(selectedAvtar.path!);
      } else {
        if (!context.mounted) return;
        EasyLoading.showToast(L10n.of(context).emptyAvatar);
      }
    } catch (e) {
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).failedToUpload,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // close loading
      EasyLoading.dismiss();
      if (context.mounted) context.goNamed(Routes.main.name);
    }
  }

  Widget _buildUploadActionButton(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      key: UserAvatarPage.uploadBtn,
      onPressed: () => uploadAvatar(context, ref),
      child: Text(
        L10n.of(context).uploadAvatar,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildSkipActionButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () => context.goNamed(Routes.main.name),
      child: Text(
        L10n.of(context).skip,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
