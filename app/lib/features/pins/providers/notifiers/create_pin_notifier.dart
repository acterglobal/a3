import 'package:acter/features/pins/models/create_pin_state/create_pin_state.dart';
import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatePinNotifier extends StateNotifier<CreatePinState> {
  final Ref ref;

  CreatePinNotifier({required this.ref}) : super(const CreatePinState());

  void setPinTitleValue(String title) {
    state = state.copyWith(pinTitle: title);
  }

  void setDescriptionValue({
    required String htmlBodyDescription,
    required String plainDescription,
  }) {
    state = state.copyWith(
      pinDescriptionParams: (
        htmlBodyDescription: htmlBodyDescription,
        plainDescription: plainDescription,
      ),
    );
  }

  void changeAttachmentTitle(PinAttachment pinAttachment, int index) {
    List<PinAttachment> pinAttachmentList = [...state.pinAttachmentList];
    pinAttachmentList[index] = pinAttachment;
    state = state.copyWith(pinAttachmentList: pinAttachmentList);
  }

  void addAttachment(PinAttachment pinAttachment) {
    List<PinAttachment> pinAttachmentList = [
      ...state.pinAttachmentList,
      pinAttachment,
    ];
    state = state.copyWith(pinAttachmentList: pinAttachmentList);
  }

  void removeAttachment(int index) {
    List<PinAttachment> pinAttachmentList = [...state.pinAttachmentList];
    pinAttachmentList.removeAt(index);
    state = state.copyWith(pinAttachmentList: pinAttachmentList);
  }
}
