import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/sdk_provider.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/validation_utils.dart';
import 'package:acter/config/env.g.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::auth::forgot_password');

class ForgotPassword extends ConsumerStatefulWidget {
  static Key passwordKey = const Key('pw-reset-password-field');
  static Key emailFieldKey = const Key('pw-reset-email-field');
  static Key submitKey = const Key('pw-reset-submit-btn');

  const ForgotPassword({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends ConsumerState<ForgotPassword> {
  PasswordChangeEmailTokenResponse? tokenResponse;

  @override
  Widget build(BuildContext context) {
    final sdk = ref.watch(sdkProvider).valueOrNull;
    if (sdk == null) {
      return SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(L10n.of(context).loading),
          ),
        ),
      );
    }
    return tokenResponse.map(
          (resp) => _NewPassword(tokenResponse: resp, sdk: sdk),
        ) ??
        _AskForEmail(
          sdk: sdk,
          onSubmit: (resp) => setState(() => tokenResponse = resp),
        );
  }
}

class _AskForEmail extends StatelessWidget {
  final void Function(PasswordChangeEmailTokenResponse) onSubmit;
  final ActerSdk sdk;

  _AskForEmail({required this.onSubmit, required this.sdk});

  final formKey = GlobalKey<FormState>(debugLabel: 'ask for email form');
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppbar(), body: _buildBody(context));
  }

  AppBar _buildAppbar() {
    return AppBar(backgroundColor: Colors.transparent);
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildTitleText(context),
              const SizedBox(height: 30),
              _buildImage(context),
              const SizedBox(height: 30),
              _buildDescriptionText(context),
              const SizedBox(height: 30),
              _buildEmailInputField(context),
              const SizedBox(height: 20),
              _buildButton(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleText(BuildContext context) {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            lang.passwordResetTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.textHighlight,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(lang.forgotYourPassword),
        Text(lang.noWorriesWeHaveGotYouCovered),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageSize = screenHeight / 4;
    return SvgPicture.asset(
      'assets/images/forgot_password.svg',
      height: imageSize,
      width: imageSize,
    );
  }

  Widget _buildDescriptionText(BuildContext context) {
    return Text(L10n.of(context).forgotPasswordDescription);
  }

  Widget _buildEmailInputField(BuildContext context) {
    final lang = L10n.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.emailAddress),
          const SizedBox(height: 10),
          TextFormField(
            key: ForgotPassword.emailFieldKey,
            controller: emailController,
            decoration: InputDecoration(hintText: lang.hintEmail),
            style: Theme.of(context).textTheme.labelLarge,
            validator: (val) => validateEmail(context, val),
          ),
        ],
      ),
    );
  }

  Future<void> _forgotPassword(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.sendingEmail);
    try {
      final resp = await sdk.api.requestPasswordChangeTokenViaEmail(
        Env.defaultHomeserverUrl,
        emailController.text.trim(),
      );
      EasyLoading.dismiss();
      onSubmit(resp);
    } catch (e, s) {
      _log.severe('Requesting password reset failed', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.sendingEmailFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildButton(BuildContext context) {
    return ActerPrimaryActionButton(
      key: ForgotPassword.submitKey,
      onPressed: () => _forgotPassword(context),
      child: Text(
        L10n.of(context).sendEmail,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _NewPassword extends StatelessWidget {
  final PasswordChangeEmailTokenResponse tokenResponse;
  final ActerSdk sdk;

  _NewPassword({required this.tokenResponse, required this.sdk});

  final formKey = GlobalKey<FormState>(debugLabel: 'new password form');
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: _buildAppbar(), body: _buildBody(context));
  }

  AppBar _buildAppbar() {
    return AppBar(backgroundColor: Colors.transparent);
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildTitleText(context),
              const SizedBox(height: 20),
              _buildDescriptionText(context),
              const SizedBox(height: 30),
              _buildPasswordInputField(context),
              const SizedBox(height: 20),
              _buildButton(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            L10n.of(context).passwordResetTitle,
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: Theme.of(context).colorScheme.textHighlight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionText(BuildContext context) {
    return Text(L10n.of(context).forgotPasswordNewPasswordDescription);
  }

  Widget _buildPasswordInputField(BuildContext context) {
    final lang = L10n.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lang.newPassword),
          const SizedBox(height: 10),
          TextFormField(
            key: ForgotPassword.passwordKey,
            controller: passwordController,
            decoration: InputDecoration(hintText: lang.hintMessagePassword),
            style: Theme.of(context).textTheme.labelLarge,
            // required field, space allowed
            validator:
                (val) =>
                    val == null || val.length < 6
                        ? lang.hintMessagePassword
                        : null,
          ),
        ],
      ),
    );
  }

  void _resetPassword(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;

    final lang = L10n.of(context);
    EasyLoading.show(status: lang.resettingPassword);
    try {
      await sdk.api.resetPassword(
        Env.defaultHomeserverUrl,
        tokenResponse.sid(),
        tokenResponse.clientSecret(),
        passwordController.text,
      );
      EasyLoading.showToast(lang.resettingPasswordSuccessful);
      if (context.mounted) context.goNamed(Routes.authLogin.name);
    } catch (e, s) {
      _log.severe('Requesting reset failed', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.resettingPasswordFailed(e),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildButton(BuildContext context) {
    return ActerPrimaryActionButton(
      key: ForgotPassword.submitKey,
      onPressed: () => _resetPassword(context),
      child: Text(
        L10n.of(context).resetPassword,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
