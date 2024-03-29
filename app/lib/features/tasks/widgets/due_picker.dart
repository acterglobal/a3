import 'package:flutter/material.dart';
import 'package:dart_date/dart_date.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class PickedDue {
  final DateTime due;
  final bool includeTime;

  const PickedDue(this.due, this.includeTime);
}

typedef OnSelect = Function(PickedDue);

class DuePicker extends StatefulWidget {
  static const quickSelectToday = Key('due-action-today');
  static const quickSelectTomorrow = Key('due-action-tomorrow');

  final Widget? title;
  final Widget? separator;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool? is24HourMode;
  final bool? isForce2Digits;
  final BorderRadiusGeometry? borderRadius;
  final BoxConstraints? constraints;
  final bool Function(DateTime)? selectableDayPredicate;
  final OnSelect onSelect;

  const DuePicker({
    super.key,
    this.title,
    this.separator,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.is24HourMode,
    this.isForce2Digits,
    this.borderRadius,
    this.constraints,
    this.selectableDayPredicate,
    required this.onSelect,
  });

  @override
  State<DuePicker> createState() => _DuePickerState();

  static Future<PickedDue?> showPicker({
    required BuildContext context,
    Widget? title,
    Widget? separator,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
    bool? is24HourMode,
    bool? isShowSeconds,
    int? minutesInterval,
    int? secondsInterval,
    bool? isForce2Digits,
    BorderRadiusGeometry? borderRadius,
    BoxConstraints? constraints,
    Widget Function(BuildContext, Animation<double>, Animation<double>, Widget)?
        transitionBuilder,
    Duration? transitionDuration,
    ThemeData? theme,
  }) {
    return showGeneralDialog(
      context: context,
      transitionBuilder: transitionBuilder ??
          (context, anim1, anim2, child) {
            return FadeTransition(
              opacity: anim1.drive(
                Tween(
                  begin: 0,
                  end: 1,
                ),
              ),
              child: child,
            );
          },
      transitionDuration:
          transitionDuration ?? const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: L10n.of(context).selectDue,
      pageBuilder: (BuildContext context, anim1, anim2) {
        return DuePicker(
          separator: separator,
          title: title,
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
          is24HourMode: is24HourMode,
          isForce2Digits: isForce2Digits,
          borderRadius: borderRadius,
          constraints: constraints,
          onSelect: (res) {
            Navigator.pop<PickedDue>(context, res);
          },
        );
      },
    );
  }
}

class _DuePickerState extends State<DuePicker> {
  bool selectTime = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Theme(
          data: Theme.of(context),
          child: OmniDateTimePicker(
            separator: widget.separator,
            title: widget.title,
            type: selectTime
                ? OmniDateTimePickerType.dateAndTime
                : OmniDateTimePickerType.date,
            initialDate: DateTime.now(),
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            is24HourMode: widget.is24HourMode,
            isShowSeconds: false,
            minutesInterval: 1,
            isForce2Digits: widget.isForce2Digits,
            borderRadius: widget.borderRadius,
            constraints: widget.constraints,
            selectableDayPredicate: widget.selectableDayPredicate,
            onSelect: (dt) {
              widget.onSelect(PickedDue(dt, selectTime));
            },
          ),
        ),
        selectTime
            ? const SizedBox()
            : Wrap(
                children: [
                  Text(L10n.of(context).quickSelect),
                  const SizedBox(
                    width: 10,
                  ),
                  ActionChip(
                    key: DuePicker.quickSelectToday,
                    label: Text(L10n.of(context).today),
                    onPressed: () {
                      widget.onSelect(
                        PickedDue(DateTime.now(), false),
                      );
                    },
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ActionChip(
                    key: DuePicker.quickSelectTomorrow,
                    label: Text(L10n.of(context).tomorrow),
                    onPressed: () {
                      widget.onSelect(
                        PickedDue(DateTime.now().nextDay, false),
                      );
                    },
                  ),
                ],
              ),
      ],
    );
  }
}
