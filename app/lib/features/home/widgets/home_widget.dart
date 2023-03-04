import 'package:effektio/common/themes/seperated_themes.dart';
import 'package:effektio/features/chat/pages/chat_page.dart';
import 'package:effektio/features/faq/pages/faq_page.dart';
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
    final client = ref.watch(clientProvider);
    return client.when(
      data: (data) => PageView(
        controller: controller,
        children: <Widget>[
          const NewsPage(),
          FaqPage(client: data),
          ToDoPage(client: data),
          ChatPage(client: data),
        ],
      ),
      error: (error, stackTrace) => const Center(
        child: Text('Couldn\'t fetch client'),
      ),
      loading: () => const Center(
        child: SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(
            color: AppCommonTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
