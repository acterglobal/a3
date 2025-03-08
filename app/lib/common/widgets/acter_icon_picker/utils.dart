import 'package:acter/common/widgets/acter_icon_picker/acter_icon_widget.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/acter_icons.dart';
import 'package:acter/common/widgets/acter_icon_picker/model/color_data.dart';
import 'package:acter/features/pins/providers/pins_provider.dart';
import 'package:acter/features/tasks/providers/tasklists_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActerIconWidgetFromObjectIdAndType extends ConsumerWidget {
  final String? objectId;
  final String? objectType;
  final double? iconSize;
  final Widget fallbackWidget;

  const ActerIconWidgetFromObjectIdAndType({
    super.key,
    this.objectId,
    this.objectType,
    this.iconSize = 16,
    required this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (objectId == null || objectType == null) return fallbackWidget;

    switch (objectType) {
      case 'pin':
        final pin = ref.watch(pinProvider(objectId!)).valueOrNull;
        return ActerIconWidget(
          iconSize: iconSize,
          color: convertColor(pin?.display()?.color(), iconPickerColors[0]),
          icon: ActerIcon.iconForPin(pin?.display()?.iconStr()),
        );
      case 'task-list':
        final taskList = ref.watch(taskListProvider(objectId!)).valueOrNull;
        return ActerIconWidget(
          iconSize: iconSize,
          color: convertColor(
            taskList?.display()?.color(),
            iconPickerColors[0],
          ),
          icon: ActerIcon.list,
        );
      default:
        return fallbackWidget;
    }
  }
}
