import 'package:acter/features/home/providers/client_providers.dart';
import 'package:acter/features/pins/models/pin_edit_state/pin_edit_state.dart';
import 'package:acter/features/pins/pin_utils/pin_utils.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PinEditNotifier extends StateNotifier<PinEditState> {
  final ActerPin pin;
  final Ref ref;

  PinEditNotifier({required this.pin, required this.ref})
      : super(const PinEditState(title: '', link: '')) {
    _init();
  }

  void _init() {
    final content = pin.content();
    String markdown = '';
    String? formattedBody;
    if (content != null) {
      if (content.formattedBody() != null) {
        formattedBody = content.formattedBody();
      } else {
        markdown = content.body();
      }
    }
    state = state.copyWith(
      title: pin.title(),
      link: pin.isLink() ? pin.url() ?? '' : '',
      markdown: formattedBody ?? markdown,
      html: formattedBody,
    );
  }

  void setTitle(String title) => state = state.copyWith(title: title);

  void setLink(String link) => state = state.copyWith(link: link);

  void setMarkdown(String text) => state = state.copyWith(markdown: text);

  void setHtml(String? html) => state = state.copyWith(html: html);

  void setEditMode(bool editMode) => state = state.copyWith(editMode: editMode);

  Future<void> onSave() async {
    try {
      EasyLoading.show(status: 'Saving Pin');
      final updateBuilder = pin.updateBuilder();
      bool hasChanges = false;

      if (pin.title() != state.title) {
        updateBuilder.title(state.title);
        hasChanges = true;
      }
      if (pin.isLink()) {
        if (pin.url() != state.link) {
          updateBuilder.url(state.link);
          hasChanges = true;
        }
      }
      final content = pin.content();
      if (content != null) {
        if (content.body() != state.markdown) {
          updateBuilder.contentMarkdown(state.markdown);
          hasChanges = true;
        }

        if (state.html != null && content.formattedBody() != state.html) {
          updateBuilder.contentHtml(state.markdown, state.html!);
          hasChanges = true;
        }
      }

      final client = ref.read(alwaysClientProvider);
      final selectedAttachments = ref.read(selectedPinAttachmentsProvider);
      final manager = await pin.attachments();
      if (selectedAttachments.isNotEmpty) {
        EasyLoading.show(status: 'Sending attachments');
        final drafts = await PinUtils.makeAttachmentDrafts(
          client,
          manager,
          selectedAttachments,
        );
        if (drafts == null) {
          EasyLoading.showError('Error sending attachments');
          return;
        }
        for (final draft in drafts) {
          await draft.send();
        }
        hasChanges = true;
      }

      if (hasChanges) {
        await updateBuilder.send();
        await pin.refresh();
        // reset the selected attachment UI
        ref.invalidate(selectedPinAttachmentsProvider);
        EasyLoading.showSuccess('Pin Updated Successfully');
      }
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.showError('Error saving changes: ${e.toString()}');
    }
  }
}
