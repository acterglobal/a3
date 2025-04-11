import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart'
    show ProfileContent, TimelineEventItem;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::chat_ng::widgets::profile_update');

class ProfileUpdateEvent extends ConsumerWidget {
  final bool isMe;
  final String roomId;
  final TimelineEventItem item;

  const ProfileUpdateEvent({
    super.key,
    required this.isMe,
    required this.roomId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    TextSpan? textSpan = buildStateWidget(context, ref, item);
    if (textSpan == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.only(left: 10, bottom: 5, right: 10),
      child: RichText(text: textSpan),
    );
  }

  TextSpan? buildStateWidget(
    BuildContext context,
    WidgetRef ref,
    TimelineEventItem item,
  ) {
    final myId = ref.read(myUserIdStrProvider);
    ProfileContent? content = item.profileContent();
    if (content == null) {
      _log.severe('failed to get content of profile change');
      return null;
    }
    final userId = content.userId().toString();
    final userName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        simplifyUserId(userId) ??
        userId;
    switch (content.displayNameChange()) {
      case 'Changed':
        return buildDisplayNameChangedMessage(
          context,
          myId,
          userId,
          content.displayNameNewVal() ?? '',
          content.displayNameOldVal() ?? '',
        );
      case 'Set':
        return buildDisplayNameSetMessage(
          context,
          myId,
          userId,
          content.displayNameNewVal() ?? '',
        );
      case 'Unset':
        return buildDisplayNameUnsetMessage(context, myId, userId, userName);
    }
    switch (content.avatarUrlChange()) {
      case 'Changed':
        return buildAvatarUrlChangedMessage(context, myId, userId, userName);
      case 'Set':
        return buildAvatarUrlSetMessage(context, myId, userId, userName);
      case 'Unset':
        return buildAvatarUrlUnsetMessage(context, myId, userId, userName);
    }
    return null;
  }

  TextSpan buildDisplayNameChangedMessage(
    BuildContext context,
    String myId,
    String userId,
    String newVal,
    String oldVal,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatProfileDisplayNameYouChanged(newVal),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatProfileDisplayNameOtherChanged(oldVal, newVal),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildDisplayNameSetMessage(
    BuildContext context,
    String myId,
    String userId,
    String newVal,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatProfileDisplayNameYouSet(newVal),
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatProfileDisplayNameOtherSet(userId, newVal),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildDisplayNameUnsetMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatProfileDisplayNameYouUnset,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatProfileDisplayNameOtherUnset(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildAvatarUrlChangedMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatProfileAvatarUrlYouChanged,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatProfileAvatarUrlOtherChanged(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildAvatarUrlSetMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatProfileAvatarUrlYouSet,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatProfileAvatarUrlOtherSet(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }

  TextSpan buildAvatarUrlUnsetMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    if (userId == myId) {
      return TextSpan(
        text: lang.chatProfileAvatarUrlYouUnset,
        style: Theme.of(context).textTheme.labelSmall,
      );
    } else {
      return TextSpan(
        text: lang.chatProfileAvatarUrlOtherUnset(userName),
        style: Theme.of(context).textTheme.labelSmall,
      );
    }
  }
}
