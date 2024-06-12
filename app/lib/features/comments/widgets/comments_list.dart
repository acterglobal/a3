import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comment.dart';
import 'package:acter/features/comments/widgets/create_comment.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CommentsList extends ConsumerStatefulWidget {
  final CommentsManager manager;

  const CommentsList({
    super.key,
    required this.manager,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _CommentsListState();
}

class _CommentsListState extends ConsumerState<CommentsList> {
  bool editorOpened = false;

  @override
  Widget build(BuildContext context) {
    return ref.watch(commentsListProvider(widget.manager)).when(
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

  Widget createComment() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CreateCommentWidget(
        manager: widget.manager,
        onClose: () => setState(() => editorOpened = false),
      ),
    );
  }

  Widget commentListUI(BuildContext context, List<Comment> comments) {
    return Column(
      children: [
        Column(
          children: comments
              .map(
                (c) => CommentWidget(
                  comment: c,
                  manager: widget.manager,
                ),
              )
              .toList(),
        ),
        if (editorOpened)
          createComment()
        else
          Container(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                child: Text(L10n.of(context).createComment),
                onPressed: () => setState(() => editorOpened = true),
              ),
            ),
          ),
      ],
    );
  }

  Widget commentEmptyState(BuildContext context) {
    if (editorOpened) return createComment();
    return Row(
      children: [
        Text(L10n.of(context).commentEmptyStateTitle),
        if (!editorOpened)
          ActerInlineTextButton(
            onPressed: () => setState(() => editorOpened = true),
            child: Text(L10n.of(context).commentEmptyStateAction),
          ),
      ],
    );
  }

  Widget onError(BuildContext context, Object error) {
    return Column(
      children: [
        Text(L10n.of(context).commentsListError(error)),
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
