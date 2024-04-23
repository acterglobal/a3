import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/chat/convo_with_profile_card.dart';
import 'package:acter/common/widgets/chat/loading_convo_card.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class ConvoCard extends ConsumerStatefulWidget {
  final Convo room;

  final Function()? onTap;

  /// Whether or not to render the parent Icon
  ///
  final bool showParent;

  /// Custom Trailing Widget
  final Widget? trailing;

  const ConvoCard({
    super.key,
    required this.room,
    this.onTap,
    this.showParent = true,
    this.trailing,
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
    final convoProfile = ref.watch(chatProfileDataProvider(widget.room));
    final latestMsg = ref.watch(latestMessageProvider(widget.room));
    // ToDo: UnreadCounter
    return convoProfile.when(
      data: (profile) => ConvoWithProfileCard(
        roomId: roomId,
        showParent: widget.showParent,
        profile: profile,
        onTap: widget.onTap,
        subtitle: latestMsg != null
            ? _SubtitleWidget(
                room: widget.room,
                latestMessage: latestMsg,
              )
            : const SizedBox.shrink(),
        trailing: widget.trailing ?? renderTrailing(context),
      ),
      error: (error, stackTrace) => LoadingConvoCard(
        roomId: roomId,
        subtitle: Text(L10n.of(context).failedToLoadConversation(error)),
      ),
      loading: () => LoadingConvoCard(
        roomId: roomId,
      ),
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
    await Future.delayed(const Duration(seconds: 1), () {
      // FIXME: we want to refresh the view but don't know
      //        when the event was confirmed form sync :(
      // let's hope that a second delay is reasonable enough
      ref.invalidate(maybeRoomProvider(roomId));
    });
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
    final userAppSettings = ref.watch(userAppSettingsProvider);
    final myUserId = ref.watch(myUserIdStrProvider);
    if (userAppSettings.valueOrNull != null) {
      final settings = userAppSettings.requireValue;
      if (settings.typingNotice() != false) {
        // start listening typing events
        final typingEvent = ref.watch(chatTypingEventProvider);
        if (typingEvent.valueOrNull != null) {
          final t = typingEvent.requireValue;
          if (t != null) {
            if (t.roomId().toString() == room.getRoomIdStr()) {
              var userIds = t.userIds().toList();
              userIds.removeWhere((id) => id.toString() == myUserId);
              if (userIds.isNotEmpty) {
                return renderTypingState(context, userIds, ref);
              }
            }
          }
        }
      }
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      '${simplifyUserId(sender)}: ',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Flexible(
                  child: Html(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    // ignore: unnecessary_string_interpolations
                    data: '''$body''',
                    maxLines: 1,
                    defaultTextStyle: const TextStyle(
                      overflow: TextOverflow.ellipsis,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${simplifyUserId(sender)}: ',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Flexible(
              child: Html(
                padding: const EdgeInsets.symmetric(vertical: 10),
                // ignore: unnecessary_string_interpolations
                data: '''$body''',
                maxLines: 1,
                defaultTextStyle: const TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontSize: 14,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${simplifyUserId(sender)}: ',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Flexible(
              child: Text(
                eventItem.msgContent()!.body(),
                style: Theme.of(context).textTheme.bodySmall,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${simplifyUserId(sender)}: ',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Flexible(
              child: Text(
                L10n.of(context).thisMessageHasBeenDeleted,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.neutral5,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${simplifyUserId(sender)}: ',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              child: Text(
                L10n.of(context).failedToDecryptMessage,
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                      color: Theme.of(context).colorScheme.neutral5,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${simplifyUserId(sender)} ',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Flexible(
              child: Html(
                padding: const EdgeInsets.symmetric(vertical: 10),
                // ignore: unnecessary_string_interpolations
                data: '''$body''',
                maxLines: 1,
                defaultTextStyle: const TextStyle(
                  overflow: TextOverflow.ellipsis,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${simplifyUserId(sender)}: ',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Flexible(
              child: Text(
                eventItem.msgContent()!.body(),
                style: Theme.of(context).textTheme.bodySmall,
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
    List<UserId> userIds,
    WidgetRef ref,
  ) {
    final textStyle = Theme.of(context).textTheme.bodySmall!;
    if (userIds.length == 1) {
      final userName = simplifyUserId(userIds[0].toString());
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(L10n.of(context).typingUser1(userName!), style: textStyle),
      );
    } else if (userIds.length == 2) {
      final u1 = simplifyUserId(userIds[0].toString());
      final u2 = simplifyUserId(userIds[1].toString());
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          L10n.of(context).typingUser2(u1!, u2!),
          style: textStyle,
        ),
      );
    } else {
      final u1 = simplifyUserId(userIds[0].toString());
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          L10n.of(context).typingUser3(u1!, {userIds.length - 1}),
          style: textStyle,
        ),
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
