import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comments_list.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class CommentsSection extends ConsumerWidget {
  final Future<CommentsManager> manager;

  const CommentsSection({
    super.key,
    required this.manager,
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
        Text(L10n.of(context).comments),
        CommentsList(manager: manager),
      ],
    );
  }

  Widget onError(BuildContext context, Object error) {
    return Column(
      children: [
        Text(L10n.of(context).comments),
        Text(L10n.of(context).loadingFailed(error)),
      ],
    );
  }

  Widget loading(BuildContext context) {
    return Column(
      children: [
        Text(L10n.of(context).comments),
        Text(L10n.of(context).loading),
      ],
    );
  }
}
