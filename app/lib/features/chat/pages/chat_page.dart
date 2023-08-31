import 'package:acter/common/widgets/with_sidebar.dart';
import 'package:acter/features/chat/widgets/rooms_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatPage extends ConsumerWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WithSidebar(
      preferSidebar: true,
      sidebar: RoomsListWidget(),
      child: SizedBox(
        child: Center(
          child: Text('Select any room to see see it'),
        ),
      ),
    );
  }
}
