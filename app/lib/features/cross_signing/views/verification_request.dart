import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';

class VerificationRequestView extends StatelessWidget {
  final String sender;
  final Function(BuildContext) onCancel;
  final Function(BuildContext) onAccept;

  const VerificationRequestView({
    super.key,
    required this.sender,
    required this.onCancel,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
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
          Text(lang.sasIncomingReqNotifContent(sender)),
          const Spacer(),
          const Icon(Atlas.lock_keyhole),
          const Spacer(),
          ActerPrimaryActionButton(
            child: Text(lang.acceptRequest),
            onPressed: () => onAccept(context),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildTitleBar(BuildContext context) {
    // has close button
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
        ),
        Text(L10n.of(context).sasIncomingReqNotifTitle),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => onCancel(context),
          ),
        ),
      ],
    );
  }
}
