import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/widgets/chat/edit_room_description_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter_matrix_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopicSystemMessageWidget extends ConsumerWidget {
  final SystemMessage message;
  final String roomId;

  const TopicSystemMessageWidget({
    super.key,
    required this.roomId,
    required this.message,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(roomMembershipProvider(roomId)).valueOrNull;
    return Center(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L10n.of(context).topic,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              SelectionArea(
                child: GestureDetector(
                  onTap: () {
                    if (membership?.canString('CanSetTopic') == true) {
                      showEditRoomDescriptionBottomSheet(
                        context: context,
                        description: message.text,
                        roomId: roomId,
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Html(data: message.text),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
