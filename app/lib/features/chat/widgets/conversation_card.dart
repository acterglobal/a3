import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/utils/utils.dart';
// import 'package:acter/features/chat/providers/notifiers/receipt_notifier.dart';
import 'package:acter/features/chat/pages/room_page.dart';
import 'package:acter/features/chat/models/joined_room/joined_room.dart';
// import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

class ConversationCard extends ConsumerStatefulWidget {
  final JoinedRoom room;

  const ConversationCard({
    Key? key,
    required this.room,
  }) : super(key: key);

  @override
  ConsumerState<ConversationCard> createState() => _ConversationCardState();
}

class _ConversationCardState extends ConsumerState<ConversationCard> {
  // final ReceiptController recieptController = Get.find<ReceiptController>();

  List<Member> activeMembers = [];

  @override
  void initState() {
    super.initState();
    getActiveMembers();
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(clientProvider)!;
    String roomId = widget.room.id;
    final convoProfile =
        ref.watch(chatProfileDataProvider(widget.room.conversation));
    // ToDo: UnreadCounter
    return convoProfile.when(
      data: (data) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              onTap: () => handleTap(context),
              leading: ActerAvatar(
                mode: DisplayMode.GroupChat, // FIXME: checking for DM somehow?
                uniqueId: roomId,
                displayName: data.displayName ?? roomId,
                avatar: data.getAvatarImage(),
                size: 36,
              ),
              title: Text(
                data.displayName ?? roomId,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(fontWeight: FontWeight.w700),
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: _SubtitleWidget(
                typingUsers: widget.room.typingUsers,
                latestMessage: widget.room.latestMessage,
              ),
              trailing: _TrailingWidget(
                // controller: recieptController,
                room: widget.room.conversation,
                latestMessage: widget.room.latestMessage,
                activeMembers: activeMembers,
                userId: client.userId().toString(),
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

  void handleTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomPage(
          conversation: widget.room.conversation,
          name: widget.room.displayName,
        ),
      ),
    );
  }

  Future<void> getActiveMembers() async {
    activeMembers = (await widget.room.conversation.activeMembers()).toList();
  }
}

class _SubtitleWidget extends ConsumerWidget {
  const _SubtitleWidget({
    required this.typingUsers,
    required this.latestMessage,
  });
  final List<types.User> typingUsers;
  final RoomMessage? latestMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (typingUsers.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          getUserPlural(typingUsers),
          style: Theme.of(context).textTheme.labelLarge,
        ),
      );
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
  const _TrailingWidget({
    required this.room,
    required this.activeMembers,
    this.latestMessage,
    required this.userId,
  });
  final Conversation room;
  final List<Member> activeMembers;
  final RoomMessage? latestMessage;
  final String? userId;

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
//   const _CustomStatusWidget({
//     required this.status,
//   });

//   final types.Status status;

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
//           child: CircularProgressIndicator(
//             strokeWidth: 1.5,
//           ),
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
