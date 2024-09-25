import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/add_button_with_can_permission.dart';
import 'package:acter/features/news/widgets/news_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topRight,
        children: [
          const NewsWidget(),
          addNewButton(context),
        ],
      ),
    );
  }

  Widget addNewButton(BuildContext context) {
    return Positioned(
      top: 50,
      right: 20,
      child: AddButtonWithCanPermission(
        canString: 'CanPostNews',
        onPressed: () => context.pushNamed(Routes.actionAddUpdate.name),
      ),
    );
  }
}
