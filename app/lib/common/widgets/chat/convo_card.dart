import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/chat/convo_with_avatar_card.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ConvoCard extends ConsumerStatefulWidget {
  final Convo room;

  final Function()? onTap;

  /// Whether or not to render the parents Icon
  final bool showParents;

  /// Custom Trailing Widget
  final Widget? trailing;
  final bool showSelectedIndication;
  final bool showSuggestedMark;

  const ConvoCard({
    super.key,
    required this.room,
    this.onTap,
    this.showParents = true,
    this.trailing,
    this.showSelectedIndication = true,
    this.showSuggestedMark = false,
  });

  @override
  ConsumerState<ConvoCard> createState() => _ConvoCardState();
}

class _ConvoCardState extends ConsumerState<ConvoCard> {
  List<Member> activeMembers = [];

  @override
  void initState() {
    super.initState();
    getActiveMembers();
  }

  @override
  Widget build(BuildContext context) {
    String roomId = widget.room.getRoomIdStr();
    final roomAvatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    final latestMsg = ref.watch(latestMessageProvider(widget.room));
    // ToDo: UnreadCounter
    return ConvoWithAvatarInfoCard(
      roomId: roomId,
      showParents: widget.showParents,
      showSuggestedMark: widget.showSuggestedMark,
      avatarInfo: roomAvatarInfo,
      onTap: widget.onTap,
      showSelectedIndication: widget.showSelectedIndication,
      subtitle: latestMsg != null
          ? _SubtitleWidget(
              room: widget.room,
              latestMessage: latestMsg,
            )
          : const SizedBox.shrink(),
      trailing: widget.trailing ?? renderTrailing(context),
    );
  }

  Widget renderTrailing(BuildContext context) {
    String roomId = widget.room.getRoomIdStr();
    final userId = ref.watch(myUserIdStrProvider);
    final mutedStatus = ref.watch(roomIsMutedProvider(roomId));
    final latestMsg = ref.watch(latestMessageProvider(widget.room));
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (latestMsg != null)
          _TrailingWidget(
            room: widget.room,
            latestMessage: latestMsg,
            activeMembers: activeMembers,
            userId: userId,
          ),
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
                  onPressed: onUnmute,
                  child: Text(L10n.of(context).unmute),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> getActiveMembers() async {
    activeMembers = (await widget.room.activeMembers()).toList();
  }

  Future<void> onUnmute() async {
    String roomId = widget.room.getRoomIdStr();
    final room = await ref.read(maybeRoomProvider(roomId).future);
    if (room == null) {
      if (!mounted) return;
      EasyLoading.showError(
        L10n.of(context).roomNotFound,
        duration: const Duration(seconds: 3),
      );
      return;
    }
    await room.unmute();
    if (!mounted) return;
    EasyLoading.showToast(L10n.of(context).notificationsUnmuted);
  }
}

class _SubtitleWidget extends ConsumerWidget {
  final Convo room;
  final RoomMessage latestMessage;

  const _SubtitleWidget({
    required this.room,
    required this.latestMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userIds =
        ref.watch(chatTypingEventProvider(room.getRoomIdStr())).valueOrNull;
    if (userIds != null && userIds.isNotEmpty) {
      return renderTypingState(context, userIds, ref);
    }

    RoomEventItem? eventItem = latestMessage.eventItem();
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
                eventItem.msgContent()!.body(),
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
                eventItem.msgContent()!.body(),
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
    List<User> userIds,
    WidgetRef ref,
  ) {
    final textStyle = Theme.of(context).textTheme.bodySmall!;
    if (userIds.length == 1) {
      final userName = simplifyUserId(userIds[0].id.toString());
      return Text(L10n.of(context).typingUser1(userName!), style: textStyle);
    } else if (userIds.length == 2) {
      final u1 = simplifyUserId(userIds[0].id.toString());
      final u2 = simplifyUserId(userIds[1].id.toString());
      return Text(
        L10n.of(context).typingUser2(u1!, u2!),
        style: textStyle,
      );
    } else {
      final u1 = simplifyUserId(userIds[0].id.toString());
      return Text(
        L10n.of(context).typingUser3(u1!, {userIds.length - 1}),
        style: textStyle,
      );
    }
  }
}

class _TrailingWidget extends ConsumerWidget {
  final Convo room;
  final List<Member> activeMembers;
  final RoomMessage latestMessage;
  final String? userId;

  const _TrailingWidget({
    required this.room,
    required this.activeMembers,
    required this.latestMessage,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    RoomEventItem? eventItem = latestMessage.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }

    return Text(
      jiffyTime(latestMessage.eventItem()!.originServerTs()),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}
