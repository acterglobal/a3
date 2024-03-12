import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comment.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsList extends ConsumerWidget {
  final CommentsManager manager;
  const CommentsList({super.key, required this.manager});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(commentsListProvider(manager)).when(
          data: (manager) => found(context, manager),
          error: (e, st) => onError(context, e),
          loading: () => loading(context),
        );
  }

  Widget found(BuildContext context, List<Comment> comments) {
    if (comments.isEmpty) {
      return const Center(
        child: Text('No comments yet. Be the first to comment!'),
      );
    }
    return Column(
      children: comments.map((c) => CommentWidget(comment: c)).toList(),
    );
  }

  Widget onError(BuildContext context, Object error) {
    return Column(
      children: [
        Text('Comments list error: $error'),
      ],
    );
  }

  Widget loading(BuildContext context) {
    return const Column(
      children: [
        Text('loading comments list'),
      ],
    );
  }
}
