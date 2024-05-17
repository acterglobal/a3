import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EncryptedInfoWidget extends StatelessWidget {
  const EncryptedInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
          child: Container(
        padding: const EdgeInsets.all(15),
        child: ListTile(
          leading: const Icon(Atlas.shield_chat),
          title: Text(
            L10n.of(context).encryptedChatInfo,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ),
      )),
    );
  }
}
