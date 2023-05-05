import 'package:acter/common/states/network_state.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/states/auth_state.dart';
import 'package:acter/features/onboarding/widgets/onboarding_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:acter/common/utils/constants.dart' show LoginPageKeys;
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

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  void _validateLogin() async {
    final isLoggedIn = ref.watch(isLoggedInProvider);

    if (isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: LoginPageKeys.snackbarSuccess,
          backgroundColor: Theme.of(context).colorScheme.success,
          content: Text(AppLocalizations.of(context)!.loginSuccess),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: LoginPageKeys.snackbarFailed,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(AppLocalizations.of(context)!.loginFailed),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    var network = ref.watch(networkAwareProvider);
    return SimpleDialog(
      title: const Text('Login'),
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: SvgPicture.asset(
                  'assets/icon/acter.svg',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.welcomeBack,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.signInContinue,
              ),
              const SizedBox(height: 40),
              SignInTextField(
                key: LoginPageKeys.usernameField,
                hintText: AppLocalizations.of(context)!.username,
                controller: username,
                validatorText: AppLocalizations.of(context)!.emptyUsername,
                type: SignInOnboardingTextFieldEnum.userName,
              ),
              const SizedBox(height: 20),
              SignInTextField(
                key: LoginPageKeys.passwordField,
                hintText: AppLocalizations.of(context)!.password,
                controller: password,
                validatorText: AppLocalizations.of(context)!.emptyPassword,
                type: SignInOnboardingTextFieldEnum.password,
              ),
              const SizedBox(height: 40),
              Container(
                key: LoginPageKeys.forgotPassBtn,
                margin: const EdgeInsets.only(right: 20),
                width: double.infinity,
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              authState
                  ? const CircularProgressIndicator()
                  : CustomButton(
                      key: LoginPageKeys.submitBtn,
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          if (network == NetworkStatus.Off) {
                            showNoInternetNotification();
                          } else {
                            await ref.read(authStateProvider.notifier).login(
                                  username.text,
                                  password.text,
                                  context,
                                );
                            _validateLogin();
                          }
                        }
                      },
                      title: AppLocalizations.of(context)!.login,
                    ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    AppLocalizations.of(context)!.noAccount,
                  ),
                  const SizedBox(width: 2),
                  InkWell(
                    key: LoginPageKeys.signUpBtn,
                    onTap: () => context.go('/signup'),
                    child: Text(
                      AppLocalizations.of(context)!.signUp,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
