import 'package:acter/common/providers/common_providers.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/files/actions/pick_avatar.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangeDisplayName extends StatefulWidget {
  final String? currentName;

  const ChangeDisplayName({
    super.key,
    required this.currentName,
  });

  @override
  State<ChangeDisplayName> createState() => _ChangeDisplayNameState();
}

class _ChangeDisplayNameState extends State<ChangeDisplayName> {
  final TextEditingController newUsername = TextEditingController();
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(debugLabel: 'display name form');

  @override
  void initState() {
    super.initState();
    newUsername.text = widget.currentName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(L10n.of(context).changeYourDisplayName),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(controller: newUsername),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        OutlinedButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(L10n.of(context).cancel),
        ),
        ActerPrimaryActionButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final currentUserName = widget.currentName;
            final newDisplayName = newUsername.text;
            if (currentUserName != newDisplayName) {
              Navigator.pop(context, newDisplayName);
            } else {
              Navigator.pop(context, null);
            }
          },
          child: Text(L10n.of(context).submit),
        ),
      ],
    );
  }
}

class MyProfilePage extends StatelessWidget {
  static const displayNameKey = Key('my-profile-display-name');

  const MyProfilePage({super.key});

  Future<void> updateDisplayName(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final TextEditingController newName = TextEditingController();
    final avatarInfo = ref.read(accountAvatarInfoProvider);
    newName.text = avatarInfo.displayName ?? '';

    final newText = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          ChangeDisplayName(currentName: avatarInfo.displayName),
    );

    if (!context.mounted) return;
    if (newText == null) return;

    EasyLoading.show(status: L10n.of(context).updatingDisplayName);
    await ref.read(accountProvider).setDisplayName(newText);
    ref.invalidate(accountProvider);

    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(L10n.of(context).displayNameUpdateSubmitted);
  }

  Future<void> updateAvatar(
    BuildContext context,
    WidgetRef ref,
  ) async {
    FilePickerResult? result = await pickAvatar(context: context);
    if (!context.mounted) return;
    if (result != null) {
      EasyLoading.show(status: L10n.of(context).updatingProfileImage);
      final file = result.files.first;
      await ref.read(accountProvider).uploadAvatar(file.path!);
      ref.invalidate(accountProvider);
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
        L10n.of(context).profile,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final accountInfo = ref.watch(accountAvatarInfoProvider);

        final userId = accountInfo.uniqueId;
        final displayName = accountInfo.displayName ?? '';

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildAvatarUI(context, ref),
                const SizedBox(height: 20),
                _profileItem(
                  key: MyProfilePage.displayNameKey,
                  context: context,
                  title: L10n.of(context).displayName,
                  subTitle: displayName,
                  trailingIcon: Atlas.pencil_edit,
                  onPressed: () => updateDisplayName(context, ref),
                ),
                const SizedBox(height: 20),
                _profileItem(
                  context: context,
                  title: L10n.of(context).username,
                  subTitle: userId,
                  trailingIcon: Atlas.pages,
                  onPressed: () => _onCopy(userId, context),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarUI(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(accountAvatarInfoProvider);
    return GestureDetector(
      onTap: () => updateAvatar(context, ref),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              width: 2,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: Stack(
            children: [
              ActerAvatar(
                options: AvatarOptions.DM(
                  avatarInfo,
                  size: 50,
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        width: 1,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                    ),
                    child: const Icon(Icons.edit, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileItem({
    Key? key,
    required BuildContext context,
    required String title,
    required String subTitle,
    required IconData trailingIcon,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          title,
          key: key,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          child: Text(
            subTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        trailing: IconButton(
          onPressed: onPressed,
          icon: Icon(trailingIcon),
        ),
      ),
    );
  }

  void _onCopy(String userId, BuildContext context) {
    Clipboard.setData(ClipboardData(text: userId));
    EasyLoading.showToast(L10n.of(context).usernameCopiedToClipboard);
  }
}
