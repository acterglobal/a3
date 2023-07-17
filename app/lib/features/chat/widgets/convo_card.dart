import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
// import 'package:acter/features/chat/providers/chat_providers.dart';
// import 'package:acter/features/chat/providers/notifiers/receipt_notifier.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ConvoCard extends ConsumerStatefulWidget {
  final Convo room;

  const ConvoCard({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  ConsumerState<ConvoCard> createState() => _ConvoCardState();
}

class _ConvoCardState extends ConsumerState<ConvoCard> {
  // final ReceiptController recieptController = Get.find<ReceiptController>();
  List<Member> activeMembers = [];

  @override
  void initState() {
    super.initState();
    getActiveMembers();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientProvider);
    String roomId = widget.room.getRoomIdStr();
    final convoProfile = ref.watch(chatProfileDataProvider(widget.room));
    // ToDo: UnreadCounter
    return convoProfile.when(
      data: (profile) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              onTap: () => context.goNamed(
                Routes.chatroom.name,
                pathParameters: {'roomId': roomId},
                extra: widget.room,
              ),
              leading: profile.hasAvatar()
                  ? ActerAvatar(
                      uniqueId: roomId,
                      mode: DisplayMode.GroupChat,
                      displayName: profile.displayName ?? roomId,
                      avatar: profile.getAvatarImage(),
                      size: 36,
                    )
                  : Container(
                      height: 36,
                      width: 36,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSecondary,
                        borderRadius: BorderRadius.circular(6),
                        shape: BoxShape.rectangle,
                      ),
                      child: SvgPicture.asset(
                        'assets/icon/acter.svg',
                      ),
                    ),
              title: Text(
                profile.displayName ?? roomId,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontWeight: FontWeight.w700),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: _SubtitleWidget(
                room: widget.room,
                latestMessage: widget.room.latestMessage(),
              ),
              trailing: _TrailingWidget(
                // controller: recieptController,
                room: widget.room,
                latestMessage: widget.room.latestMessage(),
                activeMembers: activeMembers,
                userId: client!.userId().toString(),
              ),
            ),
            Divider(
              indent: 75,
              endIndent: 10,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ],
        );
      },
      error: (error, stackTrace) => const Text('Failed to load Conversation'),
      loading: () => const CircularProgressIndicator(),
    );
  }

  Future<void> getActiveMembers() async {
    activeMembers = (await widget.room.activeMembers()).toList();
  }
}

class _SubtitleWidget extends ConsumerWidget {
  const _SubtitleWidget({
    required this.room,
    required this.latestMessage,
  });
  final Convo room;
  final RoomMessage? latestMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingEvent = ref.watch(typingProvider);
    debugPrint('$typingEvent');
    if (typingEvent.isNotEmpty) {
      debugPrint('$typingEvent');
      if (typingEvent['roomId'] == room.getRoomIdStr()) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            getUserPlural(typingEvent['typingUsers']),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        );
      }
    }
    if (latestMessage == null) {
      return const SizedBox.shrink();
    }
    RoomEventItem? eventItem = latestMessage!.eventItem();
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
      case 'm.room.canonical.alias':
      case 'm.room.create':
      case 'm.room.encryption':
      case 'm.room.guest.access':
      case 'm.room.history.visibility':
      case 'm.room.join.rules':
      case 'm.room.name':
      case 'm.room.pinned.events':
      case 'm.room.power.levels':
      case 'm.room.server.acl':
      case 'm.room.third.party.invite':
      case 'm.room.tombstone':
      case 'm.room.topic':
      case 'm.space.child':
      case 'm.space.parent':
      case 'm.key.verification.accept':
      case 'm.key.verification.cancel':
      case 'm.key.verification.done':
      case 'm.key.verification.key':
      case 'm.key.verification.mac':
      case 'm.key.verification.ready':
      case 'm.key.verification.start':
      case 'm.room.message':
        String? subType = eventItem.subType();
        switch (subType) {
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
            TextDesc? textDesc = eventItem.textDesc();
            if (textDesc == null) {
              return const SizedBox.shrink();
            }
            String body = textDesc.body();
            String? formattedBody = textDesc.formattedBody();
            if (formattedBody != null) {
              body = simplifyBody(formattedBody);
            }
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    '${simplifyUserId(sender)}: ',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(fontWeight: FontWeight.w700),
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
        return const SizedBox.shrink();
      case 'm.reaction':
        TextDesc? textDesc = eventItem.textDesc();
        if (textDesc == null) {
          return const SizedBox();
        }
        String body = textDesc.body();
        String? formattedBody = textDesc.formattedBody();
        if (formattedBody != null) {
          body = simplifyBody(formattedBody);
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontWeight: FontWeight.w700),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              eventItem.textDesc()!.body(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      case 'm.room.redaction':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: Text(
                '***This message has been deleted***',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      case 'm.room.encrypted':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: Text(
                '***Failed to decrypt message. Re-request session keys***',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      case 'm.room.member':
        TextDesc? textDesc = eventItem.textDesc();
        if (textDesc == null) {
          return const SizedBox();
        }
        String body = textDesc.body();
        String? formattedBody = textDesc.formattedBody();
        if (formattedBody != null) {
          body = simplifyBody(formattedBody);
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '${simplifyUserId(sender)}: ',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(fontWeight: FontWeight.w700),
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
    }
    return const SizedBox.shrink();
  }

  String getUserPlural(List<types.User> authors) {
    if (authors.isEmpty) {
      return '';
    } else if (authors.length == 1) {
      return '${authors[0].firstName} is typing...';
    } else if (authors.length == 2) {
      return '${authors[0].firstName} and ${authors[1].firstName} is typing...';
    } else {
      return '${authors[0].firstName} and ${authors.length - 1} others typing...';
    }
  }
}

class _TrailingWidget extends ConsumerWidget {
  final Convo room;
  final List<Member> activeMembers;
  final RoomMessage? latestMessage;
  final String? userId;

  const _TrailingWidget({
    required this.room,
    required this.activeMembers,
    this.latestMessage,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (latestMessage == null) {
      return const SizedBox.shrink();
    }
    RoomEventItem? eventItem = latestMessage!.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }
    // String senderID = '';
    // types.Status? messageStatus;
    int ts = eventItem.originServerTs();

    // List<String> seenByList = ref.read(receiptProvider.notifier).getSeenByList(
    //       room.getRoomId(),
    //       ts,
    //     );

    // senderID = latestMessage!.eventItem()!.sender();

    // messageStatus = seenByList.isEmpty
    //     ? types.Status.sent
    //     : seenByList.length < activeMembers.length
    //         ? types.Status.delivered
    //         : types.Status.seen;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          DateFormat.Hm().format(
            DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true),
          ),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        // senderID == userId
        //     ? _CustomStatusWidget(status: messageStatus)
        //     : const SizedBox.shrink(),
      ],
    );
  }
}

// class _CustomStatusWidget extends StatelessWidget {
//   final types.Status status;

//   const _CustomStatusWidget({
//     required this.status,
//   });

//   @override
//   Widget build(BuildContext context) {
//     if (status == types.Status.delivered) {
//       return SvgPicture.asset('assets/images/deliveredIcon.svg');
//     } else if (status == types.Status.seen) {
//       return SvgPicture.asset('assets/images/seenIcon.svg');
//     } else if (status == types.Status.sending) {
//       return const Center(
//         child: SizedBox(
//           height: 10,
//           width: 10,
//           child: CircularProgressIndicator(strokeWidth: 1.5),
//         ),
//       );
//     } else {
//       return SvgPicture.asset(
//         'assets/images/sentIcon.svg',
//         width: 12,
//         height: 12,
//       );
//     }
//   }
// }
