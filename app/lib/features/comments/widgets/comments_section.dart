import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/comments/models.dart';
import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comments_list.dart';
import 'package:acter/features/comments/widgets/create_comment.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentsSection extends ConsumerWidget {
  final Future<CommentsManager> manager;
  final NewCommentLocation newCommentLocation;
  const CommentsSection({
    super.key,
    required this.manager,
    this.newCommentLocation = NewCommentLocation.before,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = ref.watch(featuresProvider);
    if (!provider.isActive(LabsFeature.comments)) {
      return const SizedBox.shrink();
    }
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
      children: [
        const Text('Comments'),
        // create comment on top
        if (newCommentLocation == NewCommentLocation.before)
          CreateCommentWidget(manager: manager),
        // the actual list
        CommentsList(
          manager: manager,
          emptyChild: const SizedBox.shrink(),
        ),
        // create comment after
        if (newCommentLocation == NewCommentLocation.after)
          CreateCommentWidget(manager: manager),
      ],
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
