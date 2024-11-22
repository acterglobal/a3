import 'package:acter/common/toolkit/errors/error_page.dart';
import 'package:acter/common/extensions/options.dart';
import 'package:acter/features/comments/providers/comments_providers.dart';
import 'package:acter/features/comments/types.dart';
import 'package:acter/features/comments/widgets/add_comment_widget.dart';
import 'package:acter/features/comments/widgets/skeletons/comment_list_skeleton_widget.dart';
import 'package:acter/features/comments/widgets/comment_list_widget.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::comments::section');

class CommentsSectionWidget extends ConsumerWidget {
  final CommentsManagerProvider? managerProvider;
  final bool shrinkWrap;
  final bool centerTitle;
  final bool useCompactEmptyState;

  const CommentsSectionWidget({
    super.key,
    this.shrinkWrap = true,
    this.centerTitle = false,
    this.useCompactEmptyState = true,
    required this.managerProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = managerProvider;
    if (provider == null) {
      // we show the loading state
      return const CommentListSkeletonWidget();
    }
    final managerLoader = ref.watch(commentsManagerProvider(provider));
    final errored = managerLoader.asError;
    if (errored != null) {
      return commentManagerErrorWidget(
        context,
        ref,
        errored.error,
        errored.stackTrace,
      );
    }

    final manager = managerLoader.valueOrNull;
    if (manager == null) {
      return const CommentListSkeletonWidget();
    }
    return buildCommentSectionUI(context, manager);
  }

  static CommentListSkeletonWidget loading() =>
      const CommentListSkeletonWidget();

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
      textBuilder: (error, code) => L10n.of(context).loadingFailed(error),
      onRetryTap: () => managerProvider
          .map((manager) => ref.invalidate(commentsManagerProvider(manager))),
    );
  }
}
