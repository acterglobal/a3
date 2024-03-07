import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MyProfilePage extends StatelessWidget {
  static const displayNameKey = Key('my-profile-display-name');

  const MyProfilePage({super.key});

  Future<void> updateDisplayName(
    AccountProfile profile,
    String displayName,
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (displayName.isNotEmpty && context.mounted) {
      EasyLoading.show(status: 'Updating profile data');
      await profile.account.setDisplayName(displayName);
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }

      // close loading
      EasyLoading.dismiss();

      context.pop();
    } else {
      customMsgSnackbar(context, 'Please enter display name!');
    }
  }

  Future<void> updateAvatar(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Upload Avatar',
      type: FileType.image,
    );
    if (result != null) {
      EasyLoading.show(status: 'Updating profile image');

      final file = result.files.first;
      await profile.account.uploadAvatar(file.path!);
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }
      // close loading
      EasyLoading.dismiss();
    } else {
      // user cancelled the picker
    }
  }

  @override
  Widget build(BuildContext context) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: _buildAppbar(context),
        body: _buildBody(context),
      ),
    );
  }

  AppBar _buildAppbar(BuildContext context) {
    return AppBar(
      title: Text(
        'Profile',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final account = ref.watch(accountProfileProvider);

        return account.when(
          data: (data) {
            final userId = data.account.userId().toString();
            final displayName = data.profile.displayName ?? '';
            final displayNameController =
                TextEditingController(text: displayName);
            final usernameController = TextEditingController(text: userId);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => updateAvatar(data, context, ref),
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(width: 5),
                          ),
                          child: ActerAvatar(
                            mode: DisplayMode.DM,
                            avatarInfo: AvatarInfo(
                              uniqueId: userId,
                              avatar: data.profile.getAvatarImage(),
                              displayName: data.profile.displayName,
                            ),
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _profileItem(
                      key: MyProfilePage.displayNameKey,
                      context: context,
                      title: 'Display Name',
                      controller: displayNameController,
                    ),
                    const SizedBox(height: 20),
                    _profileItem(
                      context: context,
                      title: 'User ID',
                      controller: usernameController,
                      readOnly: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => updateDisplayName(
                        data,
                        displayNameController.text,
                        context,
                        ref,
                      ),
                      child: Text(
                        'Save',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            );
          },
          error: (e, trace) => Text('error: $e'),
          loading: () => const Text('loading'),
        );
      },
    );
  }

  Widget _profileItem({
    Key? key,
    required BuildContext context,
    required String title,
    required TextEditingController controller,
    bool readOnly = false,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        subtitle: TextFormField(
          key: key,
          controller: controller,
          readOnly: readOnly,
          decoration: const InputDecoration(
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
          ),
        ),
        enabled: true,
        trailing: readOnly
            ? IconButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: controller.text),
                  );
                  customMsgSnackbar(
                    context,
                    'Username copied to clipboard',
                  );
                },
                icon: const Icon(Atlas.pages),
              )
            : null,
      ),
    );
  }
}
