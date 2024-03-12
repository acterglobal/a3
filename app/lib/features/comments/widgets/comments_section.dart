import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comments_list.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsSection extends ConsumerWidget {
  final Future<CommentsManager> manager;
  const CommentsSection({super.key, required this.manager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(commentsManagerProvider(manager)).when(
          data: (manager) => found(context, manager),
          error: (e, st) => onError(context, e),
          loading: () => loading(context),
        );
  }

  Widget found(BuildContext context, CommentsManager manager) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [const Text('Comments'), CommentsList(manager: manager)],
    );
  }

  Widget onError(BuildContext context, Object error) {
    return Column(
      children: [
        const Text('Comments'),
        Text('Loading failed $error'),
      ],
    );
  }

  Widget loading(BuildContext context) {
    return const Column(
      children: [
        Text('Comments'),
        Text('loading'),
      ],
    );
  }
}
