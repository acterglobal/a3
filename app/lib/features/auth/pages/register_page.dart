import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/auth/actions/register_action.dart';
import 'package:acter/features/auth/providers/auth_providers.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::auth::register');

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
  final formKey = GlobalKey<FormState>(debugLabel: 'register page form');
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
    final lang = L10n.of(context);
    try {
      if (await register(
        context: context,
        username: username.text,
        password: password.text,
        name: name.text,
        token: token.text,
        ref: ref,
      )) {
        if (context.mounted) {
          // context.goNamed(
          //   Routes.saveUsername.name,
          //   queryParameters: {'username': username.text},
          // );
          context.goNamed(Routes.redeemInvitations.name);
        }
      }
    } catch (errorMsg) {
      EasyLoading.showError(
        lang.registerFailed(errorMsg),
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [_buildAppBar(context), _buildRegisterPage(context)],
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
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          lang.createProfile,
          style: textTheme.headlineMedium?.copyWith(
            color: Theme.of(context).colorScheme.textHighlight,
          ),
        ),
        const SizedBox(height: 4),
        Text(lang.onboardText, style: textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildNameInputField(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.displayName),
        const SizedBox(height: 10),
        TextFormField(
          key: RegisterPage.nameField,
          controller: name,
          decoration: InputDecoration(hintText: lang.hintMessageDisplayName),
          style: Theme.of(context).textTheme.labelLarge,
          // required field, space not allowed
          validator:
              (val) =>
                  val == null || val.trim().isEmpty ? lang.missingName : null,
        ),
      ],
    );
  }

  Widget _buildUsernameInputField(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.username),
        const SizedBox(height: 10),
        TextFormField(
          key: RegisterPage.usernameField,
          controller: username,
          decoration: InputDecoration(hintText: lang.hintMessageUsername),
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
          // required field, space not allowed
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return lang.emptyUsername;
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
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.password),
        const SizedBox(height: 10),
        TextFormField(
          key: RegisterPage.passwordField,
          controller: password,
          decoration: InputDecoration(
            hintText: lang.hintMessagePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _passwordVisible = !_passwordVisible);
              },
            ),
          ),
          obscureText: !_passwordVisible,
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          style: Theme.of(context).textTheme.labelLarge,
          // required field, space allowed
          validator:
              (val) => val == null || val.isEmpty ? lang.emptyPassword : null,
        ),
      ],
    );
  }

  Widget _buildTokenInputField(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(lang.inviteCode)),
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
          decoration: InputDecoration(hintText: lang.hintMessageInviteCode),
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          style: Theme.of(context).textTheme.labelLarge,
          // required field, space not allowed
          validator:
              (val) =>
                  val == null || val.trim().isEmpty ? lang.emptyToken : null,
        ),
      ],
    );
  }

  void showInviteCodeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final lang = L10n.of(context);
        return AlertDialog(
          title: Text(lang.inviteCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(lang.inviteCodeInfo),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
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
                      'organize',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    IconButton(
                      onPressed: () async {
                        Navigator.pop(context); // close the drawer
                        EasyLoading.showToast(
                          lang.inviteCopiedToClipboard,
                          toastPosition: EasyLoadingToastPosition.bottom,
                        );
                        await Clipboard.setData(
                          const ClipboardData(text: 'organize'),
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
              child: Text(lang.ok),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTermsAcceptText(BuildContext context) {
    final lang = L10n.of(context);
    return RichText(
      textAlign: TextAlign.start,
      text: TextSpan(
        // Note: Styles for TextSpans must be explicitly defined.
        // Child text spans will inherit styles from parent
        children: <TextSpan>[
          TextSpan(text: '${lang.termsText1} '),
          TextSpan(
            style: const TextStyle(decoration: TextDecoration.underline),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () {
                    _log.info(lang.termsOfService);
                  },
            text: lang.termsOfService,
          ),
          TextSpan(text: ' ${lang.and} '),
          TextSpan(
            style: const TextStyle(decoration: TextDecoration.underline),
            recognizer:
                TapGestureRecognizer()
                  ..onTap = () {
                    _log.info(lang.privacyPolicy);
                  },
            text: lang.privacyPolicy,
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
    final lang = L10n.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(lang.haveProfile, style: Theme.of(context).textTheme.bodyMedium),
        ActerInlineTextButton(
          key: Keys.loginBtn,
          onPressed: () => context.goNamed(Routes.authLogin.name),
          child: Text(lang.logIn),
        ),
      ],
    );
  }
}
