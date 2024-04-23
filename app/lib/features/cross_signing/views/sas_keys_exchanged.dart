import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/toolkit/buttons/danger_action_button.dart';
import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class SasKeysExchangedView extends StatelessWidget {
  final String sender;
  final bool isVerifier;
  final FfiListVerificationEmoji emojis;
  final Function(BuildContext) onCancel;
  final Function(BuildContext) onMatch;
  final Function(BuildContext) onMismatch;

  const SasKeysExchangedView({
    super.key,
    required this.sender,
    required this.isVerifier,
    required this.emojis,
    required this.onCancel,
    required this.onMatch,
    required this.onMismatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: buildTitleBar(context),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              L10n.of(context).verificationEmojiNotice,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Theme.of(context).colorScheme.neutral2,
              ),
              child: buildEmojis(context),
            ),
          ),
          const Spacer(),
          buildActionButtons(context),
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
          child: isDesktop ? const Icon(Atlas.laptop) : const Icon(Atlas.phone),
        ),
        const SizedBox(width: 5),
        Text(
          isVerifier
              ? L10n.of(context).verifyOtherSession
              : L10n.of(context).verifyThisSession,
        ),
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

  Widget buildEmojis(BuildContext context) {
    return GridView.count(
      crossAxisCount: isDesktop ? 7 : 4,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: List.generate(emojis.length, (index) {
        final emoji = emojis.elementAt(index);
        return GridTile(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                String.fromCharCode(emoji.symbol()),
                style: const TextStyle(fontSize: 32),
                textAlign: TextAlign.center,
              ),
              Text(
                emoji.description(),
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ActerDangerActionButton(
          onPressed: () => onMismatch(context),
          child: Text(L10n.of(context).verificationSasDoNotMatch),
        ),
        ActerPrimaryActionButton(
          child: Text(L10n.of(context).verificationSasMatch),
          onPressed: () => onMatch(context),
        ),
      ],
    );
  }
}
