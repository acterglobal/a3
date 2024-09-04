import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'acter_icon_picker_state.freezed.dart';

@freezed
class ActerIconPickerState with _$ActerIconPickerState {
  const factory ActerIconPickerState({
    @Default(Colors.blueGrey) Color selectedColor,
    @Default(ActerIcons.list) ActerIcons selectedIcon,
    String? newsPostSpaceId,
  }) = _ActerIconPickerState;
}
