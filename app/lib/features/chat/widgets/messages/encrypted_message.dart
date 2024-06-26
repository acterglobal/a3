import 'package:acter/features/chat/dialogs/encryption_info_drawer.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EncryptedMessageWidget extends StatelessWidget {
  const EncryptedMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showEncryptionInfoBottomSheet(context: context),
      child: Container(
        padding: const EdgeInsets.all(18),
        child: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: Icon(
                    Atlas.block_shield_thin,
                    size: Theme.of(context).textTheme.labelSmall?.fontSize,
                    color: Theme.of(context).textTheme.labelSmall?.color,
                  ),
                ),
              ),
              TextSpan(
                text: L10n.of(context).encryptedChatMessage,
                style: Theme.of(context).textTheme.labelSmall!.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
