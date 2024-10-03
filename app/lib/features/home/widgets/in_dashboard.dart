import 'package:acter/features/news/pages/news_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InDashboard extends ConsumerWidget {
  final Widget child;

  const InDashboard({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constrains) {
        if (constrains.maxWidth > 770) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(
                flex: 1,
                child: NewsListPage(newsViewMode: NewsViewMode.fullView),
              ),
              Flexible(
                flex: 2,
                child: child,
              ),
            ],
          );
        }
        return child;
      },
    );
  }
}
