import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/events/providers/events_provider.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

// interface data providers
final _titleProvider = StateProvider<String>((ref) => '');
final _dateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final _startTimeProvider = StateProvider<TimeOfDay>((ref) => TimeOfDay.now());
final _endTimeProvider = StateProvider(
  (ref) => TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  ),
);

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
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

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
    final titleNotifier = ref.read(_titleProvider.notifier);
    final dateNotifier = ref.read(_dateProvider.notifier);
    final startTimeNotifier = ref.read(_startTimeProvider.notifier);
    final endTimeNotifier = ref.read(_endTimeProvider.notifier);

    titleNotifier.update((state) => calendarEvent.title());
    // parse RFC3393 date time
    final dartDateTime = toDartDatetime(calendarEvent.utcStart());
    final dartEndTime = toDartDatetime(calendarEvent.utcEnd());
    dateNotifier.update(
      (state) => DateTime(
        dartDateTime.year,
        dartDateTime.month,
        dartDateTime.day,
      ),
    );
    startTimeNotifier.update((state) => TimeOfDay.fromDateTime(dartDateTime));
    endTimeNotifier.update((state) => TimeOfDay.fromDateTime(dartEndTime));

    _nameController.text = ref.read(_titleProvider);
    _dateController.text = DateFormat.yMd().format(ref.read(_dateProvider));

    // We are doing as expected, but the lints triggers.
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
    _startTimeController.text = ref.read(_startTimeProvider).format(context);
    _endTimeController.text = ref.read(_endTimeProvider).format(context);
    _descriptionController.text = calendarEvent.description()!.body();
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(_titleProvider);
    return SideSheet(
      header: 'Edit event',
      addActions: true,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('Here you can edit event information'),
            const SizedBox(height: 15),
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
                  onInputChanged: _handleTitleChange,
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
                        onTap: _selectDate,
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
                        child: Text('Start Time'),
                      ),
                      InkWell(
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onTap: _selectStartTime,
                        child: TextFormField(
                          enabled: false,
                          controller: _startTimeController,
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
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text('End Time'),
                      ),
                      InkWell(
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onTap: _selectEndTime,
                        child: TextFormField(
                          enabled: false,
                          controller: _endTimeController,
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
                )
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
                const Text('Link'),
                const SizedBox(height: 15),
                InputTextField(
                  controller: _linkController,
                  hintText: 'https://',
                  textInputType: TextInputType.url,
                  maxLines: 1,
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(Routes.main.name),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.neutral,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(
              color: Theme.of(context).colorScheme.success,
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () async {
            if (titleInput.isEmpty) {
              return;
            }
            _handleUpdateEvent(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: titleInput.isNotEmpty
                ? Theme.of(context).colorScheme.success
                : Theme.of(context).colorScheme.success.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }

  void _handleTitleChange(String? value) {
    ref.read(_titleProvider.notifier).update((state) => value!);
  }

  void _handleUpdateEvent(BuildContext context) async {
    popUpDialog(
      context: context,
      title: Text(
        'Updating Event',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      isLoader: true,
    );
    final calendarEvent =
        await ref.read(calendarEventProvider(widget.calendarId!).future);
    try {
      // initialize event update builder
      final eventUpdateBuilder = calendarEvent.updateBuilder();

      eventUpdateBuilder.title(ref.read(_titleProvider));

      final date = ref.read(_dateProvider);
      final startTime = ref.read(_startTimeProvider);
      final utcStartDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      ).toUtc();
      eventUpdateBuilder
          .utcStartFromRfc3339(utcStartDateTime.toIso8601String());

      final endTime = ref.read(_endTimeProvider);
      final utcEndDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      ).toUtc();
      eventUpdateBuilder.utcEndFromRfc3339(utcEndDateTime.toIso8601String());

      eventUpdateBuilder.descriptionText(_descriptionController.text.trim());

      final eventId = await eventUpdateBuilder.send();
      debugPrint('Updated Calendar Event: ${eventId.toString()}');

      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      context.pop();
      context.pop();
    } catch (e) {
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      context.pop();
      debugPrint('Some error occured ${e.toString()}');
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: ref.read(_dateProvider),
      initialDatePickerMode: DatePickerMode.day,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      ref.read(_dateProvider.notifier).update((state) => picked);
      _dateController.text = DateFormat.yMd().format(ref.read(_dateProvider));
    }
  }

  Future<void> _selectStartTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: ref.read(_startTimeProvider),
    );
    if (picked != null && context.mounted) {
      ref.read(_startTimeProvider.notifier).update((state) => picked);
      final time = ref.read(_startTimeProvider).format(context);
      _startTimeController.text = time;
    }
  }

  Future<void> _selectEndTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: ref.read(_endTimeProvider),
    );
    if (picked != null && context.mounted) {
      ref.read(_endTimeProvider.notifier).update((state) => picked);
      final time = ref.read(_endTimeProvider).format(context);
      _endTimeController.text = time;
    }
  }
}
