import 'package:effektio/features/news/pages/news_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeWidget extends ConsumerWidget {
  final TabController controller;
  const HomeWidget(this.controller, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      key: const Key('bottom-bar'),
      child: TabBarView(
        controller: controller,
        children: const <Widget>[
          NewsPage(),
          // FaqPage(client: client),
          // ToDoPage(client: client),
          // ChatPage(client: client),
        ],
      ),
    );
  }
}
