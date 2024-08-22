import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/comments/providers/comments.dart';
import 'package:acter/features/comments/widgets/comments_list.dart';
import 'package:acter/features/settings/providers/settings_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::comments::section');

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
    final managerLoader = ref.watch(commentsManagerProvider(manager));
    return managerLoader.when(
      data: (manager) => found(context, manager),
      error: (e, s) {
        _log.severe('Failed to load comment manager', e, s);
        return onError(context, e);
      },
      loading: () => loading(context),
    );
  }

  static Widget _inBox(BuildContext context, Widget child) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              const Icon(
                Atlas.comment_blank_thin,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                L10n.of(context).comments,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(width: 5),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget found(BuildContext context, CommentsManager manager) {
    return _inBox(context, CommentsList(manager: manager));
  }

  Widget onError(BuildContext context, Object error) {
    return _inBox(context, Text(L10n.of(context).loadingFailed(error)));
  }

  static Widget loading(BuildContext context) {
    return _inBox(context, Text(L10n.of(context).loading));
  }
}
