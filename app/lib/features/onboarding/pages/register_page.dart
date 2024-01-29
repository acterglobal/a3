import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/base_body_widget.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:acter/features/settings/super_invites/providers/super_invites_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

final log = Logger('Register');

Future<void> tryRedeem(SuperInvites superInvites, String token) async {
  // try to redeem the token in a fire-and-forget-manner
  try {
    await superInvites.redeem(
      token,
    );
  } catch (error) {
    log.warning('redeeming super invite failed: $error');
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

  final usernamePattern = RegExp(r'^[a-z0-9._=\-/]+$');

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
        if (errorMsg != null) {
          EasyLoading.showError(errorMsg);
        }
        if (token.text.isNotEmpty) {
          final superInvites = ref.read(superInvitesProvider);
          tryRedeem(superInvites, token.text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.watch(authStateProvider.notifier);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      primary: false,
      body: BaseBody(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  actions: [
                    if (canGuestLogin)
                      OutlinedButton(
                        onPressed: () async =>
                            await authNotifier.makeGuest(context),
                        child: const Text('Continue as guest'),
                      ),
                  ],
                  title: Text(
                    AppLocalizations.of(context)!.register,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: SvgPicture.asset('assets/icon/acter.svg'),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          AppLocalizations.of(context)!.onboardText,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          AppLocalizations.of(context)!.createAccountText,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            TextFormField(
                              key: RegisterPage.nameField,
                              controller: name,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.name,
                              ),
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
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              key: RegisterPage.usernameField,
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
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              key: RegisterPage.passwordField,
                              controller: password,
                              decoration: InputDecoration(
                                hintText:
                                    AppLocalizations.of(context)!.password,
                              ),
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                  RegExp(r'\s'),
                                ),
                              ],
                              style: Theme.of(context).textTheme.labelLarge,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .emptyPassword;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              key: RegisterPage.tokenField,
                              controller: token,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.token,
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                  RegExp(r'\s'),
                                ),
                              ],
                              style: Theme.of(context).textTheme.labelLarge,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .emptyToken;
                                }
                                return null;
                              },
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
                                        debugPrint('Terms of Service"');
                                      },
                                    text: AppLocalizations.of(context)!
                                        .termsText2,
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
                                    text: AppLocalizations.of(context)!
                                        .termsText4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        authState
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                key: RegisterPage.submitBtn,
                                onPressed: handleSubmit,
                                child: Text(
                                  AppLocalizations.of(context)!.register,
                                ),
                              ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.haveAccount}  ',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            TextButton(
                              key: Keys.loginBtn,
                              onPressed: () =>
                                  context.goNamed(Routes.authLogin.name),
                              child: Text(
                                AppLocalizations.of(context)!.logIn,
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
        ),
      ),
    );
  }
}
