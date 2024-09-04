import 'package:acter/common/widgets/acter_icon_picker/model/acter_icon_picker_state.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final acterIconPickerStateProvider = StateNotifierProvider.autoDispose<
    ActerIconPickerStateNotifier, ActerIconPickerState>(
  (ref) => ActerIconPickerStateNotifier(ref: ref),
);

class ActerIconPickerStateNotifier extends StateNotifier<ActerIconPickerState> {
  final Ref ref;

  ActerIconPickerStateNotifier({required this.ref})
      : super(const ActerIconPickerState());

  void selectColor(Color color) {
    state = state.copyWith(selectedColor: color);
  }

  void selectIcon(ActerIcons acterIcons) {
    state = state.copyWith(selectedIcon: acterIcons);
  }
}
