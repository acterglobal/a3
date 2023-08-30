import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        final authNotifier = ref.read(authStateProvider.notifier);
        final loginSuccess = await authNotifier.login(
          username.text,
          password.text,
        );

        // We are doing as expected, but the lints triggers.
        // ignore: use_build_context_synchronously
        if (!context.mounted) {
          return;
        }
        if (loginSuccess == null) {
          // no message means, login was successful.
          context.goNamed(Routes.main.name);
        } else {
          customMsgSnackbar(context, loginSuccess);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      primary: false,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.logIn),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Form(
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
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      height: 60,
                      child: TextFormField(
                        key: LoginPageKeys.usernameField,
                        obscureText: false,
                        controller: username,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.username,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        style: Theme.of(context).textTheme.labelLarge,
                        cursorColor: Theme.of(context).colorScheme.tertiary2,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return AppLocalizations.of(context)!.emptyUsername;
                          }
                          return null;
                        },
                        onChanged: (value) {
                          username.text = value;
                          username.selection = TextSelection.fromPosition(
                            TextPosition(offset: username.text.length),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      height: 60,
                      child: TextFormField(
                        key: LoginPageKeys.passwordField,
                        controller: password,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.password,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(RegExp(r'\s')),
                        ],
                        style: Theme.of(context).textTheme.labelLarge,
                        cursorColor: Theme.of(context).colorScheme.tertiary2,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return AppLocalizations.of(context)!.emptyPassword;
                          }
                          return null;
                        },
                        onChanged: (value) {
                          password.text = value;
                          password.selection = TextSelection.fromPosition(
                            TextPosition(offset: password.text.length),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      key: LoginPageKeys.forgotPassBtn,
                      margin: const EdgeInsets.only(right: 20),
                      width: double.infinity,
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {},
                        child:
                            Text(AppLocalizations.of(context)!.forgotPassword),
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
                          onTap: () =>
                              context.goNamed(Routes.authRegister.name),
                          child: Text(
                            AppLocalizations.of(context)!.register,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ),
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
