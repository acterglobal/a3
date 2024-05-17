import 'package:acter/common/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EncryptedMessageWidget extends StatelessWidget {
  const EncryptedMessageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      child: Text(
        L10n.of(context).encryptedChatMessage,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
              color: Theme.of(context).colorScheme.neutral5,
              fontStyle: FontStyle.italic,
            ),
      ),
    );
  }
}
