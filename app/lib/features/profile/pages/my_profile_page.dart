import 'package:acter/common/dialogs/deactivation_confirmation.dart';
import 'package:acter/common/dialogs/logout_confirmation.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/default_dialog.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailPassword {
  String emailAddress;
  String password;

  EmailPassword(this.emailAddress, this.password);
}

class RequestTokenViaEmail extends StatefulWidget {
  final AccountProfile account;

  const RequestTokenViaEmail({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  State<RequestTokenViaEmail> createState() => _RequestTokenViaEmailState();
}

class _RequestTokenViaEmailState extends State<RequestTokenViaEmail> {
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
      title: const Text('Reset your token via email address'),
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

const submitUrlKey = 'PASSWORD_RESET_SUBMIT_URL';
const sessionIdKey = 'PASSWORD_RESET_SESSION_ID';
const passphraseKey = 'PASSWORD_RESET_PASSPHRASE';

class MyProfile extends ConsumerWidget {
  const MyProfile({super.key});

  Future<void> updateDisplayName(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final TextEditingController newName = TextEditingController();
    newName.text = profile.profile.displayName ?? '';

    final newText = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Change your display name'),
        content: TextField(controller: newName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (profile.profile.displayName != newName.text) {
                Navigator.pop(context, newName.text);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
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

  Future<void> requestTokenViaEmail(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    final newValue = await showDialog<EmailPassword>(
      context: context,
      builder: (BuildContext context) => RequestTokenViaEmail(account: profile),
    );
    if (newValue != null && context.mounted) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => DefaultDialog(
          title: Text(
            'Requesting token via email',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          isLoader: true,
        ),
      );
      final response = await profile.account.requestTokenViaEmail(
        newValue.emailAddress,
        newValue.password,
      );
      SharedPreferences pref = await sharedPrefs();
      final submitUrl = response.submitUrl();
      if (submitUrl != null) {
        pref.setString(submitUrlKey, submitUrl);
      }
      pref.setString(sessionIdKey, response.sessionId());
      pref.setString(passphraseKey, newValue.password);
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(
        context,
        'Requested token via email. If you get email for confirmation, please submit token from email to finish this process.',
      );
    }
  }

  Future<void> submitTokenFromEmail(
    AccountProfile profile,
    BuildContext context,
    WidgetRef ref,
  ) async {
    SharedPreferences pref = await sharedPrefs();
    final submitUrl = pref.getString(submitUrlKey);
    if (submitUrl == null) {
      return;
    }
    final sessionId = pref.getString(sessionIdKey);
    final passphrase = pref.getString(passphraseKey);
    final TextEditingController newToken = TextEditingController();

    if (!context.mounted) {
      return;
    }
    final newText = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Enter the token from confirmation email'),
        content: TextField(controller: newToken),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, newToken.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (newText != null && context.mounted) {
      showAdaptiveDialog(
        context: context,
        builder: (context) => DefaultDialog(
          title: Text(
            'Confirming token from email',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          isLoader: true,
        ),
      );
      await profile.account.submitTokenFromEmail(
        submitUrl,
        sessionId!,
        passphrase!,
        newText,
      );
      ref.invalidate(accountProfileProvider);

      if (!context.mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      customMsgSnackbar(
        context,
        'Confirmed token via email. Password reset without login was finished.',
      );
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
                            icon: const Icon(Atlas.lock_keyhole_thin),
                            onPressed: () async {
                              await requestTokenViaEmail(data, context, ref);
                            },
                          ),
                          IconButton(
                            iconSize: 14,
                            icon: const Icon(Atlas.check_circle_thin),
                            onPressed: () async {
                              await submitTokenFromEmail(data, context, ref);
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
