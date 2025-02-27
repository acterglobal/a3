import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';

class RequestDoneView extends StatelessWidget {
  final bool isVerifier;
  final String sender;
  final Function(BuildContext) onDone;

  const RequestDoneView({
    super.key,
    required this.sender,
    required this.isVerifier,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: buildTitleBar(context),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              isVerifier
                  ? lang.verificationConclusionOkDone(sender)
                  : lang.verificationConclusionOkSelfNotice,
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
          const Center(child: Icon(Atlas.lock_keyhole)),
          const Spacer(),
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.40,
              child: ActerPrimaryActionButton(
                child: Text(lang.sasGotIt),
                onPressed: () => onDone(context),
              ),
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
        Text(L10n.of(context).sasVerified),
      ],
    );
  }
}
