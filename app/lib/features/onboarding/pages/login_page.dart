import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:acter/features/onboarding/widgets/onboarding_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  Future<void> handleSubmit(BuildContext context) async {
    if (formKey.currentState!.validate()) {
      final network = ref.read(networkAwareProvider);
      if (!inCI && network == NetworkStatus.Off) {
        showNoInternetNotification();
      } else {
        final notifier = ref.read(authStateProvider.notifier);
        final login_success = await notifier.login(
          username.text,
          password.text,
        );
        if (login_success == null) {
          // no message means, login was successful.
          context.goNamed(Routes.main.name);
        } else {
          customMsgSnackbar(context, login_success);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return SimpleDialog(
      title: AppBar(
        title: Text(AppLocalizations.of(context)!.logIn),
      ),
      insetPadding: EdgeInsets.all(0),
      children: [
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 50,
                width: 50,
                child: SvgPicture.asset('assets/icon/acter.svg'),
              ),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.welcomeBack),
              const SizedBox(height: 20),
              Text(AppLocalizations.of(context)!.loginContinue),
              const SizedBox(height: 40),
              LoginTextField(
                key: LoginPageKeys.usernameField,
                hintText: AppLocalizations.of(context)!.username,
                controller: username,
                validatorText: AppLocalizations.of(context)!.emptyUsername,
                type: LoginOnboardingTextFieldEnum.userName,
              ),
              const SizedBox(height: 20),
              LoginTextField(
                key: LoginPageKeys.passwordField,
                hintText: AppLocalizations.of(context)!.password,
                controller: password,
                validatorText: AppLocalizations.of(context)!.emptyPassword,
                type: LoginOnboardingTextFieldEnum.password,
              ),
              const SizedBox(height: 40),
              Container(
                key: LoginPageKeys.forgotPassBtn,
                margin: const EdgeInsets.only(right: 20),
                width: double.infinity,
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(AppLocalizations.of(context)!.forgotPassword),
                ),
              ),
              const SizedBox(height: 40),
              authState
                  ? const CircularProgressIndicator()
                  : CustomButton(
                      key: LoginPageKeys.submitBtn,
                      onPressed: () => handleSubmit(context),
                      title: AppLocalizations.of(context)!.logIn,
                    ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(AppLocalizations.of(context)!.noAccount),
                  const SizedBox(width: 2),
                  InkWell(
                    key: LoginPageKeys.signUpBtn,
                    onTap: () => context.goNamed(Routes.authRegister.name),
                    child: Text(
                      AppLocalizations.of(context)!.register,
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
