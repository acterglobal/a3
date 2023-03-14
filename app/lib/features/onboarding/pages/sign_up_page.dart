import 'package:acter/common/controllers/network_controller.dart';
import 'package:acter/common/themes/seperated_themes.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/controllers/auth_controller.dart';
import 'package:acter/features/onboarding/pages/login_page.dart';
import 'package:acter/features/onboarding/widgets/onboarding_fields.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:themed/themed.dart';

class SignupPage extends ConsumerStatefulWidget {
  const SignupPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SignupPageState();
}

class _SignupPageState extends ConsumerState<SignupPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController username = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController token = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController name = TextEditingController();

  void _validateSignUp(BuildContext context) async {
    final bool isLoggedIn = ref.read(isLoggedInProvider);
    if (isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginSuccess),
          backgroundColor: AuthTheme.authSuccess,
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.loginFailed),
          backgroundColor: AuthTheme.authFailed,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    var network = ref.watch(networkAwareProvider);
    return Scaffold(
      body: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              SizedBox(
                height: 50,
                width: 50,
                child: SvgPicture.asset('assets/icon/acter.svg'),
              ),
              const SizedBox(height: 40),
              Text(
                AppLocalizations.of(context)!.onboardText,
                style: AuthTheme.authTitleStyle,
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.createAccountText,
                style: AuthTheme.authBodyStyle,
              ),
              const SizedBox(height: 20),
              SignUpTextField(
                hintText: AppLocalizations.of(context)!.name,
                controller: name,
                validatorText: AppLocalizations.of(context)!.missingName,
                type: SignUpOnboardingTextFieldEnum.name,
              ),
              SignUpTextField(
                hintText: AppLocalizations.of(context)!.username,
                controller: username,
                validatorText: AppLocalizations.of(context)!.emptyUsername,
                type: SignUpOnboardingTextFieldEnum.userName,
              ),
              SignUpTextField(
                hintText: AppLocalizations.of(context)!.password,
                controller: password,
                validatorText: AppLocalizations.of(context)!.emptyPassword,
                type: SignUpOnboardingTextFieldEnum.password,
              ),
              SignUpTextField(
                hintText: AppLocalizations.of(context)!.token,
                controller: token,
                validatorText: AppLocalizations.of(context)!.emptyToken,
                type: SignUpOnboardingTextFieldEnum.token,
              ),
              const SizedBox(height: 30),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.start,
                  text: TextSpan(
                    // Note: Styles for TextSpans must be explicitly defined.
                    // Child text spans will inherit styles from parent
                    style: AuthTheme.authBodyStyle,
                    children: <TextSpan>[
                      TextSpan(
                        text: '${AppLocalizations.of(context)!.termsText1} ',
                      ),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            debugPrint('Terms of Service"');
                          },
                        text: AppLocalizations.of(context)!.termsText2,
                        style: AuthTheme.authBodyStyle +
                            AppCommonTheme.primaryColor,
                      ),
                      TextSpan(
                        text: ' ${AppLocalizations.of(context)!.termsText3} ',
                      ),
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            debugPrint('policy"');
                          },
                        text: AppLocalizations.of(context)!.termsText4,
                        style: AuthTheme.authBodyStyle +
                            AppCommonTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              authState
                  ? const CircularProgressIndicator(
                      color: AppCommonTheme.primaryColor,
                    )
                  : CustomButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          if (network == NetworkStatus.Off) {
                            showNoInternetNotification();
                          } else {
                            await ref
                                .read(authControllerProvider.notifier)
                                .signUp(
                                  username.text,
                                  password.text,
                                  name.text,
                                  token.text,
                                  context,
                                );
                            _validateSignUp(context);
                          }
                        }
                      },
                      title: AppLocalizations.of(context)!.signUp,
                    ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.haveAccount}  ',
                    style: AuthTheme.authBodyStyle,
                  ),
                  InkWell(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.login,
                      style:
                          AuthTheme.authBodyStyle + AppCommonTheme.primaryColor,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
