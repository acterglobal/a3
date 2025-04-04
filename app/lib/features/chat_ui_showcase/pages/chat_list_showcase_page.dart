import 'package:acter/common/widgets/acter_search_widget.dart';
import 'package:acter/common/widgets/plus_icon_widget.dart';
import 'package:acter/features/chat_ui_showcase/models/mock_convo_list.dart';
import 'package:acter/features/chat_ui_showcase/widgets/chat_item/chat_list_item_container_widget.dart';
import 'package:acter/l10n/generated/l10n.dart';
import 'package:flutter/material.dart';

class ChatListShowcasePage extends StatelessWidget {
  const ChatListShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.chat),
        actions: [PlusIconWidget(onPressed: () {})],
      ),
      body: Column(
        children: [
          ActerSearchWidget(onChanged: (value) {}, onClear: () {}),
          Expanded(child: _buildChatListUI()),
        ],
      ),
    );
  }

  Widget _buildChatListUI() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16),
      separatorBuilder: (context, index) {
        return Divider(color: Theme.of(context).unselectedWidgetColor);
      },
      itemCount: mockConvoList.length,
      itemBuilder: (context, index) {
        final mockConvo = mockConvoList[index];
        return ChatListItemContainerWidget(
          isDM: mockConvo.isDM,
          displayName: mockConvo.displayName,
          lastMessage: mockConvo.lastMessage,
          lastMessageTimestamp: mockConvo.lastMessageTimestamp,
          lastMessageSenderDisplayName: mockConvo.lastMessageSenderDisplayName,
          isUnread: mockConvo.isUnread,
          unreadCount: mockConvo.unreadCount,
          isTyping: mockConvo.isTyping,
          typingUsers: mockConvo.typingUsers,
          isMuted: mockConvo.isMuted,
          isBookmarked: mockConvo.isBookmarked,
        );
      },
    );
  }
}
