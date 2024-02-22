import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
final _startDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);
final _endDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);

class EditEventSheet extends ConsumerStatefulWidget {
  final String? calendarId;
  const EditEventSheet({super.key, this.calendarId});

  @override
  ConsumerState<EditEventSheet> createState() => _EditEventSheetConsumerState();
}

class _EditEventSheetConsumerState extends ConsumerState<EditEventSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editEventData();
  }

  // apply existing data to fields
  void _editEventData() async {
    final calendarEvent = await ref.read(
      calendarEventProvider(widget.calendarId!).future,
    );
    _nameController.text = calendarEvent.title();
    _descriptionController.text = calendarEvent.description() == null
        ? ''
        : calendarEvent.description()!.body();
    final dartDateTime = toDartDatetime(calendarEvent.utcStart());
    final dartEndTime = toDartDatetime(calendarEvent.utcEnd());
    _dateController.text =
        '${DateFormat.yMd().format(dartDateTime)} - ${DateFormat.yMd().format(dartEndTime)}';
    _timeController.text =
        '${DateFormat.jm().format(dartDateTime)} - ${DateFormat.jm().format(dartEndTime)}';
    ref.read(_titleProvider.notifier).update((state) => _nameController.text);
    ref
        .read(_startDateProvider.notifier)
        .update((state) => dartDateTime.toLocal());
    ref
        .read(_endDateProvider.notifier)
        .update((state) => dartEndTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(_titleProvider);
    final startDate = ref.watch(_startDateProvider);
    final endDate = ref.watch(_endDateProvider);
    return SideSheet(
      header: 'Edit event',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(bottom: 5),
                  child: Text('Name'),
                ),
                InputTextField(
                  hintText: 'Type Name',
                  textInputType: TextInputType.multiline,
                  controller: _nameController,
                  onInputChanged: (val) =>
                      ref.read(_titleProvider.notifier).update((state) => val!),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text('Date'),
                      ),
                      InkWell(
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onTap: _selectDateTime,
                        child: TextFormField(
                          enabled: false,
                          controller: _dateController,
                          keyboardType: TextInputType.datetime,
                          style: Theme.of(context).textTheme.labelLarge,
                          decoration: InputDecoration(
                            fillColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            filled: true,
                            hintText: 'Select Date',
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text('Time'),
                      ),
                      InkWell(
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onTap: _selectDateTime,
                        child: TextFormField(
                          enabled: false,
                          controller: _timeController,
                          keyboardType: TextInputType.datetime,
                          style: Theme.of(context).textTheme.labelLarge,
                          decoration: InputDecoration(
                            fillColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            filled: true,
                            hintText: 'Select Time',
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Description'),
                const SizedBox(height: 15),
                InputTextField(
                  controller: _descriptionController,
                  hintText: 'Type Description (Optional)',
                  textInputType: TextInputType.multiline,
                  maxLines: 10,
                ),
                const SizedBox(height: 15),
              ],
            ),
          ],
        ),
      ),
      confirmActionTitle: 'Save Changes',
      cancelActionTitle: 'Cancel',
      confirmActionOnPressed:
          (titleInput.trim().isEmpty || startDate == null || endDate == null)
              ? null
              : _handleUpdateEvent,
      cancelActionOnPressed: () =>
          context.canPop() ? context.pop() : context.goNamed(Routes.main.name),
    );
  }

  void _handleUpdateEvent() async {
    EasyLoading.show(status: 'Updating Event', dismissOnTap: false);
    try {
      final asyncEvent = ref.read(calendarEventProvider(widget.calendarId!));
      // We always have calendar object at this stage.
      final startDate = ref.read(_startDateProvider);
      final endDate = ref.read(_endDateProvider);
      final utcStartDateTime = startDate!.toUtc().toIso8601String();
      final utcEndDateTime = endDate!.toUtc().toIso8601String();
      final title = ref.read(_titleProvider);
      final description = _descriptionController.text;
      final updateBuilder = asyncEvent.value!.updateBuilder();
      updateBuilder.title(title);
      updateBuilder.utcStartFromRfc3339(utcStartDateTime);
      updateBuilder.utcEndFromRfc3339(utcEndDateTime);
      updateBuilder.descriptionText(description);
      final eventId = await updateBuilder.send();
      debugPrint('Calendar Event updated $eventId');

      EasyLoading.dismiss();
      if (context.mounted) {
        context.pop();
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error updating event: $e');
      return;
    }
  }

  void _selectDateTime() async {
    final picked = await showOmniDateTimeRangePicker(
      context: context,
      startFirstDate: ref.read(_startDateProvider),
      startInitialDate: ref.read(_startDateProvider),
      endInitialDate: ref.read(_endDateProvider),
      endFirstDate: ref.read(_endDateProvider),
      borderRadius: BorderRadius.circular(12),
      isForce2Digits: true,
    );
    if (picked != null) {
      final startDate = DateFormat.yMd().format(picked[0]);
      final endDate = DateFormat.yMd().format(picked[1]);
      _dateController.text = '$startDate - $endDate';

      final startTime = DateFormat.jm().format(picked[0]);
      final endTime = DateFormat.jm().format(picked[1]);
      _timeController.text = '$startTime - $endTime';

      ref.read(_startDateProvider.notifier).update((state) => picked[0]);
      ref.read(_endDateProvider.notifier).update((state) => picked[1]);
    }
  }
}
