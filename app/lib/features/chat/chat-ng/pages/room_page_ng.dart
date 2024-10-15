import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/common/providers/room_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/common/widgets/frost_effect.dart';
import 'package:acter/features/chat/chat-ng/widgets/chat_input_ng.dart';
import 'package:acter/features/chat/chat-ng/widgets/chat_room_ng.dart';
import 'package:acter/features/chat/providers/chat_providers.dart';
import 'package:acter/features/chat/widgets/room_avatar.dart';

import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

final _log = Logger('a3::chat::room');

class ChatNGRoomPage extends ConsumerWidget {
  static const roomPageKey = Key('chat-ng-room-page');
  final String roomId;

  const ChatNGRoomPage({
    super.key = roomPageKey,
    required this.roomId,
  });

  Widget appBar(BuildContext context, WidgetRef ref) {
    final roomAvatarInfo = ref.watch(roomAvatarInfoProvider(roomId));
    final membersLoader = ref.watch(membersIdsProvider(roomId));
    final isEncrypted =
        ref.watch(isRoomEncryptedProvider(roomId)).valueOrNull ?? false;
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: !context.isLargeScreen,
      centerTitle: true,
      toolbarHeight: 70,
      flexibleSpace: FrostEffect(
        child: Container(),
      ),
      title: GestureDetector(
        onTap: () => context.pushNamed(
          Routes.chatNGProfile.name,
          pathParameters: {'roomId': roomId},
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              roomAvatarInfo.displayName ?? roomId,
              overflow: TextOverflow.clip,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 5),
            membersLoader.when(
              data: (members) => Text(
                L10n.of(context).membersCount(members.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              skipLoadingOnReload: false,
              error: (e, s) {
                _log.severe('Failed to load active members', e, s);
                return Text(L10n.of(context).errorLoadingMembersCount(e));
              },
              loading: () => Skeletonizer(
                child: Text(L10n.of(context).membersCount(100)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isEncrypted)
          IconButton(
            onPressed: () =>
                EasyLoading.showInfo(L10n.of(context).chatNotEncrypted),
            icon: Icon(
              PhosphorIcons.shieldWarning(),
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        GestureDetector(
          onTap: () => context.pushNamed(
            Routes.chatNGProfile.name,
            pathParameters: {'roomId': roomId},
          ),
          child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: RoomAvatar(
              roomId: roomId,
              showParents: true,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrientationBuilder(
      builder: (context, orientation) => Scaffold(
        resizeToAvoidBottomInset: orientation == Orientation.portrait,
        body: Column(
          children: [
            appBar(context, ref),
            ChatNGRoom(roomId: roomId),
            chatInput(context, ref),
          ],
        ),
      ),
    );
  }

  Widget chatInput(BuildContext context, WidgetRef ref) {
    final sendTypingNotice = ref.watch(
      userAppSettingsProvider.select(
        (settings) => settings.valueOrNull?.typingNotice() ?? false,
      ),
    );
    return ChatInputNG(
      key: Key('chat-ng-input-$roomId'),
      roomId: roomId,
      onTyping: (typing) async {
        if (sendTypingNotice) {
          final chat = await ref.read(chatProvider(roomId).future);
          if (chat != null) await chat.typingNotice(typing);
        }
      },
    );
  }
}
