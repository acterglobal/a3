import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
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
            const Spacer(),
            _buildTitleText(context),
            const Spacer(),
            _buildImage(context),
            const Spacer(),
            _buildDescriptionText(context),
            const Spacer(),
            _buildButton(context),
            const Spacer(),
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
    var imageSize = screenHeight / 3;
    return SvgPicture.asset(
      'assets/icon/forgot_password.svg',
      height: imageSize,
      width: imageSize,
    );
  }

  Widget _buildDescriptionText(BuildContext context) {
    return Text(L10n.of(context).forgotPasswordDescription);
  }

  Widget _buildButton(BuildContext context) {
    return ActerPrimaryActionButton(
      onPressed: () async => await mailTo(toAddress: 'support@acter.global'),
      child: Text(
        L10n.of(context).contactActerSupport,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
