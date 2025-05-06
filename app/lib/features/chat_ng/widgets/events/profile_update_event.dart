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
  final String roomId;
  final TimelineEventItem item;

  const ProfileUpdateEvent({
    super.key,
    required this.roomId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateText = getStateEventStr(context, ref, item);
    if (stateText == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      alignment: Alignment.center,
      child: Text(
        stateText,
        style: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  String? getStateEventStr(
    BuildContext context,
    WidgetRef ref,
    TimelineEventItem item,
  ) {
    final myId = ref.watch(myUserIdStrProvider);
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
    final lang = L10n.of(context);
    switch (content.displayNameChange()) {
      case 'Changed':
        return getMessageOnDisplayNameChanged(
          lang,
          myId,
          userId,
          content.displayNameNewVal() ?? '',
          content.displayNameOldVal() ?? '',
        );
      case 'Set':
        return getMessageOnDisplayNameSet(
          lang,
          myId,
          userId,
          content.displayNameNewVal() ?? '',
        );
      case 'Unset':
        return getMessageOnDisplayNameUnset(lang, myId, userId, userName);
    }
    switch (content.avatarUrlChange()) {
      case 'Changed':
        return getMessageOnAvatarUrlChanged(lang, myId, userId, userName);
      case 'Set':
        return getMessageOnAvatarUrlSet(lang, myId, userId, userName);
      case 'Unset':
        return getMessageOnAvatarUrlUnset(lang, myId, userId, userName);
    }
    return null;
  }

  String getMessageOnDisplayNameChanged(
    L10n lang,
    String myId,
    String userId,
    String newVal,
    String oldVal,
  ) {
    if (userId == myId) {
      return lang.chatProfileDisplayNameYouChanged(newVal);
    } else {
      return lang.chatProfileDisplayNameOtherChanged(oldVal, newVal);
    }
  }

  String getMessageOnDisplayNameSet(
    L10n lang,
    String myId,
    String userId,
    String newVal,
  ) {
    if (userId == myId) {
      return lang.chatProfileDisplayNameYouSet(newVal);
    } else {
      return lang.chatProfileDisplayNameOtherSet(userId, newVal);
    }
  }

  String getMessageOnDisplayNameUnset(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatProfileDisplayNameYouUnset;
    } else {
      return lang.chatProfileDisplayNameOtherUnset(userName);
    }
  }

  String getMessageOnAvatarUrlChanged(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatProfileAvatarUrlYouChanged;
    } else {
      return lang.chatProfileAvatarUrlOtherChanged(userName);
    }
  }

  String getMessageOnAvatarUrlSet(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatProfileAvatarUrlYouSet;
    } else {
      return lang.chatProfileAvatarUrlOtherSet(userName);
    }
  }

  String getMessageOnAvatarUrlUnset(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatProfileAvatarUrlYouUnset;
    } else {
      return lang.chatProfileAvatarUrlOtherUnset(userName);
    }
  }
}
