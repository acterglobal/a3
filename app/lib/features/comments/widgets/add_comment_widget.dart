import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/features/comments/actions/sbumit_comment.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddCommentWidget extends ConsumerWidget {
  final CommentsManager manager;

  const AddCommentWidget({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarInfo = ref.watch(accountAvatarInfoProvider);
    return InkWell(
      onTap: () {
        showEditHtmlDescriptionBottomSheet(
          context: context,
          bottomSheetTitle: L10n.of(context).addComment,
          onSave: (htmlBodyDescription, plainDescription) async {
            await submitComment(
              context,
              plainDescription,
              htmlBodyDescription,
              manager,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: addCommentBoxUI(context)),
          ],
        ),
      ),
    );
  }

  Widget addCommentBoxUI(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).unselectedWidgetColor.withAlpha(30),
        border: Border.all(color: Theme.of(context).unselectedWidgetColor),
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Text(
        L10n.of(context).addComment,
        style: Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
