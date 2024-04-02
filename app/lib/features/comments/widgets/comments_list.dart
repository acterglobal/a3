import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comment.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CommentsList extends ConsumerWidget {
  final CommentsManager manager;
  final VoidCallback? onNewTap;
  final Widget emptyChild;
  const CommentsList({
    super.key,
    required this.manager,
    this.onNewTap,
    required this.emptyChild,
  });

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
      if (onNewTap != null) {
        return InkWell(
          onTap: onNewTap,
          child: Center(
            child: emptyChild,
          ),
        );
      } else {
        return Center(
          child: emptyChild,
        );
      }
    }
    return Column(
      children: comments.map((c) => CommentWidget(comment: c)).toList(),
    );
  }

  Widget onError(BuildContext context, Object error) {
    return Column(
      children: [
        Text('${L10n.of(context).commentsListError}: $error'),
      ],
    );
  }

  Widget loading(BuildContext context) {
    return Column(
      children: [
        Text(L10n.of(context).loadingCommentsList),
      ],
    );
  }
}
