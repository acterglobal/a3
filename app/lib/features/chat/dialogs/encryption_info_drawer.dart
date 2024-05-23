import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

void showEncryptionInfoBottomSheet({
  required BuildContext context,
}) {
  showModalBottomSheet(
    showDragHandle: false,
    useSafeArea: true,
    context: context,
    isDismissible: false,
    builder: (context) {
      return const EncryptionInfoSheet();
    },
  );
}

class EncryptionInfoSheet extends StatelessWidget {
  const EncryptionInfoSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                L10n.of(context).encryptedChatMessageInfoTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (context.canPop())
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    L10n.of(context).close,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            L10n.of(context).encryptedChatMessageInfo,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.pop(),
            child: Text(L10n.of(context).close),
          ),
        ],
      ),
    );
  }
}
