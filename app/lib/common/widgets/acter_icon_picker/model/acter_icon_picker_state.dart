import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

part 'acter_icon_picker_state.freezed.dart';

@freezed
class ActerIconPickerState with _$ActerIconPickerState {
  const factory ActerIconPickerState({
    @Default(Colors.grey) Color selectedColor,
    @Default(PhosphorIconsRegular.list) IconData selectedIcon,
    String? newsPostSpaceId,
  }) = _ActerIconPickerState;
}
