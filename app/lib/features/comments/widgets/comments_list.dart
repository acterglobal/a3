import 'package:acter/common/toolkit/buttons/inline_text_button.dart';
import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comment.dart';
import 'package:acter/features/comments/widgets/create_comment.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::comments::list');

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
    final commentsLoader = ref.watch(commentsListProvider(widget.manager));
    return commentsLoader.when(
      data: (comments) {
        if (comments.isEmpty) {
          return commentEmptyState(context);
        } else {
          return commentListUI(context, comments);
        }
      },
      error: (e, s) {
        _log.severe('Failed to load comments', e, s);
        return onError(context, e);
      },
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
    final commentList = comments
        .map(
          (c) => CommentWidget(
            comment: c,
            manager: widget.manager,
          ),
        )
        .toList();
    return Column(
      children: [
        Column(children: commentList),
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
    final lang = L10n.of(context);
    return Row(
      children: [
        Text(lang.commentEmptyStateTitle),
        if (!editorOpened)
          ActerInlineTextButton(
            onPressed: () => setState(() => editorOpened = true),
            child: Text(lang.commentEmptyStateAction),
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
