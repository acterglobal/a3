import 'package:acter/common/toolkit/menu_item_widget.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:atlas_icons/atlas_icons.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PickedDue {
  final DateTime due;
  final bool includeTime;

  const PickedDue(this.due, this.includeTime);
}

const quickSelectToday = Key('due-action-today');
const quickSelectTomorrow = Key('due-action-tomorrow');

class _DueQuickPickerDrawer extends StatelessWidget {
  final DateTime? currentDue;

  const _DueQuickPickerDrawer({
    super.key,
    this.currentDue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          title(context),
          MenuItemWidget(
            key: quickSelectToday,
            title: L10n.of(context).today,
            visualDensity: VisualDensity.compact,
            iconData: Icons.today,
            withMenu: false,
            onTap: () => _submit(context, DateTime.now()),
          ),
          MenuItemWidget(
            key: quickSelectTomorrow,
            title: L10n.of(context).tomorrow,
            visualDensity: VisualDensity.compact,
            iconData: Icons.calendar_today,
            withMenu: false,
            onTap: () => _submit(context, DateTime.now()),
          ),
          ...renderPostponing(context),
          const SizedBox(height: 10),
          MenuItemWidget(
            title: L10n.of(context).selectCustomDate,
            iconData: Icons.calendar_month_outlined,
            withMenu: false,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: currentDue,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().addYears(1),
              );
              if (!context.mounted) {
                return;
              }
              _submit(context, date);
            },
          ),
        ],
      ),
    );
  }

  List<Widget> renderPostponing(BuildContext context) {
    return currentDue.let(
          (p0) => [
            const SizedBox(height: 10),
            MenuItemWidget(
              visualDensity: VisualDensity.compact,
              title: L10n.of(context).postpone,
              iconData: Icons.plus_one_rounded,
              withMenu: false,
              onTap: () => _submit(context, p0 + const Duration(days: 1)),
            ),
            MenuItemWidget(
              visualDensity: VisualDensity.compact,
              title: L10n.of(context).postponeN(2),
              iconData: Atlas.plus_thin,
              withMenu: false,
              onTap: () => _submit(context, p0 + const Duration(days: 2)),
            ),
          ],
        ) ??
        [];
  }

  void _submit(
    BuildContext context,
    DateTime? newValue, {
    bool includeTime = false,
  }) {
    Navigator.pop<PickedDue?>(
      context,
      newValue.let((p0) => PickedDue(p0, includeTime)),
    );
  }

  Widget title(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      title: const Text('Due date'),
      actions: [
        if (currentDue != null)
          TextButton.icon(
            icon: const Icon(Atlas.minus_circle_thin),
            onPressed: () => _submit(context, null),
            label: Text(L10n.of(context).unset),
          ),
      ],
    );
  }
}

Future<PickedDue?> showDuePicker({
  required BuildContext context,
  Key? key,
  DateTime? initialDate,
}) async {
  return await showModalBottomSheet(
    showDragHandle: true,
    enableDrag: true,
    useSafeArea: true,
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    builder: (context) => _DueQuickPickerDrawer(
      key: key,
      currentDue: initialDate,
    ),
  );
}
