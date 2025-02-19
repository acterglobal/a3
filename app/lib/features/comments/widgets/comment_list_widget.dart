import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/comments/providers/comments_providers.dart';
import 'package:acter/features/comments/widgets/comment_item_widget.dart';
import 'package:acter/features/comments/widgets/comment_list_empty_state_widget.dart';
import 'package:acter/features/comments/widgets/skeletons/comment_list_skeleton_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

final _log = Logger('a3::comments::list::widget');

class CommentListWidget extends ConsumerWidget {
  final CommentsManager manager;
  final bool shrinkWrap;
  final bool useCompactEmptyState;

  const CommentListWidget({
    super.key,
    required this.manager,
    this.shrinkWrap = true,
    this.useCompactEmptyState = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsLoader = ref.watch(commentsListProvider(manager));
    return commentsLoader.when(
      data: (commentList) => buildCommentListUI(context, commentList),
      error: (error, stack) =>
          commentListErrorWidget(context, ref, error, stack),
      loading: () => const CommentListSkeletonWidget(),
    );
  }

  Widget buildCommentListUI(BuildContext context, List<Comment> commentList) {
    if (commentList.isEmpty) {
      return CommentListEmptyStateWidget(useCompactView: useCompactEmptyState);
    }
    return ListView.builder(
      shrinkWrap: shrinkWrap,
      itemCount: commentList.length,
      padding: EdgeInsets.zero,
      reverse: true,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (context, index) {
        return CommentItemWidget(
          comment: commentList[index],
          manager: manager,
        );
      },
    );
  }

  Widget commentListErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace stack,
  ) {
    _log.severe('Failed to load comments', error, stack);
    return ErrorPage(
      background: const CommentListSkeletonWidget(),
      error: error,
      stack: stack,
      textBuilder: (error, code) => L10n.of(context).loadingFailed(error),
      onRetryTap: () => ref.invalidate(commentsListProvider(manager)),
    );
  }
}
