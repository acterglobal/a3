import 'package:acter/common/extensions/acter_build_context.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/settings/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::settings::change_password');

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final formKey = GlobalKey<FormState>(debugLabel: 'change password form');
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
      child: Scaffold(appBar: _buildAppbar(), body: _buildBody()),
    );
  }

  AppBar _buildAppbar() {
    return AppBar(
      automaticallyImplyLeading: !context.isLargeScreen,
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
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.oldPassword),
        const SizedBox(height: 10),
        TextFormField(
          controller: oldPassword,
          obscureText: !_oldPasswordVisible,
          decoration: InputDecoration(
            hintText: lang.hintMessagePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _oldPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _oldPasswordVisible = !_oldPasswordVisible);
              },
            ),
          ),
          // required field, space allowed
          validator:
              (val) =>
                  val == null || val.isEmpty ? lang.emptyOldPassword : null,
        ),
      ],
    );
  }

  Widget _buildNewPasswordInputField() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.newPassword),
        const SizedBox(height: 10),
        TextFormField(
          controller: newPassword,
          obscureText: !_newPasswordVisible,
          decoration: InputDecoration(
            hintText: lang.hintMessagePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _newPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() => _newPasswordVisible = !_newPasswordVisible);
              },
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          // required field, space allowed
          validator:
              (val) =>
                  val == null || val.isEmpty ? lang.emptyNewPassword : null,
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordInputField() {
    final lang = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.confirmPassword),
        const SizedBox(height: 10),
        TextFormField(
          controller: confirmPassword,
          obscureText: !_confirmPasswordVisible,
          decoration: InputDecoration(
            hintText: lang.hintMessagePassword,
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
          inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
          // required field, space allowed
          validator: (val) {
            if (val == null || val.isEmpty) {
              return lang.emptyConfirmPassword;
            } else if (val != newPassword.text) {
              return lang.validateSamePassword;
            }
            return null;
          },
        ),
      ],
    );
  }

  void _changePassword(BuildContext context) async {
    if (!formKey.currentState!.validate()) return;
    final lang = L10n.of(context);
    EasyLoading.show(status: lang.changingYourPassword);
    try {
      final client = await ref.read(alwaysClientProvider.future);
      final account = client.account();
      await account.changePassword(
        oldPassword.text.trim(),
        newPassword.text.trim(),
      );
      oldPassword.clear();
      newPassword.clear();
      confirmPassword.clear();
      if (!context.mounted) return;
      EasyLoading.showSuccess(lang.passwordChangedSuccessfully);
    } catch (e, s) {
      _log.severe('Failed to change password', e, s);
      if (!context.mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.changePasswordFailed(e),
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
