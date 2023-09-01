import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/custom_button.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final usernamePattern = RegExp(r'^[a-z0-9._=\-/]+$');

  void validateRegister(BuildContext context, errMsg) {
    if (errMsg == null) {
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
          content: Text(errMsg),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> handleSubmit() async {
    if (formKey.currentState!.validate()) {
      final network = ref.read(networkAwareProvider);
      if (!inCI && network == NetworkStatus.Off) {
        showNoInternetNotification();
      } else {
        final authNotifier = ref.read(authStateProvider.notifier);
        final errorMsg = await authNotifier.register(
          username.text,
          password.text,
          name.text,
          token.text,
          context,
        );
        if (context.mounted) {
          validateRegister(context, errorMsg);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.watch(authStateProvider.notifier);
    return Scaffold(
      primary: false,
      appBar: AppBar(
        actions: [
          if (canGuestLogin)
            OutlinedButton(
              onPressed: () async => await authNotifier.makeGuest(context),
              child: const Text('Continue as guest'),
            ),
        ],
        title: Text(AppLocalizations.of(context)!.register),
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
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: name,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.name,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              style: Theme.of(context).textTheme.labelLarge,
                              cursorColor:
                                  Theme.of(context).colorScheme.tertiary2,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .missingName;
                                }
                                return null;
                              },
                              onChanged: (value) {
                                name.text = value;
                                name.selection = TextSelection.fromPosition(
                                  TextPosition(offset: name.text.length),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: username,
                              decoration: InputDecoration(
                                hintText:
                                    AppLocalizations.of(context)!.username,
                              ),
                              inputFormatters: [
                                TextInputFormatter.withFunction((
                                  TextEditingValue oldValue,
                                  TextEditingValue newValue,
                                ) {
                                  return newValue.text.isEmpty ||
                                          usernamePattern
                                              .hasMatch(newValue.text)
                                      ? newValue
                                      : oldValue;
                                }),
                              ],
                              style: Theme.of(context).textTheme.labelLarge,
                              cursorColor:
                                  Theme.of(context).colorScheme.tertiary2,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .emptyUsername;
                                }
                                final cleanedVal = val.trim().toLowerCase();
                                if (!usernamePattern.hasMatch(cleanedVal)) {
                                  return 'Username may only contain letters a-z, numbers and any of  ._=-/';
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
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: password,
                              decoration: InputDecoration(
                                hintText:
                                    AppLocalizations.of(context)!.password,
                              ),
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              style: Theme.of(context).textTheme.labelLarge,
                              cursorColor:
                                  Theme.of(context).colorScheme.tertiary2,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .emptyPassword;
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
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 60,
                            child: TextFormField(
                              controller: token,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.token,
                              ),
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(RegExp(r'\s')),
                              ],
                              style: Theme.of(context).textTheme.labelLarge,
                              cursorColor:
                                  Theme.of(context).colorScheme.tertiary2,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .emptyToken;
                                }
                                return null;
                              },
                              onChanged: (value) {
                                token.text = value;
                                token.selection = TextSelection.fromPosition(
                                  TextPosition(offset: token.text.length),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 30),
                          RichText(
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
                                      debugPrint('Terms of Service');
                                    },
                                  text:
                                      AppLocalizations.of(context)!.termsText2,
                                ),
                                TextSpan(
                                  text:
                                      ' ${AppLocalizations.of(context)!.termsText3} ',
                                ),
                                TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      debugPrint('policy');
                                    },
                                  text:
                                      AppLocalizations.of(context)!.termsText4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    authState
                        ? const CircularProgressIndicator()
                        : CustomButton(
                            onPressed: handleSubmit,
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
