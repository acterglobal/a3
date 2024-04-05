import 'package:acter/common/widgets/empty_state_widget.dart';
import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comment.dart';
import 'package:acter/features/comments/widgets/create_comment.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CommentsList extends ConsumerWidget {
  final CommentsManager manager;

  const CommentsList({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(commentsListProvider(manager)).when(
          data: (manager) {
            if (manager.isEmpty) {
              return commentEmptyState(context);
            } else {
              return commentListUI(context, manager);
            }
          },
          error: (e, st) => onError(context, e),
          loading: () => loading(context),
        );
  }

  Widget commentListUI(BuildContext context, List<Comment> comments) {
    return Column(
      children: [
        Column(
          children: comments.map((c) => CommentWidget(comment: c)).toList(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CreateCommentWidget(manager: manager),
        ),
      ],
    );
  }

  Widget commentEmptyState(BuildContext context) {
    return EmptyState(
      subtitle: L10n.of(context).commentEmptyStateSubtitle,
      image: 'assets/icon/comment.svg',
      imageSize: 50,
      primaryButton: CreateCommentWidget(manager: manager),
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
