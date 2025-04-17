import 'package:acter/common/extensions/options.dart';
import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/colors/color_scheme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';
import 'package:acter/features/labs/model/labs_features.dart';
import 'package:acter/features/labs/providers/labs_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::convo_card');

class ConvoCard extends ConsumerWidget {
  final String roomId;

  final Function()? onTap;

  /// Whether or not to render the parents Icon
  final bool showParents;

  /// Custom Trailing Widget
  final Widget? trailing;
  final bool showSelectedIndication;
  final bool showSuggestedMark;

  final Animation<double>? animation;

  const ConvoCard({
    super.key,
    required this.roomId,
    this.animation,
    this.onTap,
    this.showParents = true,
    this.trailing,
    this.showSelectedIndication = true,
    this.showSuggestedMark = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inner = buildInner(context, ref);
    return animation.map(
          (val) => SizeTransition(sizeFactor: val, child: inner),
        ) ??
        inner;
  }

  Widget buildInner(BuildContext context, WidgetRef ref) {
    final displayNameProvider = ref.watch(roomDisplayNameProvider(roomId));
    final titleIsLoading = displayNameProvider.isLoading;
    final displayName = displayNameProvider.valueOrNull ?? roomId;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: ListTile(
                dense: true,
                onTap: onTap,
                selected:
                    showSelectedIndication &&
                    roomId == ref.watch(selectedChatIdProvider),
                selectedTileColor: Theme.of(context).colorScheme.primary,
                leading: avatarWithIndicator(context, ref),
                title:
                    titleIsLoading
                        ? Skeletonizer(child: Text(roomId))
                        : Text(
                          displayName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                subtitle: buildSubtitle(context, constraints),
                trailing:
                    constraints.maxWidth < 300
                        ? null
                        : trailing ?? _TrailingWidget(roomId: roomId),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget? buildSubtitle(BuildContext context, BoxConstraints constraints) {
    if (!showSuggestedMark) {
      return constraints.maxWidth < 300
          ? null
          : _SubtitleWidget(roomId: roomId);
    }

    return Row(
      children: [
        Text(
          L10n.of(context).suggested,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(width: 2),
        Expanded(child: _SubtitleWidget(roomId: roomId)),
      ],
    );
  }

  Widget avatarWithIndicator(BuildContext context, WidgetRef ref) {
    final child = RoomAvatar(roomId: roomId, showParents: showParents);
    if (!ref.watch(isActiveProvider(LabsFeature.chatUnread))) {
      // only when the user has activated this feature
      return child;
    }
    final unreadCounters =
        ref.watch(unreadCountersProvider(roomId)).valueOrNull;

    if (unreadCounters == null) return child;

    final (notifications, mentions, messages) = unreadCounters;
    final colorScheme = Theme.of(context).colorScheme;
    if (notifications > 0) {
      return Badge(backgroundColor: colorScheme.badgeImportant, child: child);
    } else if (mentions > 0) {
      return Badge(backgroundColor: colorScheme.badgeUrgent, child: child);
    } else if (messages > 0) {
      return Badge(backgroundColor: colorScheme.badgeUnread, child: child);
    }
    // nothing urgent enough for us to indicate anything
    return child;
  }

  Widget renderTrailing(BuildContext context, WidgetRef ref) {
    final mutedStatus = ref.watch(roomIsMutedProvider(roomId));
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _TrailingWidget(roomId: roomId),
        if (mutedStatus.valueOrNull == true)
          Expanded(
            child: MenuAnchor(
              builder: (
                BuildContext context,
                MenuController controller,
                Widget? child,
              ) {
                return IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    if (controller.isOpen) {
                      controller.close();
                    } else {
                      controller.open();
                    }
                  },
                  icon: const Icon(Atlas.bell_dash_bold, size: 14),
                );
              },
              menuChildren: [
                MenuItemButton(
                  onPressed: () => onUnmute(context, ref),
                  child: Text(L10n.of(context).unmute),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> onUnmute(BuildContext context, WidgetRef ref) async {
    final lang = L10n.of(context);
    final room = await ref.read(maybeRoomProvider(roomId).future);
    if (room == null) {
      _log.severe('Room not found: $roomId');
      if (!context.mounted) return;
      EasyLoading.showError(
        lang.roomNotFound,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    await room.unmute();
    if (!context.mounted) return;
    EasyLoading.showToast(lang.notificationsUnmuted);
    await Future.delayed(const Duration(seconds: 1), () {
      // FIXME: we want to refresh the view but don’t know
      //        when the event was confirmed form sync :(
      // let’s hope that a second delay is reasonable enough
      ref.invalidate(maybeRoomProvider(roomId));
    });
  }
}

class _SubtitleWidget extends ConsumerWidget {
  final String roomId;

  const _SubtitleWidget({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(chatTypingEventProvider(roomId)).valueOrNull;
    if (users != null && users.isNotEmpty) {
      return renderTypingState(context, users, ref);
    }

    final latestMessage = ref.watch(latestMessageProvider(roomId)).valueOrNull;

    TimelineEventItem? eventItem = latestMessage?.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }

    String sender = eventItem.sender();
    String eventType = eventItem.eventType();
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    // message event
    switch (eventType) {
      case 'm.call.answer':
      case 'm.call.candidates':
      case 'm.call.hangup':
      case 'm.call.invite':
      case 'm.room.message':
        switch (eventItem.msgType()) {
          case 'm.audio':
          case 'm.file':
          case 'm.image':
          case 'm.video':
          case 'm.emote':
          case 'm.location':
          case 'm.key.verification.request':
          case 'm.notice':
          case 'm.server_notice':
          case 'm.text':
            MsgContent? msgContent = eventItem.message();
            if (msgContent == null) {
              _log.severe('failed to get content of room message');
              return const SizedBox.shrink();
            }
            String body = msgContent.body();
            String? formattedBody = msgContent.formattedBody();
            if (formattedBody != null) {
              body = simplifyBody(formattedBody);
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${simplifyUserId(sender)}: ',
                    style: textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Html(
                    // ignore: unnecessary_string_interpolations
                    data: '''$body''',
                    maxLines: 1,
                    defaultTextStyle: textTheme.labelMedium?.copyWith(
                      overflow: TextOverflow.ellipsis,
                    ),
                    onLinkTap: (url) => {},
                  ),
                ),
              ],
            );
        }
      case 'm.policy.rule.room':
      case 'm.policy.rule.server':
      case 'm.policy.rule.user':
      case 'm.room.aliases':
      case 'm.room.avatar':
      case 'm.room.canonical_alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest_access':
      case 'm.room.history_visibility':
      case 'm.room.join_rules':
      case 'm.room.name':
      case 'm.room.pinned_events':
      case 'm.room.power_levels':
      case 'm.room.server_acl':
      case 'm.room.third_party_invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
        return _RoomUpdateWidget(roomId: roomId, eventItem: eventItem);
      case 'm.reaction':
        MsgContent? msgContent = eventItem.message();
        if (msgContent == null) {
          return const SizedBox();
        }
        String body = msgContent.body();
        String? formattedBody = msgContent.formattedBody();
        if (formattedBody != null) {
          body = simplifyBody(formattedBody);
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Html(
                // ignore: unnecessary_string_interpolations
                data: '''$body''',
                maxLines: 1,
                defaultTextStyle: textTheme.labelMedium?.copyWith(
                  overflow: TextOverflow.ellipsis,
                ),
                onLinkTap: (url) => {},
              ),
            ),
          ],
        );
      case 'm.sticker':
        MsgContent? msgContent = eventItem.message();
        if (msgContent == null) {
          _log.severe('failed to get content of sticker event');
          return const SizedBox.shrink();
        }
        final body = msgContent.body();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                body,
                style: textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'm.room.redaction':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                lang.thisMessageHasBeenDeleted,
                style: textTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'm.room.encrypted':
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                lang.failedToDecryptMessage,
                style: textTheme.labelMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'MembershipChange':
        return _MembershipUpdateWidget(roomId: roomId, eventItem: eventItem);
      case 'ProfileChange':
        return _ProfileUpdateWidget(roomId: roomId, eventItem: eventItem);
      case 'm.poll.start':
        MsgContent? msgContent = eventItem.message();
        if (msgContent == null) {
          _log.severe('failed to get content of poll event');
          return const SizedBox.shrink();
        }
        final body = msgContent.body();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                body,
                style: textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
    }
    return const SizedBox.shrink();
  }

  Widget renderTypingState(
    BuildContext context,
    List<User> users,
    WidgetRef ref,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (users.length == 1) {
      final userId = users[0].id;
      final userName = simplifyUserId(userId) ?? userId;
      return Text(lang.typingUser1(userName), style: textTheme.bodySmall);
    } else if (users.length == 2) {
      final userId1 = users[0].id;
      final userName1 = simplifyUserId(userId1) ?? userId1;
      final userId2 = users[1].id;
      final userName2 = simplifyUserId(userId2) ?? userId2;
      return Text(
        lang.typingUser2(userName1, userName2),
        style: textTheme.bodySmall,
      );
    } else {
      final userId = users[0].id;
      final userName = simplifyUserId(userId) ?? userId;
      return Text(
        lang.typingUserN(userName, {users.length - 1}),
        style: textTheme.bodySmall,
      );
    }
  }
}

class _TrailingWidget extends ConsumerWidget {
  final String roomId;

  const _TrailingWidget({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestMessage = ref.watch(latestMessageProvider(roomId)).valueOrNull;
    TimelineEventItem? eventItem = latestMessage?.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }

    return Text(
      jiffyTime(context, eventItem.originServerTs()),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class _MembershipUpdateWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const _MembershipUpdateWidget({
    required this.roomId,
    required this.eventItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    MembershipContent? content = eventItem.membershipContent();
    if (content == null) {
      _log.severe('failed to get content of membership change');
      return const SizedBox.shrink();
    }
    final senderId = eventItem.sender();
    final senderName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull ??
        simplifyUserId(senderId) ??
        senderId;
    final userId = content.userId().toString();
    final userName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        simplifyUserId(userId) ??
        userId;
    final lang = L10n.of(context);
    final stateText = switch (content.change()) {
      'joined' => getMessageOnJoined(lang, myId, userId, userName),
      'left' => getMessageOnLeft(lang, myId, userId, userName),
      'banned' => getMessageOnBanned(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'unbanned' => getMessageOnUnbanned(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'kicked' => getMessageOnKicked(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'invited' => getMessageOnInvited(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'kickedAndBanned' => getMessageOnKickedAndBanned(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'invitationAccepted' => getMessageOnInvitationAccepted(
        lang,
        myId,
        userId,
        userName,
      ),
      'invitationRejected' => getMessageOnInvitationRejected(
        lang,
        myId,
        userId,
        userName,
      ),
      'invitationRevoked' => getMessageOnInvitationRevoked(
        lang,
        myId,
        userId,
        userName,
      ),
      'knocked' => getMessageOnKnocked(
        lang,
        myId,
        senderId,
        senderName,
        userId,
        userName,
      ),
      'knockAccepted' => getMessageOnKnockAccepted(
        lang,
        myId,
        userId,
        userName,
      ),
      'knockRetracted' => getMessageOnKnockRetracted(
        lang,
        myId,
        userId,
        userName,
      ),
      'knockDenied' => getMessageOnKnockDenied(lang, myId, userId, userName),
      _ => null,
    };
    if (stateText == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            stateText,
            maxLines: 1,
            style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String getMessageOnJoined(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipYouJoined;
    } else {
      return lang.chatMembershipOtherJoined(userName);
    }
  }

  String getMessageOnLeft(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipYouLeft;
    } else {
      return lang.chatMembershipOtherLeft(userName);
    }
  }

  String getMessageOnBanned(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouBannedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherBannedYou(senderName);
    } else {
      return lang.chatMembershipOtherBannedOther(senderName, userName);
    }
  }

  String getMessageOnUnbanned(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouUnbannedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherUnbannedYou(senderName);
    } else {
      return lang.chatMembershipOtherUnbannedOther(senderName, userName);
    }
  }

  String getMessageOnKicked(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouKickedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherKickedYou(senderName);
    } else {
      return lang.chatMembershipOtherKickedOther(senderName, userName);
    }
  }

  String getMessageOnInvited(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouInvitedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherInvitedYou(senderName);
    } else {
      return lang.chatMembershipOtherInvitedOther(senderName, userName);
    }
  }

  String getMessageOnKickedAndBanned(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouKickedAndBannedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherKickedAndBannedYou(senderName);
    } else {
      return lang.chatMembershipOtherKickedAndBannedOther(senderName, userName);
    }
  }

  String getMessageOnInvitationAccepted(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipInvitationYouAccepted;
    } else {
      return lang.chatMembershipInvitationOtherAccepted(userName);
    }
  }

  String getMessageOnInvitationRejected(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipInvitationYouRejected;
    } else {
      return lang.chatMembershipInvitationOtherRejected(userName);
    }
  }

  String getMessageOnInvitationRevoked(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipInvitationYouRevoked;
    } else {
      return lang.chatMembershipInvitationOtherRevoked(userName);
    }
  }

  String getMessageOnKnocked(
    L10n lang,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    if (senderId == myId) {
      return lang.chatMembershipYouKnockedOther(userName);
    } else if (userId == myId) {
      return lang.chatMembershipOtherKnockedYou(senderName);
    } else {
      return lang.chatMembershipOtherKnockedOther(senderName, userName);
    }
  }

  String getMessageOnKnockAccepted(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipKnockYouAccepted;
    } else {
      return lang.chatMembershipKnockOtherAccepted(userName);
    }
  }

  String getMessageOnKnockRetracted(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipKnockYouRetracted;
    } else {
      return lang.chatMembershipKnockOtherRetracted(userName);
    }
  }

  String getMessageOnKnockDenied(
    L10n lang,
    String myId,
    String userId,
    String userName,
  ) {
    if (userId == myId) {
      return lang.chatMembershipKnockYouDenied;
    } else {
      return lang.chatMembershipKnockOtherDenied(userName);
    }
  }
}

class _ProfileUpdateWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const _ProfileUpdateWidget({required this.roomId, required this.eventItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    ProfileContent? content = eventItem.profileContent();
    if (content == null) {
      _log.severe('failed to get content of membership change');
      return const SizedBox.shrink();
    }
    final userId = content.userId().toString();
    final userName =
        ref
            .watch(memberDisplayNameProvider((roomId: roomId, userId: userId)))
            .valueOrNull ??
        simplifyUserId(userId) ??
        userId;
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    String? stateText = switch (content.displayNameChange()) {
      'Changed' => getMessageOnDisplayNameChanged(
        lang,
        myId,
        userId,
        content.displayNameNewVal() ?? '',
        content.displayNameOldVal() ?? '',
      ),
      'Set' => getMessageOnDisplayNameSet(
        lang,
        myId,
        userId,
        content.displayNameNewVal() ?? '',
      ),
      'Unset' => getMessageOnDisplayNameSet(lang, myId, userId, userName),
      _ => null,
    };
    if (stateText != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              stateText,
              maxLines: 1,
              style: textTheme.labelMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    stateText = switch (content.avatarUrlChange()) {
      'Changed' => getMessageOnAvatarUrlChanged(lang, myId, userId, userName),
      'Set' => getMessageOnAvatarUrlSet(lang, myId, userId, userName),
      'Unset' => getMessageOnAvatarUrlUnset(lang, myId, userId, userName),
      _ => null,
    };
    if (stateText != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              stateText,
              maxLines: 1,
              style: textTheme.labelMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
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

class _RoomUpdateWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const _RoomUpdateWidget({required this.roomId, required this.eventItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(myUserIdStrProvider);
    final senderId = eventItem.sender();
    final isMe = senderId == myId;
    final senderName =
        ref
            .watch(
              memberDisplayNameProvider((roomId: roomId, userId: senderId)),
            )
            .valueOrNull ??
        simplifyUserId(senderId) ??
        senderId;
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    String? stateText = switch (eventItem.eventType()) {
      'm.policy.rule.room' => getMessageOnPolicyRuleRoom(
        lang,
        isMe,
        senderName,
      ),
      'm.policy.rule.server' => getMessageOnPolicyRuleServer(
        lang,
        isMe,
        senderName,
      ),
      'm.policy.rule.user' => getMessageOnPolicyRuleUser(
        lang,
        isMe,
        senderName,
      ),
      'm.room.aliases' => getMessageOnRoomAliases(lang, isMe, senderName),
      'm.room.avatar' => getMessageOnRoomAvatar(lang, isMe, senderName),
      'm.room.canonical_alias' => getMessageOnRoomCanonicalAlias(
        lang,
        isMe,
        senderName,
      ),
      'm.room.create' => getMessageOnRoomCreate(lang, isMe, senderName),
      'm.room.encryption' => getMessageOnRoomEncryption(lang, isMe, senderName),
      'm.room.guest_access' => getMessageOnRoomGuestAccess(
        lang,
        isMe,
        senderName,
      ),
      'm.room.history_visibility' => getMessageOnRoomHistoryVisibility(
        lang,
        isMe,
        senderName,
      ),
      'm.room.join_rules' => getMessageOnRoomJoinRules(lang, isMe, senderName),
      'm.room.name' => getMessageOnRoomName(lang, isMe, senderName),
      'm.room.pinned_events' => getMessageOnRoomPinnedEvents(
        lang,
        isMe,
        senderName,
      ),
      'm.room.power_levels' => getMessageOnRoomPowerLevels(
        lang,
        isMe,
        senderName,
      ),
      'm.room.server_acl' => getMessageOnRoomServerAcl(lang, isMe, senderName),
      'm.room.third_party_invite' => getMessageOnRoomThirdPartyInvite(
        lang,
        isMe,
        senderName,
      ),
      'm.room.tombstone' => getMessageOnRoomTombstone(lang, isMe, senderName),
      'm.room.topic' => getMessageOnRoomTopic(lang, isMe, senderName),
      'm.space.child' => getMessageOnSpaceChild(lang, isMe, senderName),
      'm.space.parent' => getMessageOnSpaceParent(lang, isMe, senderName),
      _ => null,
    };
    if (stateText == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            stateText,
            maxLines: 1,
            style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String? getMessageOnPolicyRuleRoom(L10n lang, bool isMe, String senderName) {
    final content = eventItem.policyRuleRoomContent();
    if (content == null) {
      _log.severe('failed to get content of policy rule room change');
      return null;
    }
    switch (content.entityChange()) {
      case 'Changed':
        final newVal = content.entityNewVal();
        final oldVal = content.entityOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleRoomEntityYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleRoomEntityOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.entityNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleRoomEntityYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleRoomEntityOtherSet(senderName, newVal);
        }
    }
    switch (content.reasonChange()) {
      case 'Changed':
        final newVal = content.reasonNewVal();
        final oldVal = content.reasonOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleRoomReasonYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleRoomReasonOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.reasonNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleRoomReasonYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleRoomReasonOtherSet(senderName, newVal);
        }
    }
    switch (content.recommendationChange()) {
      case 'Changed':
        final newVal = content.recommendationNewVal();
        final oldVal = content.recommendationOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleRoomRecommendationYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStatePolicyRuleRoomRecommendationOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.recommendationNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleRoomRecommendationYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleRoomRecommendationOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnPolicyRuleServer(
    L10n lang,
    bool isMe,
    String senderName,
  ) {
    final content = eventItem.policyRuleServerContent();
    if (content == null) {
      _log.severe('failed to get content of policy rule server change');
      return null;
    }
    switch (content.entityChange()) {
      case 'Changed':
        final newVal = content.entityNewVal();
        final oldVal = content.entityOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleServerEntityYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleServerEntityOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.entityNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleServerEntityYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleServerEntityOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.reasonChange()) {
      case 'Changed':
        final newVal = content.reasonNewVal();
        final oldVal = content.reasonOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleServerReasonYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleServerReasonOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.reasonNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleServerReasonYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleServerReasonOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.recommendationChange()) {
      case 'Changed':
        final newVal = content.recommendationNewVal();
        final oldVal = content.recommendationOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleServerRecommendationYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStatePolicyRuleServerRecommendationOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.recommendationNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleServerRecommendationYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleServerRecommendationOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnPolicyRuleUser(L10n lang, bool isMe, String senderName) {
    final content = eventItem.policyRuleUserContent();
    if (content == null) {
      _log.severe('failed to get content of policy rule user change');
      return null;
    }
    switch (content.entityChange()) {
      case 'Changed':
        final newVal = content.entityNewVal();
        final oldVal = content.entityOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleUserEntityYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleUserEntityOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.entityNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleUserEntityYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleUserEntityOtherSet(senderName, newVal);
        }
    }
    switch (content.reasonChange()) {
      case 'Changed':
        final newVal = content.reasonNewVal();
        final oldVal = content.reasonOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleUserReasonYouChanged(oldVal, newVal);
        } else {
          return lang.roomStatePolicyRuleUserReasonOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.reasonNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleUserReasonYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleUserReasonOtherSet(senderName, newVal);
        }
    }
    switch (content.recommendationChange()) {
      case 'Changed':
        final newVal = content.recommendationNewVal();
        final oldVal = content.recommendationOldVal() ?? '';
        if (isMe) {
          return lang.roomStatePolicyRuleUserRecommendationYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStatePolicyRuleUserRecommendationOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.recommendationNewVal();
        if (isMe) {
          return lang.roomStatePolicyRuleUserRecommendationYouSet(newVal);
        } else {
          return lang.roomStatePolicyRuleUserRecommendationOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnRoomAliases(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomAliasesContent();
    if (content == null) {
      _log.severe('failed to get content of room aliases change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomAliasesYouChanged;
        } else {
          return lang.roomStateRoomAliasesOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomAliasesYouSet;
        } else {
          return lang.roomStateRoomAliasesOtherSet(senderName);
        }
    }
    return null;
  }

  String? getMessageOnRoomAvatar(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomAvatarContent();
    if (content == null) {
      _log.severe('failed to get content of room avatar change');
      return null;
    }
    switch (content.urlChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouChanged;
        } else {
          return lang.roomStateRoomAvatarUrlOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouSet;
        } else {
          return lang.roomStateRoomAvatarUrlOtherSet(senderName);
        }
      case 'Unset':
        if (isMe) {
          return lang.roomStateRoomAvatarUrlYouUnset;
        } else {
          return lang.roomStateRoomAvatarUrlOtherUnset(senderName);
        }
    }
    return null;
  }

  String? getMessageOnRoomCanonicalAlias(
    L10n lang,
    bool isMe,
    String senderName,
  ) {
    final content = eventItem.roomCanonicalAliasContent();
    if (content == null) {
      _log.severe('failed to get content of room canonical alias change');
      return null;
    }
    switch (content.aliasChange()) {
      case 'Changed':
        final newVal = content.aliasNewVal() ?? '';
        final oldVal = content.aliasOldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomCanonicalAliasYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomCanonicalAliasOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.aliasNewVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomCanonicalAliasYouSet(newVal);
        } else {
          return lang.roomStateRoomCanonicalAliasOtherSet(senderName, newVal);
        }
      case 'Unset':
        if (isMe) {
          return lang.roomStateRoomCanonicalAliasYouUnset;
        } else {
          return lang.roomStateRoomCanonicalAliasOtherUnset(senderName);
        }
    }
    switch (content.altAliasesChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomCanonicalAltAliasesYouChanged;
        } else {
          return lang.roomStateRoomCanonicalAltAliasesOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomCanonicalAltAliasesYouSet;
        } else {
          return lang.roomStateRoomCanonicalAltAliasesOtherSet(senderName);
        }
    }
    return null;
  }

  String getMessageOnRoomCreate(L10n lang, bool isMe, String senderName) {
    if (isMe) {
      return lang.roomStateRoomCreateYou;
    } else {
      return lang.roomStateRoomCreateOther(senderName);
    }
  }

  String? getMessageOnRoomEncryption(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomEncryptionContent();
    if (content == null) {
      _log.severe('failed to get content of room encryption change');
      return null;
    }
    switch (content.algorithmChange()) {
      case 'Changed':
        final newVal = content.algorithmNewVal();
        final oldVal = content.algorithmOldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomEncryptionAlgorithmYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomEncryptionAlgorithmOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.algorithmNewVal();
        if (isMe) {
          return lang.roomStateRoomEncryptionAlgorithmYouSet(newVal);
        } else {
          return lang.roomStateRoomEncryptionAlgorithmOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnRoomGuestAccess(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomGuestAccessContent();
    if (content == null) {
      _log.severe('failed to get content of room guest access change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomGuestAccessYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomGuestAccessOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomGuestAccessYouSet(newVal);
        } else {
          return lang.roomStateRoomGuestAccessOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnRoomHistoryVisibility(
    L10n lang,
    bool isMe,
    String senderName,
  ) {
    final content = eventItem.roomHistoryVisibilityContent();
    if (content == null) {
      _log.severe('failed to get content of room history visibility change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomHistoryVisibilityYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomHistoryVisibilityOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomHistoryVisibilityYouSet(newVal);
        } else {
          return lang.roomStateRoomHistoryVisibilityOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnRoomJoinRules(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomJoinRulesContent();
    if (content == null) {
      _log.severe('failed to get content of room join rules change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomJoinRulesYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomJoinRulesOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomJoinRulesYouSet(newVal);
        } else {
          return lang.roomStateRoomJoinRulesOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnRoomName(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomNameContent();
    if (content == null) {
      _log.severe('failed to get content of room name change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomNameYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomNameOtherChanged(senderName, oldVal, newVal);
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomNameYouSet(newVal);
        } else {
          return lang.roomStateRoomNameOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnRoomPinnedEvents(
    L10n lang,
    bool isMe,
    String senderName,
  ) {
    final content = eventItem.roomPinnedEventsContent();
    if (content == null) {
      _log.severe('failed to get content of room pinned events change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPinnedEventsYouChanged;
        } else {
          return lang.roomStateRoomPinnedEventsOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPinnedEventsYouSet;
        } else {
          return lang.roomStateRoomPinnedEventsOtherSet(senderName);
        }
    }
    return null;
  }

  String? getMessageOnRoomPowerLevels(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomPowerLevelsContent();
    if (content == null) {
      _log.severe('failed to get content of room power levels change');
      return null;
    }
    switch (content.banChange()) {
      case 'Changed':
        final newVal = content.banNewVal();
        final oldVal = content.banOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsBanYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomPowerLevelsBanOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.banNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsBanYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsBanOtherSet(senderName, newVal);
        }
    }
    switch (content.eventsChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouChanged;
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsYouSet;
        } else {
          return lang.roomStateRoomPowerLevelsEventsOtherSet(senderName);
        }
    }
    switch (content.eventsDefaultChange()) {
      case 'Changed':
        final newVal = content.eventsDefaultNewVal();
        final oldVal = content.eventsDefaultOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsDefaultYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomPowerLevelsEventsDefaultOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.eventsDefaultNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsEventsDefaultYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsEventsDefaultOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.inviteChange()) {
      case 'Changed':
        final newVal = content.inviteNewVal();
        final oldVal = content.inviteOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsInviteYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomPowerLevelsInviteOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.inviteNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsInviteYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsInviteOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.kickChange()) {
      case 'Changed':
        final newVal = content.kickNewVal();
        final oldVal = content.kickOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsKickYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomPowerLevelsKickOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.kickNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsKickYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsKickOtherSet(senderName, newVal);
        }
    }
    switch (content.notificationsChange()) {
      case 'Changed':
        final newVal = content.notificationsNewVal();
        final oldVal = content.notificationsOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsNotificationYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomPowerLevelsNotificationOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.notificationsNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsNotificationYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsNotificationOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.redactChange()) {
      case 'Changed':
        final newVal = content.redactNewVal();
        final oldVal = content.redactOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsRedactYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomPowerLevelsRedactOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.redactNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsRedactYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsRedactOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.stateDefaultChange()) {
      case 'Changed':
        final newVal = content.stateDefaultNewVal();
        final oldVal = content.stateDefaultOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsStateDefaultYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomPowerLevelsStateDefaultOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.stateDefaultNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsStateDefaultYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsStateDefaultOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.usersChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsUsersYouChanged;
        } else {
          return lang.roomStateRoomPowerLevelsUsersOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomPowerLevelsUsersYouSet;
        } else {
          return lang.roomStateRoomPowerLevelsUsersOtherSet(senderName);
        }
    }
    switch (content.usersDefaultChange()) {
      case 'Changed':
        final newVal = content.usersDefaultNewVal();
        final oldVal = content.usersDefaultOldVal() ?? -1;
        if (isMe) {
          return lang.roomStateRoomPowerLevelsUsersDefaultYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomPowerLevelsUsersDefaultOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.usersDefaultNewVal();
        if (isMe) {
          return lang.roomStateRoomPowerLevelsUsersDefaultYouSet(newVal);
        } else {
          return lang.roomStateRoomPowerLevelsUsersDefaultOtherSet(
            senderName,
            newVal,
          );
        }
    }
    return null;
  }

  String? getMessageOnRoomServerAcl(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomServerAclContent();
    if (content == null) {
      _log.severe('failed to get content of room server acl change');
      return null;
    }
    switch (content.allowIpLiteralsChange()) {
      case 'Changed':
        final newVal = content.allowIpLiteralsNewVal();
        final oldVal = content.allowIpLiteralsOldVal() ?? false;
        if (isMe) {
          return lang.roomStateRoomServerAclAllowIpLiteralsYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomServerAclAllowIpLiteralsOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.allowIpLiteralsNewVal();
        if (isMe) {
          return lang.roomStateRoomServerAclAllowIpLiteralsYouSet(newVal);
        } else {
          return lang.roomStateRoomServerAclAllowIpLiteralsOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.allowChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomServerAclAllowYouChanged;
        } else {
          return lang.roomStateRoomServerAclAllowOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomServerAclAllowYouSet;
        } else {
          return lang.roomStateRoomServerAclAllowOtherSet(senderName);
        }
    }
    switch (content.denyChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomServerAclDenyYouChanged;
        } else {
          return lang.roomStateRoomServerAclDenyOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomServerAclDenyYouSet;
        } else {
          return lang.roomStateRoomServerAclDenyOtherSet(senderName);
        }
    }
    return null;
  }

  String? getMessageOnRoomThirdPartyInvite(
    L10n lang,
    bool isMe,
    String senderName,
  ) {
    final content = eventItem.roomThirdPartyInviteContent();
    if (content == null) {
      _log.severe('failed to get content of room third party invite change');
      return null;
    }
    switch (content.displayNameChange()) {
      case 'Changed':
        final newVal = content.displayNameNewVal();
        final oldVal = content.displayNameOldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomThirdPartyInviteDisplayNameYouChanged(
            oldVal,
            newVal,
          );
        } else {
          return lang.roomStateRoomThirdPartyInviteDisplayNameOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.displayNameNewVal();
        if (isMe) {
          return lang.roomStateRoomThirdPartyInviteDisplayNameYouSet(newVal);
        } else {
          return lang.roomStateRoomThirdPartyInviteDisplayNameOtherSet(
            senderName,
            newVal,
          );
        }
    }
    switch (content.keyValidityUrlChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomThirdPartyInviteKeyValidityUrlYouChanged;
        } else {
          return lang.roomStateRoomThirdPartyInviteKeyValidityUrlOtherChanged(
            senderName,
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomThirdPartyInviteKeyValidityUrlYouSet;
        } else {
          return lang.roomStateRoomThirdPartyInviteKeyValidityUrlOtherSet(
            senderName,
          );
        }
    }
    switch (content.publicKeyChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomThirdPartyInvitePublicKeyYouChanged;
        } else {
          return lang.roomStateRoomThirdPartyInvitePublicKeyOtherChanged(
            senderName,
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomThirdPartyInvitePublicKeyYouSet;
        } else {
          return lang.roomStateRoomThirdPartyInvitePublicKeyOtherSet(
            senderName,
          );
        }
    }
    return null;
  }

  String? getMessageOnRoomTombstone(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomTombstoneContent();
    if (content == null) {
      _log.severe('failed to get content of room tombstone change');
      return null;
    }
    switch (content.bodyChange()) {
      case 'Changed':
        final newVal = content.bodyNewVal();
        final oldVal = content.bodyOldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomTombstoneBodyYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomTombstoneBodyOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.bodyNewVal();
        if (isMe) {
          return lang.roomStateRoomTombstoneBodyYouSet(newVal);
        } else {
          return lang.roomStateRoomTombstoneBodyOtherSet(senderName, newVal);
        }
    }
    switch (content.replacementRoomChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateRoomTombstoneReplacementRoomYouChanged;
        } else {
          return lang.roomStateRoomTombstoneReplacementRoomOtherChanged(
            senderName,
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateRoomTombstoneReplacementRoomYouSet;
        } else {
          return lang.roomStateRoomTombstoneReplacementRoomOtherSet(senderName);
        }
    }
    return null;
  }

  String? getMessageOnRoomTopic(L10n lang, bool isMe, String senderName) {
    final content = eventItem.roomTopicContent();
    if (content == null) {
      _log.severe('failed to get content of room topic change');
      return null;
    }
    switch (content.change()) {
      case 'Changed':
        final newVal = content.newVal();
        final oldVal = content.oldVal() ?? '';
        if (isMe) {
          return lang.roomStateRoomTopicYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateRoomTopicOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.newVal();
        if (isMe) {
          return lang.roomStateRoomTopicYouSet(newVal);
        } else {
          return lang.roomStateRoomTopicOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnSpaceChild(L10n lang, bool isMe, String senderName) {
    final content = eventItem.spaceChildContent();
    if (content == null) {
      _log.severe('failed to get content of space child change');
      return null;
    }
    switch (content.viaChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateSpaceChildViaYouChanged;
        } else {
          return lang.roomStateSpaceChildViaOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateSpaceChildViaYouSet;
        } else {
          return lang.roomStateSpaceChildViaOtherSet(senderName);
        }
    }
    switch (content.orderChange()) {
      case 'Changed':
        final newVal = content.orderNewVal() ?? '';
        final oldVal = content.orderOldVal() ?? '';
        if (isMe) {
          return lang.roomStateSpaceChildOrderYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateSpaceChildOrderOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.orderNewVal() ?? '';
        if (isMe) {
          return lang.roomStateSpaceChildOrderYouSet(newVal);
        } else {
          return lang.roomStateSpaceChildOrderOtherSet(senderName, newVal);
        }
      case 'Unset':
        if (isMe) {
          return lang.roomStateSpaceChildOrderYouUnset;
        } else {
          return lang.roomStateSpaceChildOrderOtherUnset(senderName);
        }
    }
    switch (content.suggestedChange()) {
      case 'Changed':
        final newVal = content.suggestedNewVal();
        final oldVal = content.suggestedOldVal() ?? false;
        if (isMe) {
          return lang.roomStateSpaceChildSuggestedYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateSpaceChildSuggestedOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        final newVal = content.suggestedNewVal();
        if (isMe) {
          return lang.roomStateSpaceChildSuggestedYouSet(newVal);
        } else {
          return lang.roomStateSpaceChildSuggestedOtherSet(senderName, newVal);
        }
    }
    return null;
  }

  String? getMessageOnSpaceParent(L10n lang, bool isMe, String senderName) {
    final content = eventItem.spaceParentContent();
    if (content == null) {
      _log.severe('failed to get content of space parent change');
      return null;
    }
    switch (content.viaChange()) {
      case 'Changed':
        if (isMe) {
          return lang.roomStateSpaceParentViaYouChanged;
        } else {
          return lang.roomStateSpaceParentViaOtherChanged(senderName);
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateSpaceParentViaYouSet;
        } else {
          return lang.roomStateSpaceParentViaOtherSet(senderName);
        }
    }
    switch (content.canonicalChange()) {
      case 'Changed':
        final newVal = content.canonicalNewVal();
        final oldVal = content.canonicalOldVal() ?? false;
        if (isMe) {
          return lang.roomStateSpaceParentCanonicalYouChanged(oldVal, newVal);
        } else {
          return lang.roomStateSpaceParentCanonicalOtherChanged(
            senderName,
            oldVal,
            newVal,
          );
        }
      case 'Set':
        if (isMe) {
          return lang.roomStateSpaceParentViaYouSet;
        } else {
          return lang.roomStateSpaceParentViaOtherSet(senderName);
        }
    }
    return null;
  }
}
