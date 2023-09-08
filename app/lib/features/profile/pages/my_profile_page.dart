import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChangeDisplayName extends StatefulWidget {
  final AccountProfile account;

  const ChangeDisplayName({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  State<ChangeDisplayName> createState() => _ChangeDisplayNameState();
}

class _ChangeDisplayNameState extends State<ChangeDisplayName> {
  final TextEditingController newName = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    newName.text = widget.account.profile.displayName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change your display name'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(controller: newName),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onSubmit,
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void onSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (widget.account.profile.displayName != newName.text) {
      Navigator.pop(context, newName.text);
    } else {
      Navigator.pop(context, null);
    }
  }
}

class EmailPassword {
  String emailAddress;
  String password;

  EmailPassword(this.emailAddress, this.password);
}

class ChangeEmailPassword extends StatefulWidget {
  final AccountProfile account;

  const ChangeEmailPassword({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  State<ChangeEmailPassword> createState() => _ChangeEmailPasswordState();
}

class _ChangeEmailPasswordState extends State<ChangeEmailPassword> {
  final TextEditingController newEmail = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    newEmail.text = widget.account.emailAddress ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change your password via email address'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(controller: newEmail),
            ),
            Padding(
              padding: const EdgeInsets.all(5),
              child: TextFormField(controller: newPassword),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => onSubmit(context),
          child: const Text('Submit'),
        ),
      ],
    );
  }

  void onSubmit(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // user can reset password under the same email address
    final result = EmailPassword(newEmail.text, newPassword.text);
    Navigator.pop(context, result);
  }
}

class MyProfile extends ConsumerWidget {
  const MyProfile({super.key});

  Future<void> updateDisplayName(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final newText = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => ChangeDisplayName(account: profile),
    );
    if (newText != null && context.mounted) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => DefaultDialog(
          title: Text(
            'Updating Display Name',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          isLoader: true,
        ),
      );
      await profile.account.setDisplayName(newText);
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(context, 'Display Name update submitted');
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
      final file = result.files.first;
      await profile.account.uploadAvatar(file.path!);

      if (!context.mounted) {
        return;
      }
      customMsgSnackbar(context, 'Avatar uploaded');
    } else {
      // user cancelled the picker
    }
  }

  Future<void> updateEmailAddress(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final newValue = await showDialog<EmailPassword>(
      context: context,
      builder: (BuildContext context) => ChangeEmailPassword(account: profile),
    );
    if (newValue != null && context.mounted) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => DefaultDialog(
          title: Text(
            'Updating Email Address',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          isLoader: true,
        ),
      );
      await profile.account.requestTokenViaEmail(
        newValue.emailAddress,
        newValue.password,
      );
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(context, 'Display Name update submitted');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountProfileProvider);
    return account.when(
      data: (data) {
        final userId = data.account.userId().toString();
        return Scaffold(
          appBar: AppBar(
            title: const Text('My profile'),
            actions: [
              PopupMenuButton(
                itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                  PopupMenuItem(
                    onTap: () => logoutConfirmationDialog(context, ref),
                    child: Row(
                      children: [
                        const Icon(Atlas.exit_thin),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            AppLocalizations.of(context)!.logOut,
                            style: Theme.of(context).textTheme.labelSmall,
                            softWrap: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: const SizedBox(),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width - 100,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => updateAvatar(data, context, ref),
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(width: 5),
                          ),
                          child: ActerAvatar(
                            mode: DisplayMode.User,
                            uniqueId: userId,
                            avatar: data.profile.getAvatarImage(),
                            displayName: data.profile.displayName,
                            size: 100,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(data.profile.displayName ?? ''),
                          IconButton(
                            iconSize: 14,
                            icon: const Icon(Atlas.pencil_edit_thin),
                            onPressed: () async {
                              await updateDisplayName(data, context, ref);
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(userId),
                          IconButton(
                            iconSize: 14,
                            icon: const Icon(Atlas.pages),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: userId),
                              );
                              customMsgSnackbar(
                                context,
                                'Username copied to clipboard',
                              );
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(data.emailAddress ?? ''),
                          IconButton(
                            iconSize: 14,
                            icon: const Icon(Atlas.pencil_edit_thin),
                            onPressed: () async {
                              await updateEmailAddress(data, context, ref);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      OutlinedButton.icon(
                        icon: const Icon(Atlas.construction_tools_thin),
                        onPressed: () =>
                            context.pushNamed(Routes.settings.name),
                        label: const Text('App Settings'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Atlas.laptop_screen_thin),
                        onPressed: () =>
                            context.pushNamed(Routes.settingSessions.name),
                        label: const Text('Sessions'),
                      ),
                      const SizedBox(height: 30),
                      OutlinedButton.icon(
                        icon: const Icon(Atlas.exit_thin),
                        onPressed: () => logoutConfirmationDialog(context, ref),
                        label: const Text('Logout'),
                      ),
                      const SizedBox(height: 45),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.brandColorScheme.error,
                          backgroundColor: AppTheme.brandColorScheme.onError,
                          side: BorderSide(
                            width: 1,
                            color: AppTheme.brandColorScheme.error,
                          ),
                        ),
                        icon: const Icon(Atlas.trash_can_thin),
                        onPressed: () =>
                            deactivationConfirmationDialog(context, ref),
                        label: const Text('Deactivate account'),
                      ),
                    ],
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
  }
}
