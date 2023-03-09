import 'package:effektio/features/chat/pages/chat_page.dart';
import 'package:effektio/features/pin/pages/pin_page.dart';
import 'package:effektio/features/home/controllers/home_controller.dart';
import 'package:effektio/features/news/pages/news_page.dart';
import 'package:effektio/features/todo/pages/todo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeWidget extends ConsumerWidget {
  final PageController controller;
  const HomeWidget(this.controller, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(homeStateProvider.notifier).client;
    return PageView(
      controller: controller,
      children: <Widget>[
        const NewsPage(),
        PinPage(client: client),
        ToDoPage(client: client),
        ChatPage(client: client),
      ],
    );
  }
}
