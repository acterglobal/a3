import 'package:acter/features/home/widgets/user_avatar.dart';
import 'package:acter/features/news/widgets/news_widget.dart';
import 'package:acter/features/news/widgets/stream_types_selection.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NewsPage extends ConsumerWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: MediaQuery.of(context).size.width < 600
            ? const UserAvatarWidget()
            : const SizedBox.shrink(),
        centerTitle: true,
        title: const StreamTypesSelection(),
      ),
      body: const NewsWidget(),
    );
  }
}
