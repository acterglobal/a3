import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/constants.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class IntroPage extends StatelessWidget {
  const IntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: introGradient),
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
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            text: L10n.of(context).welcomeTo,
            style: Theme.of(context).textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.textHighlight,
                ),
            children: <TextSpan>[
              TextSpan(
                text: L10n.of(context).acter,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          L10n.of(context).yourSafeAndSecureSpace,
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    final imageSize = MediaQuery.of(context).size.height / 4;
    return Image.asset(
      'assets/icon/intro.png',
      height: imageSize,
      width: imageSize,
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                text: L10n.of(context).introPageDescription1,
                style: Theme.of(context).textTheme.bodyMedium,
                children: <TextSpan>[
                  TextSpan(
                    text: L10n.of(context).introPageDescription2,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.textHighlight,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              L10n.of(context).introPageDescription3,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
          onPressed: () => context.goNamed(Routes.start.name),
          icon: const Icon(
            Icons.arrow_forward_ios,
            size: 18,
          ),
          label: Text(
            L10n.of(context).letsExplore,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
      ),
    );
  }
}
