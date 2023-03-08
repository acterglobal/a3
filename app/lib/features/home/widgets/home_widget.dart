import 'package:effektio/features/chat/pages/chat_page.dart';
import 'package:effektio/features/faq/pages/faq_page.dart';
import 'package:effektio/features/home/repositories/client_repository.dart';
import 'package:effektio/features/news/pages/news_page.dart';
import 'package:effektio/features/todo/pages/todo_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeWidget extends ConsumerWidget {
  final PageController controller;
  const HomeWidget(this.controller, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientRepo = ref.watch(clientRepositoryProvider);
    return PageView(
      controller: controller,
      children: <Widget>[
        const NewsPage(),
        FaqPage(client: clientRepo.client),
        ToDoPage(client: clientRepo.client),
        ChatPage(client: clientRepo.client),
      ],
    );
  }
}
