import 'package:acter/features/pins/models/pin_edit_state/pin_edit_state.dart';
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
    String plainText = '';
    String? formattedBody;
    if (content != null) {
      if (content.formattedBody() != null) {
        formattedBody = content.formattedBody();
      } else {
        plainText = content.body();
      }
    }
    state = state.copyWith(
      title: pin.title(),
      link: pin.isLink() ? pin.url() ?? '' : '',
      plain: plainText,
      markdown: formattedBody,
    );
  }

  void setTitle(String title) => state = state.copyWith(title: title);

  void setLink(String link) => state = state.copyWith(link: link);

  void setPlainText(String text) => state = state.copyWith(plain: text);

  void setMarkdown(String? html) => state = state.copyWith(markdown: html);

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
      if (pin.isLink() && pin.url() != null) {
        if (pin.url() != state.link) {
          updateBuilder.url(state.link);
          hasChanges = true;
        }
      }
      final content = pin.content()!;
      if (content.body() != state.plain) {
        updateBuilder.contentText(state.plain);
        hasChanges = true;
      }

      if (content.formattedBody() != state.markdown && state.markdown != null) {
        updateBuilder.contentMarkdown(state.markdown!);
        hasChanges = true;
      }

      if (hasChanges) {
        await updateBuilder.send();
        await pin.refresh();
        EasyLoading.showSuccess('Pin Updated Successfully');
      }
    } catch (e) {
      EasyLoading.showError('Error saving changes: ${e.toString()}');
    }
  }
}
