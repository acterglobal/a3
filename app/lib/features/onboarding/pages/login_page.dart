import 'package:acter/common/providers/network_provider.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:acter/features/onboarding/widgets/logo_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _passwordVisible = false;

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      body: Form(
        key: formKey,
        child: Column(
          children: [
            _buildAppBar(context),
            _buildLoginPage(context),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildLoginPage(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var imageSize = screenHeight / 5;
    return Expanded(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (screenHeight > 650)
                LogoWidget(width: imageSize, height: imageSize),
              _buildHeadlineText(context),
              const SizedBox(height: 24),
              _buildUsernameInputField(context),
              const SizedBox(height: 12),
              _buildPasswordInputField(context),
              const SizedBox(height: 12),
              _buildForgotPassword(context),
              const SizedBox(height: 20),
              _buildLoginButton(context),
              const SizedBox(height: 12),
              _buildRegisterAccountButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeadlineText(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          L10n.of(context).welcomeBack,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(color: Theme.of(context).colorScheme.textHighlight),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            L10n.of(context).loginContinue,
            textAlign: TextAlign.center,
          ),
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
          key: LoginPageKeys.usernameField,
          controller: username,
          decoration: InputDecoration(
            hintText: L10n.of(context).hintMessageUsername,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return L10n.of(context).emptyUsername;
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
          key: LoginPageKeys.passwordField,
          controller: password,
          obscureText: !_passwordVisible,
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
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
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

  Widget _buildLoginButton(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return authState
        ? const Center(child: CircularProgressIndicator())
        : ActerPrimaryActionButton(
            key: LoginPageKeys.submitBtn,
            onPressed: () => handleSubmit(context),
            child: Text(
              L10n.of(context).logIn,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: ActerInlineTextButton(
        key: LoginPageKeys.forgotPassBtn,
        onPressed: () => context.pushNamed(Routes.forgotPassword.name),
        child: Text(
          L10n.of(context).forgotPassword,
        ),
      ),
    );
  }

  Widget _buildRegisterAccountButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(L10n.of(context).noProfile),
        const SizedBox(width: 2),
        ActerInlineTextButton(
          key: LoginPageKeys.signUpBtn,
          onPressed: () => context.goNamed(Routes.authRegister.name),
          child: Text(
            L10n.of(context).createProfile,
          ),
        ),
      ],
    );
  }

  Future<void> handleSubmit(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    if (!inCI && !ref.read(hasNetworkProvider)) {
      showNoInternetNotification(context);
      return;
    }
    final authNotifier = ref.read(authStateProvider.notifier);
    final loginSuccess = await authNotifier.login(
      username.text,
      password.text,
    );

    if (!context.mounted) return;
    if (loginSuccess == null) {
      // no message means, login was successful.
      context.goNamed(Routes.main.name);
    } else {
      EasyLoading.showError(
        loginSuccess,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
