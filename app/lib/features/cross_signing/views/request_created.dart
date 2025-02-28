import 'package:acter/common/themes/app_theme.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/l10n.dart';

class RequestCreatedView extends StatelessWidget {
  final Function(BuildContext) onCancel;

  const RequestCreatedView({super.key, required this.onCancel});

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            child: Text(
              L10n.of(context).verificationRequestAccept,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget buildTitleBar(BuildContext context) {
    // has close button
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          child: Icon(isDesktop ? Atlas.laptop : Atlas.phone),
        ),
        const SizedBox(width: 5),
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
