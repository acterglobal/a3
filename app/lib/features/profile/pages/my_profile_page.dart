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
import 'package:logging/logging.dart';

final _log = Logger('a3::profile::my_profile');

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
    final lang = L10n.of(context);
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text(lang.changeYourDisplayName),
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
          child: Text(lang.cancel),
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
          child: Text(lang.submit),
        ),
      ],
    );
  }
}

class MyProfilePage extends StatelessWidget {
  static const displayNameKey = Key('my-profile-display-name');

  const MyProfilePage({super.key});

  Future<void> updateDisplayName(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    final TextEditingController newName = TextEditingController();
    final avatarInfo = ref.read(accountAvatarInfoProvider);
    newName.text = avatarInfo.displayName ?? '';

    final newText = await showDialog<String>(
      context: context,
      builder: (context) {
        return ChangeDisplayName(currentName: avatarInfo.displayName);
      },
    );

    if (!context.mounted) return;
    if (newText == null) return;

    EasyLoading.show(status: lang.updatingDisplayName);
    final account = await ref.read(accountProvider.future);
    await account.setDisplayName(newText);
    ref.invalidate(accountProvider);

    if (!context.mounted) {
      EasyLoading.dismiss();
      return;
    }
    EasyLoading.showToast(lang.displayNameUpdateSubmitted);
  }

  Future<void> updateAvatar(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result = await pickAvatar(context: context);
    if (result != null && result.files.isNotEmpty) {
      final filePath = result.files.first.path;
      if (filePath == null) {
        _log.severe('FilePickerResult had an empty path', result);
        return;
      }
      if (!context.mounted) return;
      EasyLoading.show(status: L10n.of(context).updatingProfileImage);
      final account = await ref.read(accountProvider.future);
      await account.uploadAvatar(filePath);
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
        final lang = L10n.of(context);
        final accountInfo = ref.watch(accountAvatarInfoProvider);

        final userId = accountInfo.uniqueId;
        final displayName = accountInfo.displayName ?? '';

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                _buildAvatarUI(context, ref),
                const SizedBox(height: 20),
                _profileItem(
                  key: MyProfilePage.displayNameKey,
                  context: context,
                  title: lang.displayName,
                  subTitle: displayName,
                  trailingIcon: Atlas.pencil_edit,
                  onPressed: () => updateDisplayName(context, ref),
                ),
                const SizedBox(height: 20),
                _profileItem(
                  context: context,
                  title: lang.username,
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
    final colorScheme = Theme.of(context).colorScheme;
    final avatarInfo = ref.watch(accountAvatarInfoProvider);
    return GestureDetector(
      onTap: () => updateAvatar(context, ref),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              width: 2,
              color: colorScheme.onSurface,
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
                        color: colorScheme.onSurface,
                      ),
                      color: colorScheme.surface,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                    ),
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
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          title,
          key: key,
          style: textTheme.labelMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 5,
            vertical: 10,
          ),
          child: Text(
            subTitle,
            style: textTheme.titleSmall,
          ),
        ),
        trailing: IconButton(
          onPressed: onPressed,
          icon: Icon(trailingIcon),
        ),
      ),
    );
  }

  Future<void> _onCopy(String userId, BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!context.mounted) return;
    EasyLoading.showToast(L10n.of(context).usernameCopiedToClipboard);
  }
}
