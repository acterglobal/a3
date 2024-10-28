import 'package:acter/common/providers/common_providers.dart';
import 'package:acter/common/widgets/edit_html_description_sheet.dart';
import 'package:acter/features/comments/actions/sbumit_comment.dart';
import 'package:acter_avatar/acter_avatar.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AddCommentWidget extends ConsumerStatefulWidget {
  final CommentsManager manager;

  const AddCommentWidget({
    super.key,
    required this.manager,
  });

  @override
  ConsumerState<AddCommentWidget> createState() => _AddCommentWidgetState();
}

class _AddCommentWidgetState extends ConsumerState<AddCommentWidget> {
  final ValueNotifier<bool> showSendButton = ValueNotifier(false);
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final avatarInfo = ref.watch(accountAvatarInfoProvider);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ActerAvatar(options: AvatarOptions.DM(avatarInfo, size: 18)),
          const SizedBox(width: 12),
          Expanded(child: addCommentBoxUI(context)),
          sendButton(),
        ],
      ),
    );
  }

  Widget addCommentBoxUI(BuildContext context) {
    final lang = L10n.of(context);
    return TextField(
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      controller: _commentController,
      onChanged: (value) => showSendButton.value = value.isNotEmpty,
      decoration: InputDecoration(
        hintText: lang.addComment,
        suffixIcon: IconButton(
          onPressed: () => showEditHtmlDescriptionBottomSheet(
              context: context,
              bottomSheetTitle: L10n.of(context).addComment,
              descriptionHtmlValue: _commentController.text,
              onSave: (htmlBodyDescription, plainDescription) async {
                await addComment(
                  plainDescription: plainDescription,
                  htmlBodyDescription: htmlBodyDescription,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              }),
          icon: const Icon(Atlas.arrows_up_right_down_left, size: 14),
        ),
      ),
    );
  }

  Widget sendButton() {
    return ValueListenableBuilder(
      valueListenable: showSendButton,
      builder: (context, value, child) {
        return value
            ? Container(
                margin: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.all(Radius.circular(100)),
                ),
                child: IconButton(
                  onPressed: () =>
                      addComment(plainDescription: _commentController.text),
                  icon: Icon(PhosphorIcons.paperPlaneTilt()),
                ),
              )
            : const SizedBox.shrink();
      },
    );
  }

  Future<void> addComment({
    required String plainDescription,
    String? htmlBodyDescription,
  }) async {
    await submitComment(
      context,
      plainDescription,
      htmlBodyDescription ?? plainDescription,
      widget.manager,
    );
    _commentController.clear();
    showSendButton.value = false;
  }
}
