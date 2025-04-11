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
    final myId = ref.read(myUserIdStrProvider);
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
    switch (content.change()) {
      case 'joined':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildJoinedEventMessage(context, myId, userId, userName),
            ),
          ],
        );
      case 'left':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildLeftEventMessage(context, myId, userId, userName),
            ),
          ],
        );
      case 'banned':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildBannedEventMessage(
                context,
                myId,
                senderId,
                senderName,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'unbanned':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildUnbannedEventMessage(
                context,
                myId,
                senderId,
                senderName,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'kicked':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildKickedEventMessage(
                context,
                myId,
                senderId,
                senderName,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'invited':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildInvitedEventMessage(
                context,
                myId,
                senderId,
                senderName,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'kickedAndBanned':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildKickedAndBannedEventMessage(
                context,
                myId,
                senderId,
                senderName,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'invitationAccepted':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildInvitationAcceptedEventMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'invitationRejected':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildInvitationRejectedEventMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'invitationRevoked':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildInvitationRevokedEventMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'knocked':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildKnockedEventMessage(
                context,
                myId,
                senderId,
                senderName,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'knockAccepted':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildKnockAcceptedEventMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'knockRetracted':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildKnockRetractedEventMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'knockDenied':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildKnockDeniedEventMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
    }
    return const SizedBox.shrink();
  }

  Widget buildJoinedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatMembershipYouJoined,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipOtherJoined(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildLeftEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatMembershipYouLeft,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipOtherLeft(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildBannedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (senderId == myId) {
      return Text(
        lang.chatMembershipYouBannedOther(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else if (userId == myId) {
      return Text(
        lang.chatMembershipOtherBannedYou(senderName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipOtherBannedOther(senderName, userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildUnbannedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (senderId == myId) {
      return Text(
        lang.chatMembershipYouUnbannedOther(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else if (userId == myId) {
      return Text(
        lang.chatMembershipOtherUnbannedYou(senderName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipOtherUnbannedOther(senderName, userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildKickedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (senderId == myId) {
      return Text(
        lang.chatMembershipYouKickedOther(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else if (userId == myId) {
      return Text(
        lang.chatMembershipOtherKickedYou(senderName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipOtherKickedOther(senderName, userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildInvitedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (senderId == myId) {
      return Text(
        lang.chatMembershipYouInvitedOther(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else if (userId == myId) {
      return Text(
        lang.chatMembershipOtherInvitedYou(senderName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipOtherInvitedOther(senderName, userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildKickedAndBannedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (senderId == myId) {
      return Text(
        lang.chatMembershipYouKickedAndBannedOther(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else if (userId == myId) {
      return Text(
        lang.chatMembershipOtherKickedAndBannedYou(senderName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipOtherKickedAndBannedOther(senderName, userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildInvitationAcceptedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatMembershipInvitationYouAccepted,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipInvitationOtherAccepted(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildInvitationRejectedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatMembershipInvitationYouRejected,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipInvitationOtherRejected(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildInvitationRevokedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatMembershipInvitationYouRevoked,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipInvitationOtherRevoked(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildKnockedEventMessage(
    BuildContext context,
    String myId,
    String senderId,
    String senderName,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (senderId == myId) {
      return Text(
        lang.chatMembershipYouKnockedOther(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else if (userId == myId) {
      return Text(
        lang.chatMembershipOtherKnockedYou(senderName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipOtherKnockedOther(senderName, userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildKnockAcceptedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatMembershipKnockYouAccepted,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipKnockOtherAccepted(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildKnockRetractedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatMembershipKnockYouRetracted,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipKnockOtherRetracted(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildKnockDeniedEventMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatMembershipKnockYouDenied,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatMembershipKnockOtherDenied(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }
}

class _ProfileUpdateWidget extends ConsumerWidget {
  final String roomId;
  final TimelineEventItem eventItem;

  const _ProfileUpdateWidget({required this.roomId, required this.eventItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.read(myUserIdStrProvider);
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
    switch (content.displayNameChange()) {
      case 'Changed':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildDisplayNameChangedMessage(
                context,
                myId,
                userId,
                content.displayNameNewVal() ?? '',
                content.displayNameOldVal() ?? '',
              ),
            ),
          ],
        );
      case 'Set':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildDisplayNameSetMessage(
                context,
                myId,
                userId,
                content.displayNameNewVal() ?? '',
              ),
            ),
          ],
        );
      case 'Unset':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildDisplayNameUnsetMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
    }
    switch (content.avatarUrlChange()) {
      case 'Changed':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildAvatarUrlChangedMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
      case 'Set':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildAvatarUrlSetMessage(context, myId, userId, userName),
            ),
          ],
        );
      case 'Unset':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: buildAvatarUrlUnsetMessage(
                context,
                myId,
                userId,
                userName,
              ),
            ),
          ],
        );
    }
    return const SizedBox.shrink();
  }

  Widget buildDisplayNameChangedMessage(
    BuildContext context,
    String myId,
    String userId,
    String newVal,
    String oldVal,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatProfileDisplayNameYouChanged(newVal),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatProfileDisplayNameOtherChanged(oldVal, newVal),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildDisplayNameSetMessage(
    BuildContext context,
    String myId,
    String userId,
    String newVal,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatProfileDisplayNameYouSet(newVal),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatProfileDisplayNameOtherSet(userId, newVal),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildDisplayNameUnsetMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatProfileDisplayNameYouUnset,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatProfileDisplayNameOtherUnset(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildAvatarUrlChangedMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatProfileAvatarUrlYouChanged,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatProfileAvatarUrlOtherChanged(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildAvatarUrlSetMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatProfileAvatarUrlYouSet,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatProfileAvatarUrlOtherSet(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget buildAvatarUrlUnsetMessage(
    BuildContext context,
    String myId,
    String userId,
    String userName,
  ) {
    final lang = L10n.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (userId == myId) {
      return Text(
        lang.chatProfileAvatarUrlYouUnset,
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    } else {
      return Text(
        lang.chatProfileAvatarUrlOtherUnset(userName),
        maxLines: 1,
        style: textTheme.labelMedium?.copyWith(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      );
    }
  }
}
