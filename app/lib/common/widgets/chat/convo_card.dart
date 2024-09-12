import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/chat/convo_with_avatar_card.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:extension_nullable/extension_nullable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::common::chat::convo_card');

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
    final titleIsLoading = !ref.watch(roomDisplayNameProvider(roomId)).hasValue;
    final roomAvatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    // ToDo: UnreadCounter
    return ConvoWithAvatarInfoCard(
      animation: animation,
      roomId: roomId,
      showParents: showParents,
      showSuggestedMark: showSuggestedMark,
      avatarInfo: roomAvatarInfo,
      onTap: onTap,
      title: titleIsLoading ? Skeletonizer(child: Text(roomId)) : null,
      showSelectedIndication: showSelectedIndication,
      subtitle: _SubtitleWidget(
        roomId: roomId,
      ),
      trailing: trailing ?? renderTrailing(context, ref),
    );
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
    final room = await ref.read(maybeRoomProvider(roomId).future);
    if (room == null) {
      _log.severe('Room not found: $roomId');
      if (!context.mounted) return;
      EasyLoading.showError(
        L10n.of(context).roomNotFound,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    await room.unmute();
    if (!context.mounted) return;
    EasyLoading.showToast(L10n.of(context).notificationsUnmuted);
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

    RoomEventItem? eventItem = latestMessage?.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }

    String sender = eventItem.sender();
    String eventType = eventItem.eventType();
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
      case 'm.room.guest.access':
      case 'm.room.history_visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned_events':
      case 'm.room.power_levels':
      case 'm.room.server_acl':
      case 'm.room.third_party_invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent == null) {
          return const SizedBox();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                msgContent.body(),
                style: Theme.of(context).textTheme.labelMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
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
            MsgContent? msgContent = eventItem.msgContent();
            if (msgContent == null) {
              return const SizedBox.shrink();
            }
            String body =
                msgContent.formattedBody().map((p0) => simplifyBody(p0)) ??
                    msgContent.body();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    '${simplifyUserId(sender)}: ',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium!
                        .copyWith(fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Flexible(
                  child: Html(
                    // ignore: unnecessary_string_interpolations
                    data: '''$body''',
                    maxLines: 1,
                    defaultTextStyle:
                        Theme.of(context).textTheme.labelMedium!.copyWith(
                              overflow: TextOverflow.ellipsis,
                            ),
                    onLinkTap: (url) => {},
                  ),
                ),
              ],
            );
        }
      case 'm.reaction':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent == null) {
          return const SizedBox();
        }
        String body =
            msgContent.formattedBody().map((p0) => simplifyBody(p0)) ??
                msgContent.body();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Html(
                // ignore: unnecessary_string_interpolations
                data: '''$body''',
                maxLines: 1,
                defaultTextStyle:
                    Theme.of(context).textTheme.labelMedium!.copyWith(
                          overflow: TextOverflow.ellipsis,
                        ),
                onLinkTap: (url) => {},
              ),
            ),
          ],
        );
      case 'm.sticker':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent == null) {
          return const SizedBox();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                msgContent.body(),
                style: Theme.of(context).textTheme.labelMedium,
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
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                L10n.of(context).thisMessageHasBeenDeleted,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
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
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                L10n.of(context).failedToDecryptMessage,
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case 'm.room.member':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent == null) {
          return const SizedBox();
        }
        String body =
            msgContent.formattedBody().map((p0) => simplifyBody(p0)) ??
                msgContent.body();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)} ',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Html(
                // ignore: unnecessary_string_interpolations
                data: '''$body''',
                maxLines: 1,
                defaultTextStyle:
                    Theme.of(context).textTheme.labelMedium!.copyWith(
                          overflow: TextOverflow.ellipsis,
                        ),
                onLinkTap: (url) => {},
              ),
            ),
          ],
        );
      case 'm.poll.start':
        MsgContent? msgContent = eventItem.msgContent();
        if (msgContent == null) {
          return const SizedBox();
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium!
                    .copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                msgContent.body(),
                style: Theme.of(context).textTheme.labelMedium,
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
    final textStyle = Theme.of(context).textTheme.bodySmall!;
    if (users.length == 1) {
      final user1 = simplifyUserId(users[0].id)!;
      return Text(
        L10n.of(context).typingUser1(user1),
        style: textStyle,
      );
    }
    if (users.length == 2) {
      final user1 = simplifyUserId(users[0].id)!;
      final user2 = simplifyUserId(users[1].id)!;
      return Text(
        L10n.of(context).typingUser2(user1, user2),
        style: textStyle,
      );
    }
    final user1 = simplifyUserId(users[0].id)!;
    return Text(
      L10n.of(context).typingUser3(user1, {users.length - 1}),
      style: textStyle,
    );
  }
}

class _TrailingWidget extends ConsumerWidget {
  final String roomId;

  const _TrailingWidget({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestMessage = ref.watch(latestMessageProvider(roomId)).valueOrNull;
    RoomEventItem? eventItem = latestMessage?.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }

    return Text(
      jiffyTime(context, eventItem.originServerTs()),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
