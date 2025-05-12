import 'package:acter/features/chat/dialogs/encryption_info_drawer.dart';
import 'package:acter/features/chat_ng/widgets/events/state_event_container_widget.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class EncryptedMessageWidget extends StatelessWidget {
  const EncryptedMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = stateEventTextStyle(context);
    return GestureDetector(
      onTap: () => showEncryptionInfoBottomSheet(context: context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              Atlas.block_shield_thin,
              size: textTheme.fontSize,
              color: textTheme.color,
            ),
            const SizedBox(width: 6),
            Text(L10n.of(context).encryptedChatMessage, style: textTheme),
          ],
        ),
      ),
    );
  }
}
