import 'package:acter/common/dialogs/pop_up_dialog.dart';
import 'package:acter/common/snackbars/custom_msg.dart';
import 'package:acter/common/themes/app_theme.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/features/home/widgets/space_chip.dart';
import 'package:acter/common/providers/space_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:acter/features/spaces/dialogs/space_selector_sheet.dart';
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
    Future(() {
      var parentNotifier = ref.read(parentSpaceProvider.notifier);
      parentNotifier.state = widget.initialSelectedSpace;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleInput = ref.watch(_titleProvider);
    final currentParentSpace = ref.watch(parentSpaceProvider);
    final selectParentSpace = currentParentSpace != null;
    return SideSheet(
      header: 'Create new event',
      addActions: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Create new event for your community'),
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
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
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
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
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
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
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
                  const SizedBox(height: 15),
                  ListTile(
                    title: Text(
                      selectParentSpace ? 'Space' : 'No space selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: selectParentSpace
                        ? Consumer(
                            builder: (context, ref, child) =>
                                ref.watch(parentSpaceDetailsProvider).when(
                                      data: (space) => space != null
                                          ? SpaceChip(space: space)
                                          : Text(currentParentSpace),
                                      error: (e, s) => Text('error: $e'),
                                      loading: () => const Text('loading'),
                                    ),
                          )
                        : null,
                    onTap: () async {
                      var currentSpaceId = ref.read(parentSpaceProvider);
                      var newSelectedSpaceId = await selectSpaceDrawer(
                        context: context,
                        currentSpaceId: currentSpaceId,
                        title: const Text('Select parent space'),
                      );
                      ref.read(parentSpaceProvider.notifier).state =
                          newSelectedSpaceId;
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.goNamed(Routes.main.name),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
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
            await _handleCreateEvent();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.success,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            foregroundColor: Theme.of(context).colorScheme.neutral6,
            textStyle: Theme.of(context).textTheme.bodySmall,
          ),
          child: const Text('Create Event'),
        ),
      ],
    );
  }

  void _handleTitleChange(String? value) {
    ref.read(_titleProvider.notifier).update((state) => value!);
  }

  Future<void> _handleCreateEvent() async {
    popUpDialog(
      context: context,
      title: const Text('Creating Event'),
      isLoader: true,
    );
    // pre fill values if user doesn't set date time.
    if (_dateController.text.isEmpty) {
      _dateController.text = DateFormat.yMd().format(ref.read(_dateProvider));
    }
    if (_startTimeController.text.isEmpty) {
      var time = ref.read(_startTimeProvider).format(context);
      _startTimeController.text = time;
    }
    if (_endTimeController.text.isEmpty) {
      var time = ref.read(_endTimeProvider).format(context);
      _endTimeController.text = time;
    }
    try {
      var space = await ref.read(
        spaceProvider(widget.initialSelectedSpace!).future,
      );
      var draft = space.calendarEventDraft();

      draft.title(ref.read(_titleProvider));
      draft.descriptionText(_descriptionController.text.trim());

      // convert selected date time to utc and RFC3339 format
      var date = ref.read(_dateProvider);
      var startTime = ref.read(_startTimeProvider);
      var utcStartDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        startTime.hour,
        startTime.minute,
      ).toUtc();
      draft.utcStartFromRfc3339(utcStartDateTime.toIso8601String());

      var endTime = ref.read(_endTimeProvider);
      var utcEndDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        endTime.hour,
        endTime.minute,
      ).toUtc();
      draft.utcEndFromRfc3339(utcEndDateTime.toIso8601String());

      var eventId = await draft.send();
      debugPrint('Created Calendar Event: ${eventId.toString()}');
      // We are doing as expected, but the lints triggers.
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }
      context.pop();
      context.pop();
      await context.pushNamed(
        Routes.calendarEvent.name,
        pathParameters: {'calendarId': eventId.toString()},
      );
    } catch (e) {
      context.pop();
      customMsgSnackbar(context, 'Some error occured $e');
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

    // We are doing as expected, but the lints triggers.
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
    if (picked != null) {
      ref.read(_startTimeProvider.notifier).update((state) => picked);
      var time = ref.read(_startTimeProvider).format(context);
      _startTimeController.text = time;
    }
  }

  Future<void> _selectEndTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: ref.read(_endTimeProvider),
    );

    // We are doing as expected, but the lints triggers.
    // ignore: use_build_context_synchronously
    if (!context.mounted) {
      return;
    }
    if (picked != null) {
      ref.read(_endTimeProvider.notifier).update((state) => picked);
      var time = ref.read(_endTimeProvider).format(context);
      _endTimeController.text = time;
    }
  }
}
