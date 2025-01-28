import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class MessageActionsWidget extends StatelessWidget {
  final bool isMe;
  final bool canRedact;
  final String messageId;
  final String roomId;
  const MessageActionsWidget({
    super.key,
    required this.isMe,
    required this.canRedact,
    required this.messageId,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Container(
      constraints: const BoxConstraints(maxWidth: 200),
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
      ),
      child: Column(
        children: menuItems(context, lang).map((e) => e).toList(),
      ),
    );
  }

  List<Widget> menuItems(BuildContext context, L10n lang) => [
        makeMenuItem(
          pressed: () {},
          text: Text(lang.reply),
          icon: const Icon(Icons.reply_rounded, size: 18),
        ),
        //  if (isTextMessage)
        //     makeMenuItem(
        //       pressed: () => onCopyMessage(context, ref, message),
        //       text: Text(lang.copyMessage),
        //       icon: const Icon(
        //         Icons.copy_all_outlined,
        //         size: 14,
        //       ),
        //     ),
        if (isMe)
          makeMenuItem(
            pressed: () {},
            text: Text(lang.edit),
            icon: const Icon(Atlas.pencil_box_bold, size: 14),
          ),
        if (!isMe)
          makeMenuItem(
            pressed: () {},
            text: Text(
              lang.report,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            icon: Icon(
              Icons.flag_outlined,
              size: 14,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        if (canRedact)
          makeMenuItem(
            pressed: () {},
            text: Text(
              lang.delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            icon: Icon(
              Atlas.trash_can_thin,
              size: 14,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ];

  Widget makeMenuItem({
    required Widget text,
    Icon? icon,
    required void Function() pressed,
  }) {
    return InkWell(
      onTap: pressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 3,
          vertical: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            text,
            if (icon != null) icon,
          ],
        ),
      ),
    );
  }
}
