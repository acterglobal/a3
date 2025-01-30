import 'package:acter/features/news/actions/submit_news.dart';
import 'package:acter/features/news/model/keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddNewsPostToPage extends ConsumerWidget {
  final String? initialSelectedSpace;

  const AddNewsPostToPage({super.key, this.initialSelectedSpace});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(),
      body: const Placeholder(),
      floatingActionButton: FloatingActionButton(
        key: NewsUpdateKeys.newsSubmitBtn,
        onPressed: () => sendNews(context, ref),
        child: const Icon(Icons.send),
      ),
    );
  }
}
