import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/features/chat_ng/providers/chat_list_providers.dart';
import 'package:acter/features/chat_ng/widgets/chat_item/last_message_widgets/text_message_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileChangesEventWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;
  final TextStyle? textStyle;
  final TextAlign? textAlign;

  const ProfileChangesEventWidget({
    super.key,
    required this.roomId,
    required this.eventItem,
    this.textStyle,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //Return empty if membership content is not found
    ProfileContent? content = eventItem.profileContent();
    if (content == null) return const SizedBox.shrink();

    //Get sender user name
    final senderId = eventItem.sender();
    final senderName = ref.watch(
      lastMessageDisplayNameProvider((roomId: roomId, userId: senderId)),
    );

    //Get content user name
    final userId = content.userId().toString();
    final userName = ref.watch(
      lastMessageDisplayNameProvider((roomId: roomId, userId: userId)),
    );

    //Get membership event text
    final membershipEventText = _getProfileChangeEventText(
      context: context,
      ref: ref,
      userName: userName,
      senderName: senderName,
      content: content,
    );

    //Return empty if text is null
    if (membershipEventText == null) return const SizedBox.shrink();

    final messageTextStyle =
        textStyle ?? lastMessageTextStyle(context, ref, roomId);

    //Render membership event text
    return Text(
      membershipEventText,
      maxLines: 2,
      style: messageTextStyle,
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
    );
  }

  String? _getProfileChangeEventText({
    required BuildContext context,
    required WidgetRef ref,
    required String userName,
    required String senderName,
    required ProfileContent content,
  }) {
    //Get language
    final lang = L10n.of(context);
    //Get my id
    final myId = ref.watch(myUserIdStrProvider);
    //Check if the action is mine
    final isMyAction = eventItem.sender().toString() == myId;

    final oldVal = content.displayNameOldVal() ?? '';
    final newVal = content.displayNameNewVal() ?? '';

    if (content.displayNameChange() != null) {
      return switch (content.displayNameChange()) {
        'Changed' =>
          isMyAction
              ? lang.chatProfileDisplayNameYouChanged(newVal)
              : lang.chatProfileDisplayNameOtherChanged(oldVal, newVal),
        'Set' =>
          isMyAction
              ? lang.chatProfileDisplayNameYouSet(newVal)
              : lang.chatProfileDisplayNameOtherSet(userName, newVal),
        'Unset' =>
          isMyAction
              ? lang.chatProfileDisplayNameYouUnset
              : lang.chatProfileDisplayNameOtherUnset(userName),
        _ => null,
      };
    }

    if (content.avatarUrlChange() != null) {
      return switch (content.avatarUrlChange()) {
        'Changed' =>
          isMyAction
              ? lang.chatProfileAvatarUrlYouChanged
              : lang.chatProfileAvatarUrlOtherChanged(userName),
        'Set' =>
          isMyAction
              ? lang.chatProfileAvatarUrlYouSet
              : lang.chatProfileAvatarUrlOtherSet(userName),
        'Unset' =>
          isMyAction
              ? lang.chatProfileAvatarUrlYouUnset
              : lang.chatProfileAvatarUrlOtherUnset(userName),
        _ => null,
      };
    }

    return null;
  }
}
