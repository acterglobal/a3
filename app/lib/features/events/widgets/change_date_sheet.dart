import 'package:acter/common/toolkit/buttons/primary_action_button.dart';
import 'package:acter/common/utils/utils.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/events/utils/events_utils.dart';
import 'package:acter/features/notifications/actions/autosubscribe.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:dart_date/dart_date.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:acter/l10n/l10n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

final _log = Logger('a3::cal_event::change_date');

void showChangeDateBottomSheet({
  required BuildContext context,
  String? bottomSheetTitle,
  required String calendarId,
}) {
  showModalBottomSheet(
    showDragHandle: true,
    useSafeArea: true,
    context: context,
    builder:
        (context) => ChangeDateSheet(
          bottomSheetTitle: bottomSheetTitle,
          calendarId: calendarId,
        ),
  );
}

class ChangeDateSheet extends ConsumerStatefulWidget {
  final String? bottomSheetTitle;
  final String calendarId;

  const ChangeDateSheet({
    super.key,
    this.bottomSheetTitle,
    required this.calendarId,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _ChangeDateSheetState();
}

class _ChangeDateSheetState extends ConsumerState<ChangeDateSheet> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'event form key');
  final _startDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  DateTime _selectedStartDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  final _endDateController = TextEditingController();
  final _endTimeController = TextEditingController();
  DateTime _selectedEndDate = DateTime.now();
  TimeOfDay _selectedEndTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) async {
      _setEditEventData();
    });
  }

  // Apply existing data to fields
  Future<void> _setEditEventData() async {
    final calendarEvent = await ref.read(
      calendarEventProvider(widget.calendarId).future,
    );
    if (!mounted) return;

    // Getting start and end date time
    final dartStartTime = toDartDatetime(calendarEvent.utcStart());
    final dartEndTime = toDartDatetime(calendarEvent.utcEnd());

    // Setting data to variables for start date
    _selectedStartDate = dartStartTime.toLocal();
    _selectedStartTime = TimeOfDay.fromDateTime(_selectedStartDate);
    _startDateController.text = eventDateFormat(_selectedStartDate);
    _startTimeController.text = _selectedStartTime.format(context);

    // Setting data to variables for end date
    _selectedEndDate = dartEndTime.toLocal();
    _selectedEndTime = TimeOfDay.fromDateTime(_selectedEndDate);
    _endDateController.text = eventDateFormat(_selectedEndDate);
    _endTimeController.text = _selectedEndTime.format(context);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = L10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        children: [
          Text(
            widget.bottomSheetTitle ?? lang.changeDate,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 40),
          _eventDateAndTime(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(lang.cancel),
              ),
              const SizedBox(width: 20),
              ActerPrimaryActionButton(
                onPressed: _handleUpdateEvent,
                child: Text(lang.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Event date and time field
  Widget _eventDateAndTime() {
    final lang = L10n.of(context);
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.startDate),
                    const SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      keyboardType: TextInputType.text,
                      controller: _startDateController,
                      decoration: InputDecoration(
                        hintText: lang.selectDate,
                        suffixIcon: const Icon(Icons.calendar_month_outlined),
                      ),
                      onTap: () => _selectDate(isStartDate: true),
                      // required field, space not allowed
                      validator:
                          (val) =>
                              val == null || val.trim().isEmpty
                                  ? lang.startDateRequired
                                  : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.startTime),
                    const SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      keyboardType: TextInputType.text,
                      controller: _startTimeController,
                      decoration: InputDecoration(
                        hintText: lang.selectTime,
                        suffixIcon: const Icon(Icons.access_time_outlined),
                      ),
                      onTap: () => _selectTime(isStartTime: true),
                      // required field, space not allowed
                      validator:
                          (val) =>
                              val == null || val.trim().isEmpty
                                  ? lang.startTimeRequired
                                  : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.endDate),
                    const SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      keyboardType: TextInputType.text,
                      controller: _endDateController,
                      decoration: InputDecoration(
                        hintText: lang.selectDate,
                        suffixIcon: const Icon(Icons.calendar_month_outlined),
                      ),
                      onTap: () => _selectDate(isStartDate: false),
                      // required field, space not allowed
                      validator:
                          (val) =>
                              val == null || val.trim().isEmpty
                                  ? lang.endDateRequired
                                  : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lang.endTime),
                    const SizedBox(height: 10),
                    TextFormField(
                      readOnly: true,
                      keyboardType: TextInputType.text,
                      controller: _endTimeController,
                      decoration: InputDecoration(
                        hintText: lang.selectTime,
                        suffixIcon: const Icon(Icons.access_time_outlined),
                      ),
                      onTap: () => _selectTime(isStartTime: false),
                      // required field, space not allowed
                      validator:
                          (val) =>
                              val == null || val.trim().isEmpty
                                  ? lang.endTimeRequired
                                  : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Selecting date
  Future<void> _selectDate({required bool isStartDate}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().addYears(1),
    );
    if (date == null || !mounted) return;
    if (isStartDate) {
      _selectedStartDate = date;
      _startDateController.text = eventDateFormat(date);
      // if end date is empty and if start date is same or after end date
      if (_endDateController.text.isEmpty ||
          date.isSameOrAfter(_selectedEndDate)) {
        _selectedEndDate = date;
        _endDateController.text = eventDateFormat(date);
      }
    } else {
      // if date is same or after start date
      if (date.isSameOrAfter(_selectedStartDate)) {
        _selectedEndDate = date;
        _endDateController.text = eventDateFormat(date);
        // When user change date that time end time is reset
        _endTimeController.text = '';
      } else {
        EasyLoading.showToast(L10n.of(context).pleaseSelectValidEndDate);
      }
    }
    setState(() {});
  }

  // Selecting Time
  Future<void> _selectTime({required bool isStartTime}) async {
    final time = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _selectedStartTime : _selectedEndTime,
    );
    if (time == null || !mounted) return;
    if (isStartTime) {
      _selectedStartTime = time;
      _startTimeController.text = _selectedStartTime.format(context);
      // select end time after one of start time
      if (_endTimeController.text.isEmpty) {
        _selectedEndTime = time.replacing(hour: _selectedStartTime.hour + 1);
        _endTimeController.text = _selectedEndTime.format(context);
      }
    } else {
      // Checking if end time is before start time
      final double startTime = _selectedStartTime.toDouble();
      final double endTime = time.toDouble();
      if (_selectedStartDate.isSameDay(_selectedEndDate) &&
          startTime > endTime) {
        EasyLoading.showToast(L10n.of(context).pleaseSelectValidEndTime);
      } else {
        _selectedEndTime = time;
        _endTimeController.text = _selectedEndTime.format(context);
      }
    }
    setState(() {});
  }

  // Edit event handler
  Future<void> _handleUpdateEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final lang = L10n.of(context);
    EasyLoading.show(status: lang.updatingDate);
    try {
      // We always have calendar object at this stage.
      final calendarEvent = await ref.read(
        calendarEventProvider(widget.calendarId).future,
      );

      // Replacing hours and minutes from DateTime
      // Start Date
      final startDateTime = calculateDateTimeWithHours(
        _selectedStartDate,
        _selectedStartTime,
      );
      // End Date
      final endDateTime = calculateDateTimeWithHours(
        _selectedEndDate,
        _selectedEndTime,
      );

      // Convert UTC time zone
      final utcStartDateTime = startDateTime.toUtc().toIso8601String();
      final utcEndDateTime = endDateTime.toUtc().toIso8601String();

      // Updating calender event
      final updateBuilder = calendarEvent.updateBuilder();
      updateBuilder.utcStartFromRfc3339(utcStartDateTime);
      updateBuilder.utcEndFromRfc3339(utcEndDateTime);
      final eventId = await updateBuilder.send();
      _log.info('Calendar Event updated $eventId');

      await autosubscribe(ref: ref, objectId: eventId.toString(), lang: lang);

      EasyLoading.dismiss();

      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      _log.severe('Failed to update calendar event', e, s);
      if (!mounted) {
        EasyLoading.dismiss();
        return;
      }
      EasyLoading.showError(
        lang.errorUpdatingEvent(e),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
