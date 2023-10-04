import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/events/presentation/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
final _dateProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
final _startTimeProvider =
    StateProvider.autoDispose<TimeOfDay>((ref) => TimeOfDay.now());
final _endTimeProvider = StateProvider.autoDispose<TimeOfDay>(
  (ref) => TimeOfDay(
    hour: TimeOfDay.now().hour + 1,
    minute: TimeOfDay.now().minute,
  ),
);

class CreateEventSheet extends ConsumerStatefulWidget {
  final String? initialSelectedSpace;
  const CreateEventSheet({super.key, this.initialSelectedSpace});

  @override
  ConsumerState<CreateEventSheet> createState() =>
      _CreateEventSheetConsumerState();
}

class _CreateEventSheetConsumerState extends ConsumerState<CreateEventSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((Duration duration) {
      final parentNotifier = ref.read(selectedSpaceIdProvider.notifier);
      parentNotifier.state = widget.initialSelectedSpace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(_titleProvider);
    ref.listen(createEventProvider, (previous, next) {
      next.whenData(
        (event) {
          if (event == null) return;
          context.pop();
          context.pop();
          context.pushNamed(
            Routes.calendarEvent.name,
            pathParameters: {'calendarId': event.eventId().toString()},
          );
        },
      );
    });

    return SideSheet(
      header: 'Create new event',
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
                  hintText: 'Name of the event',
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
                const Text('Link'),
                const SizedBox(height: 15),
                InputTextField(
                  controller: _linkController,
                  hintText: 'https://',
                  textInputType: TextInputType.url,
                  maxLines: 1,
                ),
                const SizedBox(height: 15),
                const SelectSpaceFormField(canCheck: 'CanPostEvent'),
              ],
            ),
          ],
        ),
      ),
      confirmActionTitle: 'Create Event',
      cancelActionTitle: 'Cancel',
      confirmActionOnPressed: titleInput.isEmpty
          ? null
          : () async {
              await _handleCreateEvent();
            },
      cancelActionOnPressed: () =>
          context.canPop() ? context.pop() : context.goNamed(Routes.main.name),
    );
  }

  Future<void> _handleCreateEvent() async {
    final spaceId = ref.read(selectedSpaceIdProvider)!;
    // pre fill values if user doesn't set date time.
    if (_dateController.text.isEmpty) {
      _dateController.text = DateFormat.yMd().format(DateTime.now().toUtc());
    }
    if (_startTimeController.text.isEmpty) {
      final time = TimeOfDay.now().format(context);
      _startTimeController.text = time;
    }
    if (_endTimeController.text.isEmpty) {
      final time = TimeOfDay(
        hour: TimeOfDay.now().hour + 1,
        minute: TimeOfDay.now().minute,
      ).format(context);
      _endTimeController.text = time;
    }
    final date = ref.read(_dateProvider);
    final startTime = ref.read(_startTimeProvider);
    final endTime = ref.read(_endTimeProvider);
    final utcStartDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    ).toUtc().toIso8601String();
    final utcEndDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    ).toUtc().toIso8601String();
    await ref.read(createEventProvider.notifier).create(
          spaceId,
          _nameController.text.trim(),
          _descriptionController.text.trim(),
          utcStartDateTime,
          utcEndDateTime,
        );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.day,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      ref.read(_dateProvider.notifier).update((state) => picked);
      _dateController.text = DateFormat.yMd().format(picked);
    }
  }

  Future<void> _selectStartTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && context.mounted) {
      final time = picked.format(context);
      ref.read(_startTimeProvider.notifier).update((state) => picked);
      _startTimeController.text = time;
    }
  }

  Future<void> _selectEndTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: TimeOfDay.now().hour + 1,
        minute: TimeOfDay.now().minute,
      ),
    );

    if (picked != null && context.mounted) {
      final time = picked.format(context);
      ref.read(_endTimeProvider.notifier).update((state) => picked);
      _endTimeController.text = time;
    }
  }
}
