import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SasCancelledView extends StatelessWidget {
  final String sender;
  final bool isVerifier;
  final String? message;
  final Function(BuildContext) onDone;

  const SasCancelledView({
    super.key,
    required this.sender,
    required this.isVerifier,
    this.message,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackMsg = L10n.of(context).verificationConclusionCompromised;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: buildTitleBar(context),
          ),
          const Spacer(),
          const Icon(Atlas.lock_keyhole),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(message ?? fallbackMsg),
          ),
          const Spacer(),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.40,
            child: ActerPrimaryActionButton(
              child: Text(L10n.of(context).sasGotIt),
              onPressed: () => onDone(context),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildTitleBar(BuildContext context) {
    // has no close button
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
        ),
        const SizedBox(width: 5),
        Text(
          isVerifier
              ? L10n.of(context).verifyOtherSession
              : L10n.of(context).verifyThisSession,
        ),
      ],
    );
  }
}
