import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/events/providers.dart';
import 'package:acter_flutter_sdk/acter_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
final _dateProvider =
    StateProvider.autoDispose<DateTime>((ref) => DateTime.now());
final _startTimeProvider =
    StateProvider.autoDispose<TimeOfDay>((ref) => TimeOfDay.now());
final _endTimeProvider = StateProvider.autoDispose(
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
    final calendarEvent = ref.read(
      calendarEventProvider(widget.calendarId!),
    );
    calendarEvent.whenData(
      (event) {
        _nameController.text = event.title();
        _descriptionController.text =
            event.description() == null ? '' : event.description()!.body();
        final dartDateTime = toDartDatetime(event.utcStart());
        final dartEndTime = toDartDatetime(event.utcEnd());
        _dateController.text = DateFormat.yMd().format(dartDateTime.toLocal());
        _startTimeController.text =
            DateFormat.jm().format(dartDateTime.toLocal());
        _endTimeController.text = DateFormat.jm().format(dartEndTime.toLocal());
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          ref
              .read(_titleProvider.notifier)
              .update((state) => _nameController.text);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(_titleProvider);
    ref.listen(editEventProvider, (prev, next) {
      next.whenData(
        (event) {
          if (event == null) return;
          context.pop();
        },
      );
    });
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
              ],
            ),
          ],
        ),
      ),
      confirmActionTitle: 'Save Changes',
      cancelActionTitle: 'Cancel',
      confirmActionOnPressed:
          titleInput.isEmpty ? null : () => _handleUpdateEvent(context),
      cancelActionOnPressed: () =>
          context.canPop() ? context.pop() : context.goNamed(Routes.main.name),
    );
  }

  void _handleUpdateEvent(BuildContext context) async {
    final asyncData = ref.read(calendarEventProvider(widget.calendarId!));
    final spaceId = asyncData.value!.roomIdStr();
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
    ref.read(editEventProvider.notifier).update(
          spaceId,
          widget.calendarId!,
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
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && context.mounted) {
      final time = picked.format(context);
      ref.read(_startTimeProvider.notifier).update((state) => picked);
      _endTimeController.text = time;
    }
  }
}
