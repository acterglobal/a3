import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/chat/convo_with_profile_card.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConvoCard extends ConsumerStatefulWidget {
  final Convo room;

  /// Whether or not to render the parent Icon
  ///
  final bool showParent;

  const ConvoCard({
    Key? key,
    required this.room,
    this.showParent = true,
  }) : super(key: key);

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
    final client = ref.watch(clientProvider);
    String roomId = widget.room.getRoomIdStr();
    final convoProfile = ref.watch(chatProfileDataProvider(widget.room));
    // ToDo: UnreadCounter
    return convoProfile.when(
      data: (profile) => ConvoWithProfileCard(
        roomId: roomId,
        showParent: widget.showParent,
        profile: profile,
        onTap: () async {
          ref
              .read(currentConvoProvider.notifier)
              .update((state) => widget.room);
          ref.invalidate(chatRoomProvider);
          ref.invalidate(messagesProvider);
          if (!isDesktop(context)) {
            context.pushNamed(
              Routes.chatroom.name,
              pathParameters: {'roomId': roomId},
            );
          }
        },
        subtitle: _SubtitleWidget(
          latestMessage: widget.room.latestMessage(),
        ),
        trailing: _TrailingWidget(
          room: widget.room,
          latestMessage: widget.room.latestMessage(),
          activeMembers: activeMembers,
          userId: client!.userId().toString(),
        ),
      ),
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
    required this.latestMessage,
  });
  final RoomMessage? latestMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (latestMessage == null) {
      return const SizedBox.shrink();
    }
    RoomEventItem? eventItem = latestMessage!.eventItem();
    if (eventItem == null) {
      return const SizedBox.shrink();
    }
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
      case 'm.room.sticker':
      case 'm.room.member':
        return _RoomMessageDescription(eventItem: eventItem);
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
          case 'm.sticker':
          case 'm.reaction':
          case 'm.text':
            return _RoomMessageDescription(eventItem: eventItem);
        }
      case 'm.room.redaction':
        return _RoomMessageDescription(
          eventItem: eventItem,
          optionalText: 'Message deleted',
        );
      case 'm.room.encrypted':
        return _RoomMessageDescription(
          eventItem: eventItem,
          optionalText: 'Failed to decrypt message. Re-request session keys',
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

class _RoomMessageDescription extends StatelessWidget {
  final RoomEventItem? eventItem;
  final String? optionalText;
  const _RoomMessageDescription({this.eventItem, this.optionalText});

  @override
  Widget build(BuildContext context) {
    TextDesc? textDesc = eventItem!.textDesc();
    if (textDesc == null) {
      return const SizedBox.shrink();
    }
    String sender = eventItem!.sender();
    String body = textDesc.body();
    String? formattedBody = textDesc.formattedBody();
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
        optionalText != null
            ? Flexible(
                child: Text(
                  optionalText ?? '',
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context).colorScheme.neutral5,
                        fontStyle: FontStyle.italic,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Flexible(
                child: Html(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  data: body,
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          jiffyTime(latestMessage!.eventItem()!.originServerTs()),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
