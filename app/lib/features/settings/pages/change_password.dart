import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::room::change_password');

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController oldPassword = TextEditingController();
  final TextEditingController newPassword = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  bool _oldPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return WithSidebar(
      sidebar: const SettingsPage(),
      child: Scaffold(
        appBar: _buildAppbar(),
        body: _buildBody(),
      ),
    );
  }

  AppBar _buildAppbar() {
    return AppBar(
      backgroundColor: const AppBarTheme().backgroundColor,
      elevation: 0.0,
      title: Text(L10n.of(context).changePassword),
      centerTitle: true,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildOldPasswordInputField(),
                const SizedBox(height: 20),
                _buildNewPasswordInputField(),
                const SizedBox(height: 20),
                _buildConfirmPasswordInputField(),
                const SizedBox(height: 20),
                _buildChangePasswordButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOldPasswordInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).oldPassword),
        const SizedBox(height: 10),
        TextFormField(
          controller: oldPassword,
          obscureText: !_oldPasswordVisible,
          decoration: InputDecoration(
            hintText: L10n.of(context).hintMessagePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _oldPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _oldPasswordVisible = !_oldPasswordVisible;
                });
              },
            ),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return L10n.of(context).emptyOldPassword;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNewPasswordInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).newPassword),
        const SizedBox(height: 10),
        TextFormField(
          controller: newPassword,
          obscureText: !_newPasswordVisible,
          decoration: InputDecoration(
            hintText: L10n.of(context).hintMessagePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _newPasswordVisible = !_newPasswordVisible;
                });
              },
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return L10n.of(context).emptyNewPassword;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(L10n.of(context).confirmPassword),
        const SizedBox(height: 10),
        TextFormField(
          controller: confirmPassword,
          obscureText: !_confirmPasswordVisible,
          decoration: InputDecoration(
            hintText: L10n.of(context).hintMessagePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _confirmPasswordVisible
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _confirmPasswordVisible = !_confirmPasswordVisible;
                });
              },
            ),
          ),
          inputFormatters: [
            FilteringTextInputFormatter.deny(RegExp(r'\s')),
          ],
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return L10n.of(context).emptyConfirmPassword;
            } else if (val.trim() != newPassword.text.trim()) {
              return L10n.of(context).validateSamePassword;
            }
            return null;
          },
        ),
      ],
    );
  }

  void _changePassword(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    EasyLoading.show(status: L10n.of(context).changingYourPassword);
    try {
      final client = ref.read(alwaysClientProvider);
      final account = client.account();
      await account.changePassword(
        oldPassword.text.trim(),
        newPassword.text.trim(),
      );
      oldPassword.clear();
      newPassword.clear();
      confirmPassword.clear();
      if (!context.mounted) return;
      EasyLoading.showSuccess(L10n.of(context).passwordChangedSuccessfully);
    } catch (err) {
      EasyLoading.dismiss();
      _log.severe('Change password failed', err);
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).changePasswordFailed(err),
        duration: const Duration(seconds: 3),
      );
    }
  }

  Widget _buildChangePasswordButton() {
    return ActerPrimaryActionButton(
      onPressed: () => _changePassword(context),
      child: Text(L10n.of(context).changePassword),
    );
  }
}
