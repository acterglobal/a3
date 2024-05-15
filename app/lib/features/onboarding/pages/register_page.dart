import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';

import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('Register');

Future<void> tryRedeem(SuperInvites superInvites, String token) async {
  // try to redeem the token in a fire-and-forget-manner
  try {
    await superInvites.redeem(token);
  } catch (error) {
    _log.warning('redeeming super invite failed: $error');
  }
}

class RegisterPage extends ConsumerStatefulWidget {
  static const usernameField = Key('reg-username-txt');
  static const passwordField = Key('reg-password-txt');
  static const nameField = Key('reg-name-txt');
  static const tokenField = Key('reg-token-txt');
  static const submitBtn = Key('reg-submit');

  const RegisterPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController token = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController name = TextEditingController();
  bool _passwordVisible = false;

  final usernamePattern = RegExp(r'^[a-z0-9._=\-/]+$');

  Future<void> handleSubmit(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    if (!inCI && !ref.read(hasNetworkProvider)) {
      showNoInternetNotification(context);
      return;
    }
    final authNotifier = ref.read(authStateProvider.notifier);
    final errorMsg = await authNotifier.register(
      username.text,
      password.text,
      name.text,
      token.text,
      context,
    );
    if (context.mounted && errorMsg != null) {
      EasyLoading.showError(errorMsg, duration: const Duration(seconds: 3));
      return;
    }
    if (token.text.isNotEmpty) {
      final superInvites = ref.read(superInvitesProvider);
      tryRedeem(superInvites, token.text);
    }
    if (context.mounted) {
      context.goNamed(
        Routes.saveUsername.name,
        queryParameters: {'username': username.text},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: Column(
        children: [
          _buildAppBar(context),
          _buildRegisterPage(context),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final authNotifier = ref.watch(authStateProvider.notifier);
    return AppBar(
      backgroundColor: Colors.transparent,
      actions: [
        if (canGuestLogin)
          OutlinedButton(
            onPressed: () async => await authNotifier.makeGuest(context),
            child: Text(L10n.of(context).continueAsGuest),
          ),
      ],
    );
  }

  Widget _buildRegisterPage(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeadlineText(context),
                const SizedBox(height: 50),
                _buildNameInputField(context),
                const SizedBox(height: 12),
                _buildUsernameInputField(context),
                const SizedBox(height: 12),
                _buildPasswordInputField(context),
                const SizedBox(height: 24),
                _buildTokenInputField(context),
                const SizedBox(height: 40),
                _buildTermsAcceptText(context),
                const SizedBox(height: 20),
                _buildSignUpButton(context),
                const SizedBox(height: 12),
                _buildLoginAccountButton(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    return Column(
      children: [
        Text(
          L10n.of(context).createProfile,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Theme.of(context).colorScheme.textHighlight,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          L10n.of(context).onboardText,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildNameInputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).displayName),
        const SizedBox(height: 10),
        TextFormField(
          key: RegisterPage.nameField,
          controller: name,
          decoration: InputDecoration(
            hintText: L10n.of(context).hintMessageDisplayName,
          ),
          style: Theme.of(context).textTheme.labelLarge,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return L10n.of(context).missingName;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildUsernameInputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).username),
        const SizedBox(height: 10),
        TextFormField(
          key: RegisterPage.usernameField,
          controller: username,
          decoration: InputDecoration(
            hintText: L10n.of(context).hintMessageUsername,
          ),
          inputFormatters: [
            TextInputFormatter.withFunction((
              TextEditingValue oldValue,
              TextEditingValue newValue,
            ) {
              return newValue.text.isEmpty ||
                      usernamePattern.hasMatch(newValue.text)
                  ? newValue
                  : oldValue;
            }),
          ],
          style: Theme.of(context).textTheme.labelLarge,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return L10n.of(context).emptyUsername;
            }
            final cleanedVal = val.trim().toLowerCase();
            if (!usernamePattern.hasMatch(cleanedVal)) {
              return 'Username may only contain letters a-z, numbers and any of  ._=-/';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordInputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).password),
        const SizedBox(height: 10),
        TextFormField(
          key: RegisterPage.passwordField,
          controller: password,
          decoration: InputDecoration(
            hintText: L10n.of(context).hintMessagePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _passwordVisible = !_passwordVisible;
                });
              },
            ),
          ),
          obscureText: !_passwordVisible,
          inputFormatters: [
            FilteringTextInputFormatter.deny(
              RegExp(r'\s'),
            ),
          ],
          style: Theme.of(context).textTheme.labelLarge,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return L10n.of(context).emptyPassword;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTokenInputField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                L10n.of(context).inviteCode,
              ),
            ),
            IconButton(
              onPressed: showInviteCodeDialog,
              icon: const Icon(Atlas.question_chat, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextFormField(
          key: RegisterPage.tokenField,
          controller: token,
          decoration: InputDecoration(
            hintText: L10n.of(context).hintMessageInviteCode,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.deny(
              RegExp(r'\s'),
            ),
          ],
          style: Theme.of(context).textTheme.labelLarge,
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return L10n.of(context).emptyToken;
            }
            return null;
          },
        ),
      ],
    );
  }

  void showInviteCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(L10n.of(context).inviteCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(L10n.of(context).inviteCodeInfo),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.neutral,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 10.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'tryacter',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      onPressed: () async {
                        context.pop(); // close the drawer
                        EasyLoading.showToast(
                          L10n.of(context).inviteCopiedToClipboard,
                          toastPosition: EasyLoadingToastPosition.bottom,
                        );
                        await Clipboard.setData(
                          const ClipboardData(text: 'tryacter'),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            OutlinedButton(
              child: Text(L10n.of(context).ok),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermsAcceptText(BuildContext context) {
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        // Note: Styles for TextSpans must be explicitly defined.
        // Child text spans will inherit styles from parent
        children: <TextSpan>[
          TextSpan(
            text: '${L10n.of(context).termsText1} ',
          ),
          TextSpan(
            style: const TextStyle(
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _log.info(L10n.of(context).termsOfService);
              },
            text: L10n.of(context).termsOfService,
          ),
          TextSpan(text: ' ${L10n.of(context).and} '),
          TextSpan(
            style: const TextStyle(
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _log.info(L10n.of(context).privacyPolicy);
              },
            text: L10n.of(context).privacyPolicy,
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpButton(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return authState
        ? const Center(child: CircularProgressIndicator())
        : ActerPrimaryActionButton(
            key: RegisterPage.submitBtn,
            onPressed: () => handleSubmit(context),
            child: Text(
              L10n.of(context).createProfile,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
  }

  Widget _buildLoginAccountButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          L10n.of(context).haveProfile,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ActerInlineTextButton(
          key: Keys.loginBtn,
          onPressed: () => context.goNamed(Routes.authLogin.name),
          child: Text(
            L10n.of(context).logIn,
          ),
        ),
      ],
    );
  }
}
