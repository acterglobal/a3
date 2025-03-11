import 'package:acter/features/pins/models/create_pin_state/pin_attachment_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_pin_state.freezed.dart';

@freezed
class CreatePinState with _$CreatePinState {
  const factory CreatePinState({
    String? pinTitle,
    PinDescriptionParams? pinDescriptionParams,
    @Default([]) List<PinAttachment> pinAttachmentList,
  }) = _CreatePinState;
}

typedef PinDescriptionParams =
    ({String htmlBodyDescription, String plainDescription});
