import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class SasAcceptedView extends StatelessWidget {
  final String sender;
  final bool isVerifier;

  const SasAcceptedView({
    super.key,
    required this.sender,
    required this.isVerifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: buildTitleBar(context),
          ),
          const Spacer(),
          const Center(
            child: SizedBox(
              height: 100,
              width: 100,
              child: CircularProgressIndicator(),
            ),
          ),
          const Spacer(),
          Text(L10n.of(context).verificationRequestWaitingFor(sender)),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildTitleBar(BuildContext context) {
    final lang = L10n.of(context);
    // has no close button
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
        ),
        const SizedBox(width: 5),
        Text(isVerifier ? lang.verifyOtherSession : lang.verifyThisSession),
      ],
    );
  }
}
