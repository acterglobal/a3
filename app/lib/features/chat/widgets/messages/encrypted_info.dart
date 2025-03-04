import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:acter/l10n/generated/l10n.dart';

class EncryptedInfoWidget extends StatelessWidget {
  const EncryptedInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: SelectionArea(
          child: Container(
            padding: const EdgeInsets.all(15),
            child: ListTile(
              leading: const Icon(Atlas.shield_chat_thin),
              title: Text(
                L10n.of(context).encryptedChatInfo,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
