import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/validation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgotPassword extends StatelessWidget {
  ForgotPassword({super.key});

  final formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      appBar: _buildAppbar(),
      body: _buildBody(context),
    );
  }

  AppBar _buildAppbar() {
    return AppBar(
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildTitleText(context),
              const SizedBox(height: 30),
              _buildImage(context),
              const SizedBox(height: 30),
              _buildDescriptionText(context),
              const SizedBox(height: 30),
              _buildEmailInputField(context),
              const SizedBox(height: 20),
              _buildButton(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.center,
          child: Text(
            L10n.of(context).passwordRecovery,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color: Theme.of(context).colorScheme.textHighlight,
                ),
          ),
        ),
        const SizedBox(height: 20),
        Text(L10n.of(context).forgotYourPassword),
        Text(L10n.of(context).noWorriesWeHaveGotYouCovered),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    var imageSize = screenHeight / 4;
    return SvgPicture.asset(
      'assets/icon/forgot_password.svg',
      height: imageSize,
      width: imageSize,
    );
  }

  Widget _buildDescriptionText(BuildContext context) {
    return Text(L10n.of(context).forgotPasswordDescription);
  }

  Widget _buildEmailInputField(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L10n.of(context).emailAddress),
          const SizedBox(height: 10),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(
              hintText: L10n.of(context).hintEmail,
            ),
            style: Theme.of(context).textTheme.labelLarge,
            validator: (val) => validateEmail(context, val),
          ),
        ],
      ),
    );
  }

  void _forgotPassword() {
    if (!formKey.currentState!.validate()) return;
  }

  Widget _buildButton(BuildContext context) {
    return ActerPrimaryActionButton(
      onPressed: _forgotPassword,
      child: Text(
        L10n.of(context).sendEmail,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
