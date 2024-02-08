import 'package:freezed_annotation/freezed_annotation.dart';

part 'pin_edit_state.freezed.dart';

@freezed
class PinEditState with _$PinEditState {
  const factory PinEditState({
    required String title,
    required String link,
    @Default('') String plain,
    @Default(null) String? markdown,
    @Default(false) bool editMode,
  }) = _PinEditState;
}
