import 'package:acter/common/providers/space_providers.dart';
import 'package:acter/common/utils/routes.dart';
import 'package:acter/common/widgets/input_text_field.dart';
import 'package:acter/common/widgets/side_sheet.dart';
import 'package:acter/common/widgets/spaces/select_space_form_field.dart';
import 'package:acter/features/events/providers/event_providers.dart';
import 'package:acter/features/home/providers/client_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';

final _titleProvider = StateProvider.autoDispose<String>((ref) => '');
final _startDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);
final _endDateProvider = StateProvider.autoDispose<DateTime?>((ref) => null);

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
  final TextEditingController _timeController = TextEditingController();

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
    final startDate = ref.watch(_startDateProvider);
    // keeping it here as provider doesn't seem to acknowledge state change
    // without it...
    // ignore: unused_local_variable
    final endDate = ref.watch(_endDateProvider);
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
                  textInputAction: TextInputAction.newline,
                  maxLines: 10,
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
      confirmActionOnPressed:
          (titleInput.isEmpty || startDate == null) ? null : _handleCreateEvent,
      cancelActionOnPressed: () =>
          context.canPop() ? context.pop() : context.goNamed(Routes.main.name),
    );
  }

  Future<void> _handleCreateEvent() async {
    EasyLoading.show(status: 'Creating Calendar Event', dismissOnTap: false);
    try {
      final spaceId = ref.read(selectedSpaceIdProvider);
      if (spaceId == null) {
        EasyLoading.showError(
          'Please select space',
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final date = ref.read(_startDateProvider);
      final endDate = ref.read(_endDateProvider);
      debugPrint('endDATE = $endDate');

      final utcStartDateTime = date!.toUtc().toIso8601String();
      final utcEndDateTime = endDate!.toUtc().toIso8601String();

      final space = await ref.read(spaceProvider(spaceId).future);
      final draft = space.calendarEventDraft();
      final title = ref.read(_titleProvider);
      final description = _descriptionController.text;
      draft.title(title);
      draft.utcStartFromRfc3339(utcStartDateTime);
      draft.utcEndFromRfc3339(utcEndDateTime);
      draft.descriptionText(description);
      final eventId = await draft.send();
      final client = ref.read(alwaysClientProvider);
      final calendarEvent =
          await client.waitForCalendarEvent(eventId.toString(), null);

      /// Event is created, set RSVP status to `Yes` by default for host.
      final rsvpManager = await calendarEvent.rsvpManager();
      final rsvpDraft = rsvpManager.rsvpDraft();
      rsvpDraft.status('yes');
      await rsvpDraft.send();
      debugPrint('Created Calendar Event: ${eventId.toString()}');
      EasyLoading.dismiss();
      if (context.mounted) {
        ref.invalidate(calendarEventProvider);
        context.pop();
        context.pushNamed(
          Routes.calendarEvent.name,
          pathParameters: {'calendarId': eventId.toString()},
        );
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error Creating Calendar Event: $e');
      return;
    }
  }

  Future<void> _selectDateTime() async {
    final selectedStartDate = ref.read(_startDateProvider);
    final selectedEndDate = ref.read(_endDateProvider);
    final picked = await showOmniDateTimeRangePicker(
      context: context,
      startFirstDate: DateTime.now(),
      startInitialDate: selectedStartDate ?? DateTime.now(),
      endInitialDate: selectedEndDate ?? DateTime.now(),
      endFirstDate: DateTime.now(),
      borderRadius: BorderRadius.circular(12),
      isForce2Digits: true,
    );
    if (picked == null) {
      return;
    }
    if (picked[0].isAfter(picked[1])) {
      EasyLoading.showError(
        'Invalid Date Time Range. Please select valid dates.',
        duration: const Duration(seconds: 2),
      );
      return;
    }

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
