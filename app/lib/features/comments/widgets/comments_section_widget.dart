import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/add_comment_widget.dart';
import 'package:acter/features/comments/widgets/comment_list_skeleton_widget.dart';
import 'package:acter/features/comments/widgets/comment_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::comments::section');

class CommentsSectionWidget extends ConsumerWidget {
  final Future<CommentsManager> manager;
  final bool shrinkWrap;
  final bool centerTitle;
  final bool useCompactEmptyState;

  const CommentsSectionWidget({
    super.key,
    this.shrinkWrap = true,
    this.centerTitle = false,
    this.useCompactEmptyState = true,
    required this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final managerLoader = ref.watch(commentsManagerProvider(manager));
    return managerLoader.when(
      data: (commentManager) => buildCommentSectionUI(context, commentManager),
      error: (error, stack) =>
          commentManagerErrorWidget(context, ref, error, stack),
      loading: () => const CommentListSkeletonWidget(),
    );
  }

  Widget buildCommentSectionUI(
    BuildContext context,
    CommentsManager commentManager,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 12),
        commentTitleUI(context),
        commentListUI(commentManager),
        AddCommentWidget(manager: commentManager),
      ],
    );
  }

  Widget commentTitleUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        L10n.of(context).comments,
        style: Theme.of(context).textTheme.titleMedium,
        textAlign: centerTitle ? TextAlign.center : TextAlign.start,
      ),
    );
  }

  Widget commentListUI(CommentsManager commentManager) {
    if (shrinkWrap) {
      return CommentListWidget(
        manager: commentManager,
        useCompactEmptyState: useCompactEmptyState,
      );
    }
    return Expanded(
      child: CommentListWidget(
        manager: commentManager,
        shrinkWrap: shrinkWrap,
        useCompactEmptyState: useCompactEmptyState,
      ),
    );
  }

  Widget commentManagerErrorWidget(
    BuildContext context,
    WidgetRef ref,
    Object error,
    StackTrace stack,
  ) {
    _log.severe('Failed to load comment manager', error, stack);
    return ErrorPage(
      background: const CommentListSkeletonWidget(),
      error: error,
      stack: stack,
      textBuilder: L10n.of(context).loadingFailed,
      onRetryTap: () => ref.invalidate(commentsManagerProvider(manager)),
    );
  }
}
