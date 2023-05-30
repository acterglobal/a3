import 'package:acter/common/states/network_state.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/states/auth_state.dart';
import 'package:acter/features/onboarding/widgets/onboarding_fields.dart';
import 'package:acter/main/routing/routes.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class RegisterPage extends ConsumerStatefulWidget {
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

  void _validateRegister(BuildContext context) {
    final bool isLoggedIn = ref.read(isLoggedInProvider);
    if (isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.success,
          content: Text(AppLocalizations.of(context)!.loginSuccess),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(AppLocalizations.of(context)!.loginFailed),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    final authState = ref.watch(authStateProvider);
    var network = ref.watch(networkAwareProvider);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: desktop
                  ? InkWell(
                      onTap: () => context.goNamed(Routes.main.name),
                      child: const Icon(Atlas.arrow_left_circle),
                    )
                  : null,
            ),
            SliverToBoxAdapter(
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
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!.createAccountText,
                    ),
                    const SizedBox(height: 20),
                    RegisterTextField(
                      hintText: AppLocalizations.of(context)!.name,
                      controller: name,
                      validatorText: AppLocalizations.of(context)!.missingName,
                      type: RegisterOnboardingTextFieldEnum.name,
                    ),
                    RegisterTextField(
                      hintText: AppLocalizations.of(context)!.username,
                      controller: username,
                      validatorText:
                          AppLocalizations.of(context)!.emptyUsername,
                      type: RegisterOnboardingTextFieldEnum.userName,
                    ),
                    RegisterTextField(
                      hintText: AppLocalizations.of(context)!.password,
                      controller: password,
                      validatorText:
                          AppLocalizations.of(context)!.emptyPassword,
                      type: RegisterOnboardingTextFieldEnum.password,
                    ),
                    RegisterTextField(
                      hintText: AppLocalizations.of(context)!.token,
                      controller: token,
                      validatorText: AppLocalizations.of(context)!.emptyToken,
                      type: RegisterOnboardingTextFieldEnum.token,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          // Note: Styles for TextSpans must be explicitly defined.
                          // Child text spans will inherit styles from parent

                          children: <TextSpan>[
                            TextSpan(
                              text:
                                  '${AppLocalizations.of(context)!.termsText1} ',
                            ),
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  debugPrint('Terms of Service"');
                                },
                              text: AppLocalizations.of(context)!.termsText2,
                            ),
                            TextSpan(
                              text:
                                  ' ${AppLocalizations.of(context)!.termsText3} ',
                            ),
                            TextSpan(
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  debugPrint('policy"');
                                },
                              text: AppLocalizations.of(context)!.termsText4,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    authState
                        ? const CircularProgressIndicator()
                        : CustomButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                if (network == NetworkStatus.Off) {
                                  showNoInternetNotification();
                                } else {
                                  await ref
                                      .read(authStateProvider.notifier)
                                      .register(
                                        username.text,
                                        password.text,
                                        name.text,
                                        token.text,
                                        context,
                                      );
                                  _validateRegister(context);
                                }
                              }
                            },
                            title: AppLocalizations.of(context)!.register,
                          ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.haveAccount}  ',
                        ),
                        InkWell(
                          onTap: () => context.goNamed(Routes.authLogin.name),
                          child: Text(
                            AppLocalizations.of(context)!.logIn,
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
            ),
          ],
        ),
      ),
    );
  }
}
