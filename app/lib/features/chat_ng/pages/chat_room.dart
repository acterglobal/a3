import 'package:acter/common/providers/chat_providers.dart';
import 'package:acter/router/routes.dart';
import 'package:acter/features/chat_ng/widgets/chat_editor/chat_editor_view.dart';
import 'package:acter/features/chat_ng/widgets/chat_messages.dart';
import 'package:acter/features/chat_ng/widgets/chat_room/app_bar_widget.dart';
import 'package:acter/features/settings/providers/app_settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ChatRoomNgPage extends ConsumerWidget {
  static const roomPageKey = Key('chat-room-ng-page');

  final String roomId;

  const ChatRoomNgPage({super.key = roomPageKey, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: ChatRoomAppBarWidget(
        roomId: roomId,
        onProfileTap:
            () => context.pushNamed(
              Routes.chatProfile.name,
              pathParameters: {'roomId': roomId},
            ),
      ),
      body: OrientationBuilder(
        builder:
            (context, orientation) => Scaffold(
              resizeToAvoidBottomInset: orientation == Orientation.portrait,
              body: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.07,
                            child: Container(
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage(
                                    'assets/images/chat_bg.png',
                                  ),
                                  repeat: ImageRepeat.repeat,
                                  fit: BoxFit.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned.fill(child: ChatMessages(roomId: roomId)),
                      ],
                    ),
                  ),
                  chatInput(context, ref),
                ],
              ),
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
    return ChatEditorView(
      key: Key('chat-editor-$roomId'),
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
