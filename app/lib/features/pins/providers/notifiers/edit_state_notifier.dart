import 'package:acter/features/pins/models/pin_edit_state/pin_edit_state.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk_ffi.dart' show ActerPin;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:riverpod/riverpod.dart';

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

  // FIXME: move it to UI widget in order to implement l10n
  Future<void> onSave() async {
    EasyLoading.show(status: 'Saving Pin');
    try {
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

        if (state.html != null) {
          if (content.formattedBody() != state.html) {
            updateBuilder.contentHtml(state.markdown, state.html!);
            hasChanges = true;
          }
        }
      }

      if (hasChanges) {
        await updateBuilder.send();
      }
      await pin.refresh();
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showToast('Pin Updated Successfully');
    } catch (e) {
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        'Error saving changes: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
    }
  }
}
