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
final _endDateProvider = StateProvider.autoDispose<DateTime?>(
  (ref) => null,
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
    final startDate = ref.watch(_startDateProvider);
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
                        child: Text('Start Time'),
                      ),
                      InkWell(
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onTap: _selectDateTime,
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
                        onTap: _selectDateTime,
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
      confirmActionOnPressed:
          (titleInput.isEmpty || startDate == null || endDate == null)
              ? null
              : () async {
                  await _handleCreateEvent();
                },
      cancelActionOnPressed: () =>
          context.canPop() ? context.pop() : context.goNamed(Routes.main.name),
    );
  }

  Future<void> _handleCreateEvent() async {
    EasyLoading.show(status: 'Creating Calendar Event', dismissOnTap: false);
    try {
      final spaceId = ref.read(selectedSpaceIdProvider);
      if (spaceId == null) {
        return;
      }

      final date = ref.read(_startDateProvider);
      final endDate = ref.read(_endDateProvider);

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
      final client = ref.read(clientProvider);
      final calendarEvent =
          await client!.waitForCalendarEvent(eventId.toString(), null);

      /// Event is created, set RSVP status to `Yes` by default for host.
      final rsvpManager = await calendarEvent.rsvpManager();
      final rsvpDraft = rsvpManager.rsvpDraft();
      rsvpDraft.status('Yes');
      await rsvpDraft.send();
      debugPrint('Updated Calendar Event: ${eventId.toString()}');
      EasyLoading.dismiss();
      if (context.mounted) {
        ref.invalidate(calendarEventProvider);
        context.pop();
      }
    } catch (e) {
      EasyLoading.dismiss();
      EasyLoading.showError('Error Creating Calendar Event: $e');
      return;
    }
  }

  void _selectDateTime() async {
    await showOmniDateTimeRangePicker(
      context: context,
      startFirstDate: DateTime.now(),
      startInitialDate: DateTime.now(),
      borderRadius: BorderRadius.circular(12),
    ).then((picked) {
      if (picked != null) {
        ref.read(_startDateProvider.notifier).update((state) => picked[0]);
        ref.read(_endDateProvider.notifier).update((state) => picked[1]);
        _dateController.text = DateFormat.yMd().format(picked[0]);
        _startTimeController.text = DateFormat.jm().format(picked[0]);
        _endTimeController.text = DateFormat.jm().format(picked[1]);
      }
    });
  }
}
