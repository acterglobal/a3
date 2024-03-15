import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/base_body_widget.dart';
import 'package:acter/common/widgets/no_internet.dart';
import 'package:acter/features/onboarding/providers/onboarding_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
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
  bool _passwordVisible = false;

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
          EasyLoading.showError(
            loginSuccess,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return Scaffold(
      primary: false,
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      extendBodyBehindAppBar: true,
      body: BaseBody(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              title: Text(
                L10n.of(context).logIn,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            SliverToBoxAdapter(
              child: Form(
                key: formKey,
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          width: 50,
                          child: SvgPicture.asset('assets/icon/acter.svg'),
                        ),
                        const SizedBox(height: 20),
                        Text(L10n.of(context).welcomeBack),
                        const SizedBox(height: 20),
                        Text(L10n.of(context).loginContinue),
                        const SizedBox(height: 40),
                        TextFormField(
                          key: LoginPageKeys.usernameField,
                          obscureText: false,
                          controller: username,
                          decoration: InputDecoration(
                            hintText: L10n.of(context).username,
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
                        const SizedBox(height: 20),
                        TextFormField(
                          key: LoginPageKeys.passwordField,
                          controller: password,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            hintText: L10n.of(context).password,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _passwordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
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
                        const SizedBox(height: 40),
                        authState
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                key: LoginPageKeys.submitBtn,
                                onPressed: () => handleSubmit(context),
                                child: Text(
                                  L10n.of(context).logIn,
                                ),
                              ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(L10n.of(context).noAccount),
                            const SizedBox(width: 2),
                            TextButton(
                              key: LoginPageKeys.signUpBtn,
                              onPressed: () =>
                                  context.goNamed(Routes.authRegister.name),
                              child: Text(
                                L10n.of(context).register,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
