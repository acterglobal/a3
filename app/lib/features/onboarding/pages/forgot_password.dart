import 'package:acter/common/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({super.key});

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
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            _buildTitleText(context),
            const Spacer(),
            _buildImage(),
            const Spacer(),
            _buildDescriptionText(context),
            const Spacer(),
            _buildButton(context),
            const SizedBox(height: 50),
          ],
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
                  color: Colors.green,
                ),
          ),
        ),
        const SizedBox(height: 20),
        Text(L10n.of(context).forgotPassword('withYour')),
        Text(L10n.of(context).noWorriesWeHaveGotYouCovered),
      ],
    );
  }

  Widget _buildImage() {
    return SvgPicture.asset(
      'assets/icon/forgot_password.svg',
      height: 300,
      width: 300,
    );
  }

  Widget _buildDescriptionText(BuildContext context) {
    return Text(L10n.of(context).forgotPasswordDescription);
  }

  Widget _buildButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async =>
          await openLink('https://next.acter.global/contact-us', context),
      child: Text(
        L10n.of(context).contactActerSupport,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
