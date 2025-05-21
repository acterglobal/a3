import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/config/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:go_router/go_router.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(resizeToAvoidBottomInset: true, body: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          const Spacer(),
          _buildTitle(context),
          const Spacer(),
          _buildImage(context),
          const Spacer(),
          _buildDescription(context),
          const Spacer(),
          _buildButton(context),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: lang.welcomeTo,
            style: textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.textHighlight,
            ),
            children: <TextSpan>[TextSpan(text: lang.acter)],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          lang.yourSafeAndSecureSpace,
          style: textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    // limit the to always show the button even if the keyboard is opened
    final imageSize = MediaQuery.of(context).size.height / 5;
    return Image.asset(
      'assets/images/intro.png',
      height: imageSize,
      width: imageSize,
    );
  }

  Widget _buildDescription(BuildContext context) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: lang.introPageDescriptionPre,
                style: textTheme.bodyMedium,
                children: <TextSpan>[
                  TextSpan(
                    text: lang.introPageDescriptionHl,
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.textHighlight,
                    ),
                  ),
                  TextSpan(text: lang.introPageDescriptionPost),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(lang.introPageDescription2ndLine, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ActerPrimaryActionButton.icon(
          key: Keys.exploreBtn,
          onPressed: () => context.goNamed(Routes.introProfile.name),
          icon: const Icon(Icons.arrow_forward_ios, size: 18),
          label: Text(
            L10n.of(context).letsGetStarted,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ),
    );
  }
}
